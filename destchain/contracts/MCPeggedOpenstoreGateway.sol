// SPDX-License-Identifier: MIT

/**
ERC1155 gateway for MC-Pegged-Openstore
swapout = burn
swapin = mint
 */

pragma solidity ^0.8.0;

import "./ERC1155Gateway.sol";
import "./lib/Address.sol";
import "./lib/AssetContract.sol";

interface IMCOpenstore {
    function uri(uint256 _id) external view returns (string memory);

    function mint(
        address account,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function totalSupply(uint256 _id) external view returns (uint256);
}

interface IFactory {
    function getERC721Address(address creator) external pure returns (address);
}

interface MCIERC721 {
    function mint(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function exists(uint256 tokenId) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function creator() external view returns (address);
}

contract ERC1155Gateway_MintBurn is ERC1155Gateway {
    using Address for address;
    using TokenIdentifiers for *;

    address public factory;

    constructor(
        address anyCallProxy,
        address token,
        address factory_
    ) ERC1155Gateway(anyCallProxy, token) {
        factory = factory_;
    }

    function setFactory(address factory_) external onlyAdmin {
        factory = factory_;
    }

    function convert1155to721(uint256 tokenId)
        external
        returns (uint256 tokenId721)
    {
        address erc721 = IFactory(factory).getERC721Address(
            tokenId.tokenCreator()
        );
        require(erc721.isContract());
        require(tokenId.tokenMaxSupply() == 1);
        require(IMCOpenstore(token).balanceOf(msg.sender, tokenId) == 1);
        tokenId721 = tokenId.tokenIndex();
        IMCOpenstore(token).burn(msg.sender, tokenId, 1);
        MCIERC721(erc721).mint(msg.sender, tokenId721);
    }

    function convert721to1155(address erc721, uint256 tokenId)
        external
        returns (uint256 tokenId1155)
    {
        address creator = MCIERC721(erc721).creator();
        require(erc721 == IFactory(factory).getERC721Address(creator));
        require(MCIERC721(erc721).ownerOf(tokenId) == msg.sender);
        MCIERC721(erc721).burn(tokenId);
        tokenId1155 = uint256(uint160(creator)) << 56;
        tokenId1155 += tokenId;
        tokenId1155 = tokenId1155 << 40;
        tokenId1155 += 1;
        IMCOpenstore(token).mint(msg.sender, tokenId1155, 1, "");
    }

    function _swapout(
        address sender,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override returns (bool, bytes memory) {
        bytes memory extraMsg = bytes(IMCOpenstore(token).uri(tokenId));
        address erc721 = IFactory(factory).getERC721Address(
            tokenId.tokenCreator()
        );
        uint256 tokenIndex = tokenId.tokenIndex();
        if (
            tokenId.tokenMaxSupply() == 1 &&
            erc721.isContract() &&
            MCIERC721(erc721).exists(tokenIndex)
        ) {
            return (false, "");
        }
        try IMCOpenstore(token).burn(sender, tokenId, amount) {
            return (true, extraMsg);
        } catch {
            return (false, "");
        }
    }

    function _swapin(
        uint256 tokenId,
        uint256 amount,
        address receiver,
        bytes memory extraMsg
    ) internal override returns (bool) {
        address erc721 = IFactory(factory).getERC721Address(
            tokenId.tokenCreator()
        );
        uint256 tokenIndex = tokenId.tokenIndex();
        if (
            amount == 1 && tokenId.tokenMaxSupply() == 1 && erc721.isContract()
        ) {
            if (IMCOpenstore(token).totalSupply(tokenId) == 0) {
                return false;
            }
            try MCIERC721(erc721).mint(receiver, tokenIndex) {
                return true;
            } catch {
                return false;
            }
        }
        try IMCOpenstore(token).mint(receiver, tokenId, amount, extraMsg) {
            return true;
        } catch {
            return false;
        }
    }

    function _swapoutFallback(
        uint256 tokenId,
        uint256 amount,
        address sender,
        uint256 swapoutSeq,
        bytes memory extraMsg
    ) internal override returns (bool result) {
        try IMCOpenstore(token).mint(sender, tokenId, amount, extraMsg) {
            result = true;
        } catch {
            result = false;
        }
        if (sender.isContract()) {
            bytes memory _data = abi.encodeWithSelector(
                IGatewayClient.notifySwapoutFallback.selector,
                result,
                tokenId,
                amount,
                swapoutSeq
            );
            sender.call(_data);
        }
        return result;
    }
}
