// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LoyaltyApp is ERC721, Ownable {
    uint256 private tokenIdCounter;
    mapping(uint256 => bool) private isTokenBurnt;
    bool private isTokenTransferable;
    bool private proposalInProgress;
    uint256 private totalVotes;
    uint256 private totalYes;
    mapping(address => bool) private hasVoted;
    mapping(address => bool) private tokenHolders;
    address[] private voters;

    event TokenMinted(address indexed user, uint256 indexed tokenId);
    event TokenBurned(address indexed user, uint256 indexed tokenId);
    event ProposalCreated(uint256 indexed proposalId, string proposalDescription);
    event Voted(address indexed voter, bool voteChoice);
    event ProposalFinalized(bool passed);

    constructor() ERC721("Loyalty Token", "LOYALTY") {
        tokenIdCounter = 1;
        isTokenBurnt[0] = true;
        isTokenTransferable = false;
        proposalInProgress = false;
        totalVotes = 0;
        totalYes = 0;
    }

    function mintToken(address user) external onlyOwner returns (uint256) {
        require(user != address(0), "Invalid user address");

        uint256 newTokenId = tokenIdCounter;
        tokenIdCounter++;

        _safeMint(user, newTokenId);

        emit TokenMinted(user, newTokenId);

        return newTokenId;
    }

    function burnToken(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not the owner nor approved");
        require(!isTokenBurnt[tokenId], "Token is already burnt");

        isTokenBurnt[tokenId] = true;
        _burn(tokenId);

        emit TokenBurned(_msgSender(), tokenId);
    }

    function setTokenTransferability(bool transferable) external onlyOwner {
        isTokenTransferable = transferable;
    }

    function isTokenBurned(uint256 tokenId) external view returns (bool) {
        return isTokenBurnt[tokenId];
    }

    function getTransferability() external view returns (bool) {
        return isTokenTransferable;
    }

    function createProposal(string calldata proposalDescription) external {
        require(tokenHolders[_msgSender()], "Caller does not own tokens");
        require(!proposalInProgress, "Existing proposal in progress");

        proposalInProgress = true;
        totalVotes = 0;
        totalYes = 0;

        emit ProposalCreated(totalVotes, proposalDescription);
    }

    function vote(bool choice) external {
        require(tokenHolders[_msgSender()], "Caller does not own tokens");
        require(proposalInProgress, "No proposal in progress");
        require(!hasVoted[_msgSender()], "Caller has already voted");

        totalVotes++;
        if (choice) {
            totalYes++;
        }

        hasVoted[_msgSender()] = true;
        voters.push(_msgSender());

        emit Voted(_msgSender(), choice);
    }

    function finalizeProposal() external onlyOwner {
        require(proposalInProgress, "No proposal in progress");

        bool proposalPassed = (totalYes > totalVotes / 2);

        if (proposalPassed) {
            // Implement proposal action here
            isTokenTransferable = !isTokenTransferable;
        }

        // Reset proposal variables
        proposalInProgress = false;
        totalVotes = 0;
        totalYes = 0;
        for (uint256 i = 0; i < voters.length; i++) {
            hasVoted[voters[i]] = false;
        }
        delete voters;

        emit ProposalFinalized(proposalPassed);
    }
}