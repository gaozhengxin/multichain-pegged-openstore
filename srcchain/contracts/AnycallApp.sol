// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAnycallV6Proxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function executor() external view returns (address);
}

interface IExecutor {
    function context()
        external
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );
}

contract Administrable {
    address public admin;
    address public pendingAdmin;
    event LogSetAdmin(address admin);
    event LogTransferAdmin(address oldadmin, address newadmin);
    event LogAcceptAdmin(address admin);

    function setAdmin(address admin_) internal {
        admin = admin_;
        emit LogSetAdmin(admin_);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = pendingAdmin;
        pendingAdmin = newAdmin;
        emit LogTransferAdmin(oldAdmin, newAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit LogAcceptAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}

abstract contract AnyCallApp is Administrable {
    uint256 public flag; // 0: pay on dest chain, 2: pay on source chain
    address public anyCallProxy;

    mapping(uint256 => address) public peer;

    modifier onlyExecutor() {
        require(msg.sender == IAnycallV6Proxy(anyCallProxy).executor());
        _;
    }

    constructor(address anyCallProxy_, uint256 flag_) {
        anyCallProxy = anyCallProxy_;
        flag = flag_;
    }

    function setPeers(uint256[] memory chainIDs, address[] memory peers)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < chainIDs.length; i++) {
            peer[chainIDs[i]] = peers[i];
        }
    }

    function setAnyCallProxy(address proxy) public onlyAdmin {
        anyCallProxy = proxy;
    }

    function _anyExecute(uint256 fromChainID, bytes calldata data)
        internal
        virtual
        returns (bool success, bytes memory result);

    function _anyFallback(bytes calldata data) internal virtual;

    function _anyCall(
        address _to,
        bytes memory _data,
        address _fallback,
        uint256 _toChainID
    ) internal {
        if (flag == 2) {
            IAnycallV6Proxy(anyCallProxy).anyCall{value: msg.value}(
                _to,
                _data,
                _fallback,
                _toChainID,
                flag
            );
        } else {
            IAnycallV6Proxy(anyCallProxy).anyCall(
                _to,
                _data,
                _fallback,
                _toChainID,
                flag
            );
        }
    }

    function anyExecute(bytes calldata data)
        external
        onlyExecutor
        returns (bool success, bytes memory result)
    {
        (address callFrom, uint256 fromChainID, ) = IExecutor(
            IAnycallV6Proxy(anyCallProxy).executor()
        ).context();
        require(peer[fromChainID] == callFrom, "call not allowed");
        _anyExecute(fromChainID, data);
    }

    function anyFallback(address to, bytes calldata data)
        external
        onlyExecutor
    {
        (address callFrom, , ) = IExecutor(
            IAnycallV6Proxy(anyCallProxy).executor()
        ).context();
        require(address(this) == callFrom, "call not allowed");
        _anyFallback(data);
    }
}
