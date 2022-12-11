// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Desired Features
// - Mint new employer badge (admin only)
// - Assign ownership to employer (admin only)
// - Add wallet to team (admin only)
// - Burn Tokens (admin only?)
// - ERC1155 full interface (base, metadata, enumerable)
contract PoppEmployerBadge is
ERC1155,
ERC1155URIStorage,
Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    // This can only be done because we only allow 1 token per wallet
    mapping(address => uint256) private _walletToToken;

    constructor() ERC1155("https://test.com/{id}.json") {}

    /**
     * @dev Mint a new Employer Verification Badge
     * the uri here will contain the employer name, logo and other metadata
     *
     * @return uint256 representing the newly minted token id
     */
    function mintNewBadge(address _to) external onlyOwner returns (uint256) {
        return _mintToken(_to);
    }

    /**
     * @dev Mint a pre-verified employer token and transfer to a new wallet
     * this is an admin function for setting up a team's wallets
     *
     * @return uint256 representing the newly minted token id
     */
    function addToTeam(address _to, uint256 _tokenId) external onlyOwner returns (uint256) {
        return _addToTeam(_to, _tokenId);
    }

    /**
    * @dev Mint a pre-verified employer token and transfer to a new wallet
     * we allow badge owners to add to their team
     *
     * @return uint256 representing the newly minted token id
     */
    function addToMyTeam(address _to) external returns (uint256) {
        uint256 _tokenId = tokenFromWallet(_msgSender());
        require(_tokenId != 0, "You need to register your employer");
        require(tokenFromWallet(_to) == 0, "Wallet already apart of a team");

        return _addToTeam(_to, _tokenId);
    }

    function _addToTeam(address _to, uint256 _tokenId) internal returns (uint256) {
        _mint(_to, _tokenId, 1, "");
        _walletToToken[_to] = _tokenId;
        return _tokenId;
    }

    /**
     * @dev Mint a new NFT. This is an internal function that is called by
     * `mintNewBadge` and `addToTeam`.
     * 1. Mint the token
     * 2. Set the token URI
     * 3. Set the token to the wallet
     * @return uint256 representing the newly minted token id
     */
    function _mintToken(address _to) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 _tokenId = _tokenIdCounter.current();

        return _addToTeam(_to, _tokenId);
    }

    /**
     * @dev remove a wallet from a team
     * This can only be done by a team member.
     * note: A wallet can remove itself from a team
     */
    function removeFromMyTeam(address from) public {
        uint256 _tokenId = tokenFromWallet(_msgSender());
        super._burn(from, _tokenId, 1);
    }

    /**
     * @dev remove a wallet from a team
     * This can only be done by an admin user
     */
    function removeFromTeam(
        address from,
        uint256 id
    ) public onlyOwner {
        super._burn(from, id, 1);
    }

    /**
     * @dev return the employer token id for a given wallet.
     * Remember that a wallet can only own 1 employer token at a time
     */
    function tokenFromWallet(address _address) public view returns (uint256) {
        return _walletToToken[_address];
    }

    // The following functions are overrides required by Solidity.
    function uri(uint256 tokenId) public view virtual override(ERC1155, ERC1155URIStorage)  returns (string memory) {
        return super.uri(tokenId);
    }
}
