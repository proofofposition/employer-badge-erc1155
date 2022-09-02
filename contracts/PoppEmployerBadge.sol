// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

// Desired Features
// - Mint new employer badge (admin only)
// - Assign ownership to employer (admin only)
// - Add wallet to team (admin only)
// - Burn Tokens (only admin?)
// - ERC721 full interface (base, metadata, enumerable)
contract PoppEmployerBadge is
ERC721,
ERC721Enumerable,
ERC721URIStorage,
Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Proof Of Position Employer Badge", "POPP_BADGE") {}

    /**
     * @dev Mint a new Employer Verification Badge
     * @return uint256 representing the newly minted token id
     */
    function mintNewBadge(
        address to,
        string memory uri
    ) external onlyOwner returns (uint256) {
        return _mintToken(to, uri);
    }

    /**
     * @dev Mint a pre-verified employer token and transfer to a new wallet
     * @return uint256 representing the newly minted token id
     */
    function addToTeam(
        address to,
        uint256 tokenId
    ) external returns (uint256) {
        string memory uri = tokenURI(tokenId);
        require(_msgSender() == ownerOf(tokenId) || owner() == _msgSender(), "Only the owner can do this");

        return _mintToken(to, uri);
    }

    /**
     * @dev Mint a new NFT
     * @return uint256 representing the newly minted token id
     */
    function _mintToken(
        address to,
        string memory uri
    ) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }


    // The following functions are overrides required by Solidity.

    /**
     * @dev Validate the mint
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) virtual {
        // token can only be minted or burnt
        if (to != address(0)) {
            require(from == address(0), "Employer badges are non-transferable");
            require(balanceOf(to) == 0, "You already have a POPP Employer Badge");
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
