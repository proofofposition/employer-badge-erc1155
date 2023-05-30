// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "popp-interfaces/IEmployerSft.sol";
// Desired Features
// - Mint a new employer badge (admin only)
// - Assign ownership to an employer (admin only)
// - Add a wallet to a team (admin only)
// - Burn Tokens (admin only?)
// - ERC1155 full interface (base, metadata, enumerable)
contract PoppEmployerBadge is
ERC1155,
ERC1155URIStorage,
Ownable,
IEmployerSft
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    // This can only be done because we only allow 1 token per wallet
    mapping(address => uint32) public _walletToTokenId;
    mapping(address => uint32) public _invalidFrom;

    constructor() ERC1155("https://ipfs.io/ipfs/") {
        _setBaseURI("https://ipfs.io/ipfs/");
    }

    /**
     * @dev Mint a new Employer Verification Badge. This is done when onboarding a new employer.
     * After the first token has been minted, the employer can then add wallets to their team.
     *
     * @return uint256 representing the newly minted token id
     */
    function mintNewBadge(address _to, string memory _tokenURI) external onlyOwner returns (uint256) {
        uint256 _tokenId = _mintToken(_to);
        _setURI(_tokenId, _tokenURI);

        return _tokenId;
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function setURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    /**
    * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
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
        uint256 _tokenId = _walletToTokenId[_msgSender()];
        require(_tokenId != 0, "You need to register your employer");
        require(_walletToTokenId[_to] == 0, "Wallet already apart of a team");

        return _addToTeam(_to, _tokenId);
    }

    /**
    * @dev Mint a new token and add to a team
     * this is an internal function that is called by `mintNewBadge` and `addToTeam`
     * 1. Mint the token
     * 2. Set the token to the wallet
     * @return uint256 representing the newly minted token id
     */
    function _addToTeam(address _to, uint256 _tokenId) internal returns (uint256) {
        _mint(_to, _tokenId, 1, "");
        _walletToTokenId[_to] = uint32(_tokenId);

        return _tokenId;
    }

    /**
     * @dev Mint a new NFT. This is an internal function that is called by
     * `mintNewBadge` and `addToTeam`.
     * 1. Mint the token
     * 2. Set the token to the wallet
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
    function removeFromMyTeam(address _from, uint32 _timestamp) public {
        uint256 _tokenId = _walletToTokenId[_msgSender()];
        _invalidFrom[_from] = _timestamp;

        super._burn(_from, _tokenId, 1);
    }

    /**
     * @dev remove a wallet from a team
     * This can only be done by an admin user
     */
    function removeFromTeam(
        address _from,
        uint256 _id,
        uint32 _timestamp
    ) public onlyOwner {
        _invalidFrom[_from] = _timestamp;

        super._burn(_from, _id, 1);
    }

    /**
     * @dev return the employer token id for a given wallet.
     * Remember that a wallet can only own 1 employer token at a time
     */
    function employerIdFromWallet(address _address) external view returns (uint32) {
        return _walletToTokenId[_address];
    }

    /**
     * @dev return the timestamp (if any) of when an employer wallet becomes invalid.
     * This is to mark a wallet as invalid if the employer is no longer verified
     */
    function invalidFrom(address _address) external view returns (uint32) {
        return _invalidFrom[_address];
    }

    // The following functions are overrides required by Solidity.
    function uri(uint256 tokenId) public view virtual override(ERC1155, ERC1155URIStorage)  returns (string memory) {
        return super.uri(tokenId);
    }

    function selfDestruct() public onlyOwner {
        selfdestruct(payable(owner()));
    }

    /**
    * @dev This override is to make the token non-transferable
    */
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal virtual override(ERC1155) {
        require(from == address(0) || to == address(0), "Employer badges are non-transferable");
    }
}
