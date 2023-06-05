// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

// Desired Features
// - Mint a new employer badge (admin only)
// - Assign ownership to an employer (admin only)
// - Add a wallet to a team (admin only)
// - Burn Tokens (admin only?)
// - ERC1155 full interface (base, metadata, enumerable)
contract PoppEmployerBadge is
ERC1155Upgradeable,
ERC1155URIStorageUpgradeable,
OwnableUpgradeable,
UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    // This can only be done because we only allow 1 token per wallet
    mapping(address => uint32) public _walletToTokenId;
    mapping(address => uint32) public _invalidFrom;

    function initialize() initializer public {
        __ERC1155_init("https://ipfs.io/ipfs/");
        __ERC1155URIStorage_init();
        _setBaseURI("https://ipfs.io/ipfs/");
        __Ownable_init();
        __UUPSUpgradeable_init();
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
    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)  returns (string memory) {
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
        require(from == address(0) || to == address(0), "Employer badges are non-transferable");
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override(ERC1155Upgradeable) returns (uint256) {
        return super.balanceOf(account, id);
    }

    /**
    * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC1155Upgradeable) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(ERC1155Upgradeable) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155Upgradeable) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override(ERC1155Upgradeable) returns (bool) {
        return super.isApprovedForAll(account, operator);
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override(ERC1155Upgradeable) returns (uint256[] memory) {
        return super.balanceOfBatch(accounts, ids);
    }
}
