// SPDX-License-Identifier: MIT

/**
ERC1155 gateway for Openstore
swapout = lockin
swapin = lockout
 */

pragma solidity ^0.8.0;

import "./ERC1155Gateway.sol";
import "./lib/Address.sol";

interface IOpenstore {
    function uri(uint256 _id) external view returns (string memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract ERC1155Gateway_LILO is ERC1155Gateway {
    using Address for address;

    constructor(address anyCallProxy, address token)
        ERC1155Gateway(anyCallProxy, token)
    {}

    function _swapout(
        address sender,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override returns (bool, bytes memory) {
        try IOpenstore(token).safeTransferFrom(sender, address(this), tokenId, amount, "") {
            bytes memory extraMsg = bytes(IOpenstore(token).uri(tokenId));
            return (true, extraMsg);
        } catch {
            return (false, "");
        }
        return (false, "");
    }

    function _swapin(
        uint256 tokenId,
        uint256 amount,
        address receiver,
        bytes memory extraMsg
    ) internal override returns (bool) {
        if (!(keccak256(abi.encodePacked(bytes(IOpenstore(token).uri(tokenId)))) == keccak256(abi.encodePacked(extraMsg)))) {
            return false;
        }
        try IOpenstore(token).safeTransferFrom(address(this), receiver, tokenId, amount, "") {
            return true;
        } catch {
            return false;
        }
        return false;
    }

    function _swapoutFallback(
        uint256 tokenId,
        uint256 amount,
        address sender,
        uint256 swapoutSeq,
        bytes memory extraMsg
    ) internal override returns (bool result) {
        if (!(keccak256(abi.encodePacked(bytes(IOpenstore(token).uri(tokenId)))) == keccak256(abi.encodePacked(extraMsg)))) {
            return false;
        }
        try IOpenstore(token).safeTransferFrom(address(this), sender, tokenId, amount, "") {
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
    }
}
