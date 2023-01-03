// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PoppEmployerBadge.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// Desired Features
// - Propose a new employer wallet (includes transferring POPP ERC-20)
// - Vote on proposals
// - Conclude proposal (after 7 days)
// - Send rewards for winning votes (using POPP ERC-20)
contract PoppEmployerBadgeVoting is
PoppEmployerBadge
{
    using Counters for Counters.Counter;

    Counters.Counter private _proposalIdCounter;
    uint256 proposalTtl = 7 * 24 * 60 * 60; // 7 days
    uint256 private proposalCost = 100;
    uint256 private voteMinBalance = 100;

    struct Proposal {
        address wallet;
        string uri;
        uint256 timestamp;
    }

    mapping(uint256 => Proposal) public proposals;
    // note: only one proposal per wallet
    mapping(address => Proposal) public addressToProposal;
    // note: only one vote per proposal per wallet
    mapping(uint256 => mapping(bool => address[])) public votes;
    // this keeps track of the wallets that have voted with a timestamp
    mapping (address => mapping(uint256 => uint256)) public addressToVotes;

    IERC20 token;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    /**
     * @dev Propose a new employer wallet
     * @param _uri the URI for the employer's badge
     * @return uint256 the proposal ID
     */
    function propose(string calldata _uri) external returns (uint256) {
        require(addressToProposal[_msgSender()].timestamp == 0, "You already have a proposal");
        require(_walletToTokenId[_msgSender()] == 0, "You already have an employer badge");

        _proposalIdCounter.increment();
        uint256 _id = _proposalIdCounter.current();

        Proposal memory proposal = Proposal(
            _msgSender(),
            _uri,
            block.timestamp
        );

        proposals[_id] = proposal;
        addressToProposal[_msgSender()] = proposal;
        require(
            token.transferFrom(
                _msgSender(),
                address(this),
                proposalCost
            ),
            "Failed to transfer tokens"
        );
        return _id;
    }

    /**
     * @dev Vote on a proposal
     * @param _id the proposal id
     * @return Proposal the proposal
     */
    function getProposal(uint256 _id) external view returns (Proposal memory) {
        return proposals[_id];
    }

    /**
     * @dev Get proposal for the sender's wallet
     * @return Proposal the proposal
     */
    function getMyProposal() external view returns (Proposal memory) {
        return addressToProposal[_msgSender()];
    }

    /**
     * @dev Get the votes for a proposal
     * @return voteResults
     */
    function getVotes(uint256 _proposalId, bool _result) external view returns (address[] memory) {
        return votes[_proposalId][_result];
    }

    /**
     * @dev Vote on a proposal
     * @param _proposalId the proposal id
     * @param _voteResult the vote (true = yes, false = no)
     */
    function vote(uint256 _proposalId, bool _voteResult) external {
        Proposal storage proposal = proposals[_proposalId];

        require(proposal.timestamp != 0, "Proposal does not exist");
        require(proposal.wallet != _msgSender(), "You cannot vote on your own proposal");
        require(addressToVotes[_msgSender()][_proposalId] == 0, "You already voted");
        require(_walletToTokenId[_msgSender()] != 0, "You must have an employer badge to vote");

        uint256 _balance = token.balanceOf(_msgSender());
        require(_balance >= voteMinBalance, "You need to have some at least 100 POPP tokens to vote");

        _vote(_proposalId, _voteResult);
    }

    function _vote(uint256 _proposalId, bool _voteResult) internal {
        votes[_proposalId][_voteResult].push(_msgSender());
        addressToVotes[_msgSender()][_proposalId] = block.timestamp;
    }

    /**
     * @dev Conclude a proposal
     * @param _proposalId the proposal id
     */
    function conclude(uint256 _proposalId) external onlyOwner {
        require(proposals[_proposalId].timestamp != 0, "Proposal does not exist");
        require(proposals[_proposalId].timestamp + proposalTtl < block.timestamp, "Proposal has not yet concluded");
        bool voteResult = votes[_proposalId][true].length > votes[_proposalId][false].length;

        if (voteResult) {
            uint256 _tokenId = _mintToken(proposals[_proposalId].wallet);
            _setURI(_tokenId, proposals[_proposalId].uri);
        }

        uint256 voteCount = votes[_proposalId][voteResult].length;

        uint256 _reward = proposalCost / voteCount;

        for (uint256 i = 0; i < voteCount; i++) {
            token.transfer(votes[_proposalId][voteResult][i], _reward);
        }

        delete proposals[_proposalId];
        delete votes[_proposalId][true];
        delete votes[_proposalId][false];
    }

    /**
    * @dev Set the proposal ttl (admin only)
    * @param _ttl the ttl in seconds
    */
    function setProposalTtl(uint256 _ttl) external onlyOwner {
        proposalTtl = _ttl;
    }

    /**
    * @dev Set the proposal cost (admin only)
    * @param _cost the cost in POPP tokens
    */
    function setProposalCost(uint256 _cost) external onlyOwner {
        proposalCost = _cost;
    }

    /**
    * @dev Set the vote minimum balance (admin only)
    * @param _balance the minimum balance in POPP tokens
    */
    function setVoteMinBalance(uint256 _balance) external onlyOwner {
        voteMinBalance = _balance;
    }
}
