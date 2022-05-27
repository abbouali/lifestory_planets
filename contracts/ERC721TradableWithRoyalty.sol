// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @author: Abderrahmane Bouali


import "./common/EIP2981/IERC721TradableWithRoyalty.sol";
import "./common/EIP2981/specs/IEIP2981.sol";

import "./ERC721Tradable.sol";

/**
 * Simple EIP2981 reference override implementation
 */
abstract contract ERC721TradableWithRoyalty is IEIP2981, IEIP2981RoyaltyOverride, ERC721Tradable {

    event TokenRoyaltySet(uint256 tokenId, address recipient, uint16 bps);
    event DefaultRoyaltySet(address recipient, uint16 bps);

    struct TokenRoyalty {
        address recipient;
        uint16 bps;
    }

    TokenRoyalty public defaultRoyalty;
    mapping(uint256 => TokenRoyalty) private _tokenRoyalties;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint16 _royaltyBPS,
        address _proxyRegistryOpenseaAddress
    )
        ERC721Tradable(
            _name,
            _symbol,
            _proxyRegistryOpenseaAddress
        )
    {
      defaultRoyalty = TokenRoyalty(_royaltyRecipient, _royaltyBPS);
    }

    function setTokenRoyalty(uint256 tokenId, address recipient, uint16 bps) public override onlyOwner {
        _tokenRoyalties[tokenId] = TokenRoyalty(recipient, bps);
        emit TokenRoyaltySet(tokenId, recipient, bps);
    }

    function setDefaultRoyalty(address recipient, uint16 bps) public override onlyOwner {
        defaultRoyalty = TokenRoyalty(recipient, bps);
        emit DefaultRoyaltySet(recipient, bps);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || interfaceId == type(IEIP2981RoyaltyOverride).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 value) public override view returns (address, uint256) {
        if (_tokenRoyalties[tokenId].recipient != address(0)) {
            return (_tokenRoyalties[tokenId].recipient, value*_tokenRoyalties[tokenId].bps/10000);
        }
        if (defaultRoyalty.recipient != address(0) && defaultRoyalty.bps != 0) {
            return (defaultRoyalty.recipient, value*defaultRoyalty.bps/10000);
        }
        return (address(0), 0);
    }
}