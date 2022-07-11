// SPDX-License-Identifier: MIT

/**
ERC1155 gateway for MC-Pegged-Openstore
swapout = burn
swapin = mint
 */

pragma solidity ^0.8.0;

import "./ERC1155Gateway.sol";
import "../lib/Address.sol";

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
}

contract ERC1155Gateway_MintBurn is ERC1155Gateway {
    using Address for address;

    constructor(address anyCallProxy, address token)
        ERC1155Gateway(anyCallProxy, token)
    {}

    function _swapout(
        address sender,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override returns (bool, bytes memory) {
        try IMCOpenstore(token).burn(sender, tokenId, amount) {
            bytes memory extraMsg = bytes(IMCOpenstore(token).uri(tokenId));
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
