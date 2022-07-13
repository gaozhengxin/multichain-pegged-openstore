// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Strings.sol";

contract ERC721Template is ERC721Enumerable {
    address public minter;
    address public creator;

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    constructor(address creator_, address minter_)
        ERC721Enumerable(toString(uint256(owner_)), toString(uint256(owner_)))
    {
        creator = creator_;
        minter = minter_;
    }

    function setNameSymbol(string memory name_, string memory symbol_)
        external
        onlyCreator
    {
        this.name = name_;
        this.symbol = symbol_;
    }

    function setMinter(address minter_) external onlyCreator {
        minter = minter_;
    }

    function mint(address to, uint256 tokenId) external onlyMinter {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyMinter {
        _burn(tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}

contract ERC721Factory {
    address public minter;

    constructor (address minter_) {
        minter = minter_;
    }

    function getERC721Address(address creator) external pure returns (address) {
        bytes32 addr;
        addr = keccak256(
            abi.encodePacked(
                hex"ff",
                address(this),
                keccak256(abi.encodePacked(creator, minter)),
                keccak256(abi.encodePacked(type(ERC721Template).creationCode))
            )
        );
        return address(uint160(uint256(addr)));
    }

    // Create and register ERC721 NFT collection
    // Collection key is creator
    // returns ERC721 contract address
    function createERC721(address creator) external returns (address) {
        address addr;
        bytes memory bytecode = type(ERC721Template).creationCode;
        uint256 _salt = abi.encodePacked(creator, minter);
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), _salt)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        require(getERC721Address(creator) == addr);
        return addr;
    }
}
