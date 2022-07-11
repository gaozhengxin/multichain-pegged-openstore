// SPDX-License-Identifier: MIT

/**
ERC1155 gateway for Openstore
swapout = lockin
swapin = lockout
 */

pragma solidity ^0.8.0;

import "./ERC1155Gateway.sol";
import "../lib/Address.sol";

contract ERC1155Gateway_LILO is ERC1155Gateway {
    using Address for address;

    constructor(
        address anyCallProxy,
        uint256 flag,
        address token
    ) ERC1155Gateway(anyCallProxy, flag, token) {}

    function _swapout(
        address sender,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override returns (bool, bytes memory) {
        /*try IMintBurn1155(token).burn(sender, tokenId, amount) {
            return (true, "");
        } catch {
            return (false, "");
        }*/
        // TODO
        return (false, "");
    }

    function _swapin(
        uint256 tokenId,
        uint256 amount,
        address receiver,
        bytes memory extraMsg
    ) internal override returns (bool) {
        /*try IMintBurn1155(token).mint(receiver, tokenId, amount) {
            return true;
        } catch {
            return false;
        }*/
        // TODO
        return false;
    }

    function _swapoutFallback(
        uint256 tokenId,
        uint256 amount,
        address sender,
        uint256 swapoutSeq,
        bytes memory extraMsg
    ) internal override returns (bool result) {
        /*try IMintBurn1155(token).mint(sender, tokenId, amount) {
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
        return result;*/
        // TODO
        return false;
    }
}
