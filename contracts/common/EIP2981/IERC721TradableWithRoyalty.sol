// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: lifetimeapp.io && manifold.xyz

/**
 * Simple EIP2981 reference override implementation
 */
interface IEIP2981RoyaltyOverride  {

    function setTokenRoyalty(uint256 tokenId, address recipient, uint16 bps) external;

    function setDefaultRoyalty(address recipient, uint16 bps) external;

}