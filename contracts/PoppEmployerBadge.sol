// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import "popp-interfaces/IEmployerSft.sol";

/**
 * @title PoppEmployerBadge
 * @notice This contract represents an employer badge. It is a non-transferable token that can be a
 warded by admin to a verified employer.
 * @dev This contract is an ERC1155 token that is minted by an admin and assigned to a verified employer.
 * Desired Features
 * - Mint a new employer badge (admin only)
 * - Assign ownership to an employer (admin only)
 * - Add a wallet to a team (admin only)
 * - Burn Tokens (admin only?)
 * - ERC1155 full interface (base, metadata, enumerable)
*/
contract PoppEmployerBadge is
ERC1155Upgradeable,
ERC1155URIStorageUpgradeable,
OwnableUpgradeable,
UUPSUpgradeable,
IEmployerSft
{
    //////////////
    // Errors  //
    /////////////
    error MissingEmployerBadge();
    error WalletAlreadyOnTeam(address wallet);
    error NonTransferable();
    //////////////////////
    // State Variables //
    /////////////////////
    uint256 private _tokenIdCounter;
    // This can only be done because we only allow 1 token per wallet
    mapping(address => uint32) private _walletToTokenId;
    mapping(address => uint32) private _invalidFrom;

    /////////////
    // Events //
    ///////////
    event NewBadgeMinted(address indexed _to, string indexed _tokenURI);
    event UriSet(uint256 indexed _tokenId, string indexed _tokenURI);
    event BaseUriSet(string indexed _baseUri);
    event WalletAddedToTeam(address indexed _wallet, uint256 indexed _tokenId);
    event WalletRemovedFromTeam(address indexed _wallet, uint256 indexed _tokenId);
    event TokenBurned(uint256 indexed _tokenId);

    function initialize() initializer public {
        __ERC1155_init("ipfs://");
        __ERC1155URIStorage_init();
        _setBaseURI("ipfs://");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Mint a new Employer Verification Badge (admin only).
     * This is done when onboarding a new employer after KYC byt the team
     * After the first token has been minted, the employer can then add wallets to their team.
     * @notice this contract is an ERC-1155 thus semi fungible.
     * @param _to address of the first wallet to receive the token
     * @param _tokenURI string representing the tokenURI of the new token
     *
     * @return uint256 representing the newly minted token id
     */
    function mintNewBadge(address _to, string memory _tokenURI) external onlyOwner returns (uint256) {
        uint256 _tokenId = _mintToken(_to);
        _setURI(_tokenId, _tokenURI);
        emit NewBadgeMinted(_to, _tokenURI);

        return _tokenId;
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     * This is an admin function for setting up the tokenURI of an employer's badge
     *
     * @param tokenId uint256 id of the token to set its URI
     * @param tokenURI string URI to assign
     */
    function setURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
        _setURI(tokenId, tokenURI);
        emit UriSet(tokenId, tokenURI);
    }

    /**
    * @dev Sets `baseURI` as the `_baseURI` for all tokens
    * This is an admin function for setting up the baseURI of all tokens.
    * @notice This is most commonly set to ipfs://

    * @param baseURI string URI to assign
    *
    */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
        emit BaseUriSet(baseURI);
    }

    /**
     * @dev Mint a pre-verified employer token and transfer to a new wallet.
     * An admin function for setting up a team's wallets
     * we allow admins to add to any team
     * @param _to address of the wallet to receive the token
     * @param _tokenId uint256 representing the token id
     *
     * @return uint256 representing the newly minted token id
     */
    function addToTeam(address _to, uint256 _tokenId) external onlyOwner returns (uint256) {
        if (_walletToTokenId[_to] != 0) {
            revert WalletAlreadyOnTeam(_to);
        }

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
        if (_tokenId == 0) {
            revert MissingEmployerBadge();
        }

        if (_walletToTokenId[_to] != 0) {
            revert WalletAlreadyOnTeam(_to);
        }

        return _addToTeam(_to, _tokenId);
    }

    /**
    * @dev Mint a new token and add to a team
     * this is an internal function that is called by `mintNewBadge` and `addToTeam`
     * 1. Mint the token
     * 2. Set the token to the wallet
     * @param _to address of the wallet to receive the token
     * @param _tokenId uint256 representing the token id
     *
     * @return uint256 representing the newly minted token id
     */
    function _addToTeam(address _to, uint256 _tokenId) internal returns (uint256) {
        _mint(_to, _tokenId, 1, "");
        _walletToTokenId[_to] = uint32(_tokenId);
        emit WalletAddedToTeam(_to, _tokenId);

        return _tokenId;
    }

    /**
     * @dev Mint a new NFT. This is an internal function that is called by
     * `mintNewBadge` and `addToTeam`.
     * 1. Mint the token
     * 2. Set the token to the wallet
     * @param _to address of the wallet to receive the token
     *
     * @return uint256 representing the newly minted token id
     */
    function _mintToken(address _to) internal returns (uint256) {
        _tokenIdCounter++;
        return _addToTeam(_to, _tokenIdCounter);
    }

    /**
     * @dev remove a wallet from a team
     * This can only be done by a team member.
     *
     * @notice A wallet can remove itself from a team
     * @param _from address of the wallet to remove from the team
     * @param _timestamp uint32 representing the timestamp of when the token became invalid
     */
    function removeFromMyTeam(address _from, uint32 _timestamp) external {
        // TODO: Add timestamp validation
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
    ) external onlyOwner {
        _invalidFrom[_from] = _timestamp;

        super._burn(_from, _id, 1);
        emit WalletRemovedFromTeam(_from, _id);
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
    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) returns (string memory) {
        return super.uri(tokenId);
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
    ) internal virtual override(ERC1155Upgradeable) {
        if (from != address(0) && to != address(0)) {
            revert NonTransferable();
        }
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}
}
