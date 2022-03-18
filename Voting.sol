// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting
 * @dev CRUD Whitelist
 * @dev CRUD Proposal for voting
 * @dev Voting system management
 */
contract Voting is Ownable{
	// Status for whitelist
	enum AddressStatus { Default, Blacklist, Whitelist }
	// Different states of a vote
	enum WorkflowStatus { 
		RegisteringVoters,
		ProposalsRegistrationStarted,
		ProposalsRegistrationEnded,
		VotingSessionStarted,
		VotingSessionEnded,
		VotesTallied
	}
	
	struct Voter {
		bool isRegistered;
		bool hasVoted;
		uint votedProposalId;
	}
	struct Proposal {
		string description;
		uint voteCount;
	}
	mapping(address=> AddressStatus) listStatus;

	event Authorized(address[] _address);
	event Banned(address[] _address);
	event Excluded(address[] _address);
	event VoterRegistered(address voterAddress); 
	event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
	event ProposalRegistered(uint proposalId);
	event Voted (address voter, uint proposalId);
	
	/**
	 * @dev change the status to allow voting
	 * @param _address address table to accept
	 */
	function authorizeVoter(address[] memory _address) public onlyOwner{
		for (uint i = 0; i < _address.length; i++){
			listStatus[_address[i]] = AddressStatus.Whitelist;
		}
		emit Authorized(_address);
	}
	/**
	 * @dev change the status to ban a voter
	 * @param _address address table to ban
	 */
	function bannedVoter(address[] memory _address) public onlyOwner{
		for (uint i = 0; i < _address.length; i++){
			listStatus[_address[i]] = AddressStatus.Blacklist;
		}
		emit Banned(_address);
	}
	/**
	 * @dev change the status to exclude a voter
	 * @param _address address table to eclude
	 */
	function excludeVoter(address[] memory _address) public onlyOwner{
		for (uint i = 0; i < _address.length; i++){
			listStatus[_address[i]] = AddressStatus.Default;
		}
		emit Excluded(_address);
	}
}