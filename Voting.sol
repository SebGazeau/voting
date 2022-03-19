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
		uint nbrVoters;
		address[] votersWhoVoted;
		uint nbrOfProposals;
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
		require(votings[idEvent].workflowStatus == WorkflowStatus.RegisteringVoters, "The registration phase is over");
		_;
	}

	/**
	 * @dev start voting
	 * @return isStarted boolean to indicate the good start
	 */
	function startVoting() public onlyOwner returns(bool isStarted){
		uint idEvent = votings.length -1;
		require(votings[idEvent].workflowStatus == WorkflowStatus.VotesTallied, "The previous vote is not over");
		votings.push();
		return true;
	}
	/**
	 * @dev set new proposal
	 * @return infoSave registration status
	 */
	function setProposal(string memory _description) public anAuthorizedVoter returns(string memory infoSave){
		uint idEvent = votings.length -1;
		uint idProposal = votings[idEvent].nbrOfProposals;
		require(votings[idEvent].workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "The previous vote is not over");
		votings[idEvent].proposals[idProposal].description = _description;
		votings[idEvent].nbrOfProposals++;
		emit ProposalRegistered(idProposal);
		return "your proposal has been registered";
	}
	/**
	 * @dev set vote 
	 * @param _proposalId id of the proposal voted
	 */
	function voted(uint _proposalId) public anAuthorizedVoter {
		uint idEvent = votings.length -1;
		require(votings[idEvent].workflowStatus == WorkflowStatus.VotingSessionStarted, "you can't vote at the moment");
		require(votings[idEvent].listVoter[msg.sender].hasVoted == false, "You have already voted");
		votings[idEvent].listVoter[msg.sender].votedProposalId = _proposalId;
		votings[idEvent].listVoter[msg.sender].hasVoted = true;
		votings[idEvent].proposals[_proposalId].voteCount++;
		votings[idEvent].votersWhoVoted.push(msg.sender);
		emit Voted(msg.sender, _proposalId);
	}

	/**
	 * @dev Get one voter
	 * @param _addressVoter address of a voter
	 * @return voter one Voter
	 */
	function getVoter(address _addressVoter) public view returns(Voter memory){
		uint idEvent = votings.length -1;
		Voter memory voter = votings[idEvent].listVoter[_addressVoter];
		require(voter.hasVoted == true, "he hasn't voted yet");
		return (voter);
	}
	/**
	 * @dev Get all voters
	 * @return voters array Voter
	 */
	function getAllVoter() public view returns(address[] memory){
		uint idEvent = votings.length -1;
		address[] memory votersWhoVoted = votings[idEvent].votersWhoVoted;
		uint nbrVoters = votersWhoVoted.length;
		require(nbrVoters > 0, "No one has voted yet");
		return (votersWhoVoted);
	}
	/**
	 * @dev Get winner proposal
	 * @return Proposal return the winning proposal(s)
	 */
	function getWinner() public view returns(string memory){
		uint idEvent = votings.length -1;
		WorkflowStatus tempWorkflowStatus = votings[idEvent].workflowStatus;
		require(tempWorkflowStatus == WorkflowStatus.VotingSessionEnded || tempWorkflowStatus == WorkflowStatus.VotesTallied, "Voting is not over yet");
		uint nbrProposals = votings[idEvent].nbrOfProposals;
		string memory proposalsWin;
		uint win;
		for(uint i = 0; i < nbrProposals; i++){
			string memory description = votings[idEvent].proposals[i].description;
			uint _voteCount = votings[idEvent].proposals[i].voteCount;
			if (_voteCount > win) {
				proposalsWin = "";
				proposalsWin = string(
					abi.encodePacked(
						'Proposal Win ',uint2str(i),', with description : ',description, 'and a number of votes of ',uint2str(_voteCount)
						));
				win = _voteCount;
			}else if (_voteCount == win){
				string memory exAequo = string(
					abi.encodePacked(
						' ex aequo with','Proposal Win ',uint2str(i),', with description : ',description, 'and a number of votes of ',uint2str(_voteCount)
						));
				proposalsWin = string(abi.encodePacked(proposalsWin,exAequo));				
			}
		}
		return proposalsWin;
	}

	/**
	 * @dev Get proposals
	 * @return proposal array proposals
	 */
	function getAllProposal() public view returns(Proposal[] memory){
		uint idEvent = votings.length -1;
		uint nbrProposals = votings[idEvent].nbrOfProposals;
		require(nbrProposals > 0, "There are no proposals yet");
		Proposal[] memory proposals = new Proposal[](nbrProposals);
		for(uint i = 0; i < nbrProposals; i++){
			proposals[i] = votings[idEvent].proposals[i];
		}
		return proposals;
	}
	/**
	 * @dev Get all proposal
	 * @param _id identifier of the proposal
	 * @return proposal informations
	 */
	function getProposal(uint _id) public view returns(Proposal memory){
		uint idEvent = votings.length -1;
		Proposal memory proposal = votings[idEvent].proposals[_id];
		return proposal;
	}
	/**
	 * @dev change event status
	 * @param _status new WorkflowStatus
	 */
	function workflowStatusChange(WorkflowStatus _status) public onlyOwner {
		uint idEvent = votings.length -1;
		WorkflowStatus previousStatus = votings[idEvent].workflowStatus;

		bool previousIsProposalStatus = previousStatus == WorkflowStatus.ProposalsRegistrationStarted || previousStatus == WorkflowStatus.ProposalsRegistrationEnded;

		bool forStartProposal = previousStatus == WorkflowStatus.RegisteringVoters && _status == WorkflowStatus.ProposalsRegistrationStarted;
		bool forEndProposal = previousStatus == WorkflowStatus.ProposalsRegistrationStarted && _status == WorkflowStatus.ProposalsRegistrationEnded;
		bool forStartVoting = previousIsProposalStatus && _status == WorkflowStatus.VotingSessionStarted;
		bool forEndVoting = previousStatus == WorkflowStatus.VotingSessionStarted && _status == WorkflowStatus.VotingSessionEnded;
		bool forTallied = previousStatus == WorkflowStatus.VotingSessionEnded && _status == WorkflowStatus.VotesTallied;

		if(forStartProposal){
			votings[idEvent].workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
		}else if(forEndProposal){
			votings[idEvent].workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
		}else if(forStartVoting){
			require(votings[idEvent].nbrOfProposals > 0, "there are no registered proposals yet");
			votings[idEvent].workflowStatus = WorkflowStatus.VotingSessionStarted;
		}else if(forEndVoting){
			votings[idEvent].workflowStatus = WorkflowStatus.VotingSessionEnded;
		}else if(forTallied){
			votings[idEvent].workflowStatus = WorkflowStatus.VotesTallied;
		}else{
			revert("the chosen status is not good");
		}
		emit WorkflowStatusChange(previousStatus, _status);
	}

	/**
	 * @dev add a voter
	 * @param _address address to add
	 */
	function voterRegistered(address _address) public onlyOwner inRegisteringStatus{
		uint idEvent = votings.length -1;
		votings[idEvent].listVoter[_address].isRegistered = true;
		votings[idEvent].nbrVoters++;
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
			votings[idEvent].nbrVoters++;
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
		votings[idEvent].nbrVoters--;
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
			votings[idEvent].nbrVoters--;
		}
		emit VotersExcluded(_address);
	}


	function uint2str(uint256 _i) internal pure returns (string memory str) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 length;
		while (j != 0) {
			length++;
			j /= 10;
		}
		bytes memory bstr = new bytes(length);
		uint256 k = length;
		j = _i;
		while (j != 0) {
			bstr[--k] = bytes1(uint8(48 + j % 10));
			j /= 10;
		}
		str = string(bstr);
	}
}