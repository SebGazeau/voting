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
	struct EventVoting { 
		WorkflowStatus workflowStatus;
		mapping(address=> Voter) listVoter;
		mapping(uint => Proposal) proposals;
	}
	EventVoting[] public votings;

	// mapping(uint => Proposal) public proposals;
	event VoterRegistered(address voterAddress); 
	event VotersRegistered(address[] votersAddress); 
	event VoterExcluded(address voterAddress);
	event VotersExcluded(address[] votersAddress);

	event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
	event ProposalRegistered(uint proposalId);
	event Voted (address voter, uint proposalId);
	/**
	 * @dev Set contract deployer as owner
	 */
	constructor() {
		votings.push();
	}

	// modifier to check if caller is an authorized voter
	modifier anAuthorizedVoter() {
		uint idEvent = votings.length -1;
		require(votings[idEvent].listVoter[msg.sender].isRegistered, "Caller is not authorised");
		_;
	}
	// modifier to check if caller can add voters
	modifier inRegisteringStatus() {
		uint idEvent = votings.length -1;
		require(votings[idEvent].workflowStatus == WorkflowStatus.RegisteringVoters, "You can no longer add voters for this event");
		_;
	}

	/**
	 * @dev start voting
	 */
	function startVoting() public onlyOwner returns(bool isStarted){
		uint idEvent = votings.length -1;
		require(votings[idEvent].workflowStatus != WorkflowStatus.VotesTallied, "Caller is");
		votings.push();
		return true;
	}


	/**
	 * @dev 
	 * @param _proposalId id of the proposal voted
	 */
	function voted(uint _proposalId) public anAuthorizedVoter {
		uint idEvent = votings.length -1;
		require(votings[idEvent].workflowStatus == WorkflowStatus.VotingSessionStarted, "vote non ouvert");
		votings[idEvent].proposals[_proposalId].voteCount++;
		emit Voted(msg.sender, _proposalId);
	}




	/**
	 * @dev add a voter
	 * @param _address address to add
	 */
	function voterRegistered(address _address) public onlyOwner inRegisteringStatus{
		uint idEvent = votings.length -1;
		votings[idEvent].listVoter[_address].isRegistered = true;
		emit VoterRegistered(_address);
	}

	/**
	 * @dev add voters
	 * @param _address table of addresses to add
	 */
	function votersRegistered(address[] memory _address) public onlyOwner inRegisteringStatus{
		uint idEvent = votings.length -1;
		for (uint i = 0; i < _address.length; i++){
			votings[idEvent].listVoter[_address[i]].isRegistered = true;
		}
		emit VotersRegistered(_address);
	}
	/**
	 * @dev exclude a voter
	 * @param _address address to eclude
	 */
	function voterExcluded(address _address) public onlyOwner inRegisteringStatus{
		uint idEvent = votings.length -1;
		votings[idEvent].listVoter[_address].isRegistered = false;
		emit VoterExcluded(_address);
	}
	/**
	 * @dev exclude voters
	 * @param _address table of addresses to exclude
	 */
	function votersExcluded(address[] memory _address) public onlyOwner inRegisteringStatus{
		uint idEvent = votings.length -1;
		for (uint i = 0; i < _address.length; i++){
			votings[idEvent].listVoter[_address[i]].isRegistered = false;
		}
		emit VotersExcluded(_address);
	}
}