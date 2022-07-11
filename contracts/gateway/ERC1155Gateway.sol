// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./anycall_app.sol";

interface IGatewayClient {
    function notifySwapoutFallback(
        bool refundSuccess,
        uint256 tokenId,
        uint256 amount,
        uint256 swapoutSeq
    ) external returns (bool);
}

// interface of ERC20Gateway
interface IERC1155Gateway {
    function name() external view returns (string memory);

    function token() external view returns (address);

    function getPeer(uint256 foreignChainID) external view returns (address);

    function Swapout(
        uint256 tokenId,
        uint256 amount,
        address receiver,
        uint256 toChainID
    ) external payable returns (uint256 swapoutSeq);

    function Swapout_no_fallback(
        uint256 tokenId,
        uint256 amount,
        address receiver,
        uint256 toChainID
    ) external payable returns (uint256 swapoutSeq);
}

abstract contract ERC1155Gateway is IERC1155Gateway, AnyCallApp {
    address public override token;
    mapping(uint256 => uint8) public decimals;
    uint256 public swapoutSeq;
    string public override name;

    constructor(
        address anyCallProxy,
        uint256 flag,
        address token_
    ) AnyCallApp(anyCallProxy, flag) {
        setAdmin(msg.sender);
        token = token_;
    }

    function getPeer(uint256 foreignChainID)
        external
        view
        override
        returns (address)
    {
        return peer[foreignChainID];
    }

    function _swapout(
        address sender,
        uint256 tokenId,
        uint256 amount
    ) internal virtual returns (bool, bytes memory);

    function _swapin(
        uint256 tokenId,
        uint256 amount,
        address receiver,
        bytes memory extraMsg
    ) internal virtual returns (bool);

    function _swapoutFallback(
        uint256 tokenId,
        uint256 amount,
        address sender,
        uint256 swapoutSeq,
        bytes memory extraMsg
    ) internal virtual returns (bool);

    event LogAnySwapOut(
        uint256 tokenId,
        address sender,
        address receiver,
        uint256 toChainID,
        uint256 swapoutSeq
    );

    function setForeignGateway(
        uint256[] memory chainIDs,
        address[] memory peers
    ) external onlyAdmin {
        for (uint256 i = 0; i < chainIDs.length; i++) {
            peer[chainIDs[i]] = peers[i];
        }
    }

    function Swapout(
        uint256 tokenId,
        uint256 amount,
        address receiver,
        uint256 destChainID
    ) external payable override returns (uint256) {
        (bool ok, bytes memory extraMsg) = _swapout(
            msg.sender,
            tokenId,
            amount
        );
        require(ok);
        swapoutSeq++;
        bytes memory data = abi.encode(
            tokenId,
            amount,
            msg.sender,
            receiver,
            swapoutSeq,
            extraMsg
        );
        _anyCall(peer[destChainID], data, address(this), destChainID);
        emit LogAnySwapOut(
            tokenId,
            msg.sender,
            receiver,
            destChainID,
            swapoutSeq
        );
        return swapoutSeq;
    }

    function Swapout_no_fallback(
        uint256 tokenId,
        uint256 amount,
        address receiver,
        uint256 destChainID
    ) external payable override returns (uint256) {
        (bool ok, bytes memory extraMsg) = _swapout(
            msg.sender,
            tokenId,
            amount
        );
        require(ok);
        swapoutSeq++;
        bytes memory data = abi.encode(
            tokenId,
            amount,
            msg.sender,
            receiver,
            swapoutSeq,
            extraMsg
        );
        _anyCall(peer[destChainID], data, address(0), destChainID);
        emit LogAnySwapOut(
            tokenId,
            msg.sender,
            receiver,
            destChainID,
            swapoutSeq
        );
        return swapoutSeq;
    }

    function _anyExecute(uint256 fromChainID, bytes calldata data)
        internal
        override
        returns (bool success, bytes memory result)
    {
        (
            uint256 tokenId,
            uint256 amount,
            ,
            address receiver,
            ,
            bytes memory extraMsg
        ) = abi.decode(
                data,
                (uint256, uint256, address, address, uint256, bytes)
            );
        require(_swapin(tokenId, amount, receiver, extraMsg));
    }

    function _anyFallback(bytes calldata data) internal override {
        (
            uint256 tokenId,
            uint256 amount,
            address sender,
            ,
            uint256 swapoutSeq,
            bytes memory extraMsg
        ) = abi.decode(
                data,
                (uint256, uint256, address, address, uint256, bytes)
            );
        require(
            _swapoutFallback(tokenId, amount, sender, swapoutSeq, extraMsg)
        );
    }
}