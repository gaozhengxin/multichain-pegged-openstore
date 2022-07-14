// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721Template is ERC721Enumerable {
    using Strings for uint256;

    address public minter;
    address public creator;

    string private custom_name;
    string private custom_symbol;

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    constructor(address creator_, address minter_) ERC721(uint256(uint160(creator_)).toHexString(),uint256(uint160(creator_)).toHexString())
    {
        creator = creator_;
        minter = minter_;
    }

    function setNameSymbol(string memory name_, string memory symbol_)
        external
        onlyCreator
    {
        custom_name = name_;
        custom_symbol = symbol_;
    }

    function name() public view override returns (string memory) {
        return (bytes(custom_name).length == 0) ? super.name() : custom_name;
    }

    function symbol() public view override returns (string memory) {
        return (bytes(custom_symbol).length == 0) ? super.symbol() : custom_symbol;
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

    string public templateURI =
        "https://api.opensea.io/api/v2/metadata/matic/0x2953399124F0cBB46d2CbACD8A89cF0599974963/0x{id}";

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 tokenId1155 = uint256(uint160(creator)) << 56;
        tokenId1155 += tokenId;
        tokenId1155 = tokenId1155 << 40;
        tokenId1155 += 1;
        uint256 len = bytes(templateURI).length - 6;
        bytes memory baseURI = new bytes(len + 42);
        for (uint256 i = 0; i < len; i++) {
            baseURI[i] = bytes(templateURI)[i];
        }
        return string(abi.encodePacked(baseURI, tokenId1155.toHexString()));
    }
}

contract ERC721Factory {
    address public minter;

    constructor(address minter_) {
        minter = minter_;
    }

    function getERC721Address(address creator) public view returns (address) {
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
        bytes memory _salt = abi.encodePacked(creator, minter);
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
