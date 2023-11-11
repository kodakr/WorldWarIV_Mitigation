// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
//import { Ownable } from "";
import {WorldWarIVMitigationFactory} from "./PeaceFactory.sol";

//author: https://twitter.com/Kodak_Rome

contract WorldWarIV{ //WorldWarIV_Mitigation

    struct Candidate{
        uint8 Id;
        string Name;
        uint VoteCount;
        //address Addr;
    }

    uint public numberOfCandidates;
    address public immutable admin;
    uint public votingStarts;
    uint public votingEnds;
    bool candidatesRegistered;
    uint private allVoteCount;
    bool votingEndedAsDrawOrInconclusive; //votingEndedAsDrawOrInconclusive
    bool votingEndedWithAWinner;
    bytes32 contractUniqueDeployID;
    Candidate private winner;
    Candidate [] candidates; // liveTelevision
    Candidate [] private forSorting;
    WorldWarIVMitigationFactory worldWarIV_MitigationFactory;
    
    error ZeroVotingduration();
    error zeroCandidate();
    error OnlyAdminAllowed();
    error InvalidNumOfVoters();
    error VotingShouldStartASAP();
    error CandidatesAlreadyRegistered();
    error NotVotingPeriod();
    error NotARegisteredVoter();
    error InvalidIdRange();
    error VotingNotEnded();
    error SortingError();

    // future investigation on Abraham lincoln Presidency
    event CandidatesRegistered(string _candidate);
    event VoterRegistered(address indexed _voter);
    event VoteCasted(address indexed _voter);
    event EmergedWinner(Candidate _winner);
    event VotingInconclusiveDraw();
    

    //Security: a map of valid and registered Voters. Only them can Vote to prevent sybil attack on election
    mapping (address => bool) private RegisteredVoters;
    mapping (uint Id => Candidate) RegisteredCandidates;

    modifier OnlyAdmin {
        if (msg.sender != admin) revert OnlyAdminAllowed();
        _;
    }
    modifier OneTimeOperation {
        if (candidatesRegistered) revert CandidatesAlreadyRegistered();
        _;
    }
    modifier WhileVotingOn {
        if (! isVotingCurrentlyOn())revert NotVotingPeriod();
        _;
    }
    modifier RegisteredVoter {
        if (! isRegisteredVoter(msg.sender)) revert NotARegisteredVoter();
        _;
    }
    modifier afterVotingEnds {
        if (block.timestamp <= votingEnds) revert VotingNotEnded();
        _;
    }

    /**
    @dev Allows a deployer to irrevocably assign an admin (Itself or other)
    @param _timeUntilVotingStarts can also be uint(0) for instant voting. // @audit if zero, then RegisterVoters in 1 tx
    // candidates [] can be emptyb if not immediate.
     */ 
    constructor(address _admin, uint _timeUntilVotingStarts,uint _timeUntilVotingEnds, WorldWarIVMitigationFactory _factory, bytes32 _uniqueID){
       // if (numberOfCandidates == 0) revert zeroCandidate();
        if (_timeUntilVotingEnds <= _timeUntilVotingStarts ) revert ZeroVotingduration();
        // if (_quickStartVoting) {
        //     if (_voters.length < 2) revert InvalidNumOfVoters();
        //     if (_timeUntilVotingStarts != uint(0)) revert VotingShouldStartASAP();
        //     bool registeredVoters = RegisterVoters(_voters);
        //     bool registeredCandidates = RegisterCandidates(_candidates);
        //     require(registered && registeredCandidates, "QuickRegistration Unsuccesful");
        // }
        admin = _admin;
        votingStarts = block.timestamp + _timeUntilVotingStarts;
        votingEnds = block.timestamp + _timeUntilVotingEnds;
        worldWarIV_MitigationFactory = _factory;
        contractUniqueDeployID = _uniqueID;
    }



    function RegisterVoters(address[] memory _voters) public OnlyAdmin returns(bool) {
        for (uint i=0; i < _voters.length; i++) {
            if (_voters[i] != address(0)) { //Security: Skips any possible inclusion of null address
                RegisteredVoters[_voters[i]] = true;
                emit VoterRegistered(_voters[i]);
            }
        }
        return true;
    }
    /**
    @dev programatically setUp the Candidate data type with the given string input. For ease and ensuring IDs are of consecutive Increment and Votecount
    starts from 0 (unmanipulated)
     */
    function RegisterCandidates(string [] memory _candidates) public OnlyAdmin OneTimeOperation returns(bool) {
        numberOfCandidates = _candidates.length;

         for (uint8 i=0; i < numberOfCandidates; i++) {
            candidates.push(Candidate({
                Id: i,
                Name: _candidates[i],
                VoteCount: 0
            }));
            Candidate storage cd = RegisteredCandidates[i];
            cd = candidates[i];
            emit CandidatesRegistered(_candidates[i]);
            // RegisteredCandidates[i] = _candidates[i];
            // candidates.push(_candidates[i]);
        }
        return true;
    }

    function declareWinner() private {
        if (forSorting.length == 1) {
            winner = forSorting[0];
            votingEndedWithAWinner = true;
            emit EmergedWinner(forSorting[0]);
        }else {
            if (forSorting.length == 0) revert SortingError(); // Hopefully Unreachable code line
            votingEndedAsDrawOrInconclusive = true;
            emit VotingInconclusiveDraw();
        }
        updateFactoryRecords(votingEndedWithAWinner);

    }
    function isVotingCurrentlyOn() public view returns (bool) {
         if (block.timestamp >= votingStarts && block.timestamp <= votingEnds) {
            return true;
         }
         return false;
    }
    function vote(uint8 _candidateIdOrIndex) public WhileVotingOn RegisteredVoter returns(bool){
        return _vote(_candidateIdOrIndex, msg.sender);
    }

    function _vote(uint _candidateIdOrIndex, address _voter) private returns (bool Voted) {
        if (_candidateIdOrIndex > getMaxIndexForCandidates()) revert InvalidIdRange();
        //Security: disenfranchise Immediately (Can only vote once)
        RegisteredVoters[_voter] = false;
        allVoteCount++;
        RegisteredCandidates[_candidateIdOrIndex].VoteCount++;
        if (!RegisteredVoters[_voter]) { //Security: expected to be always true. Just for accuracy b4 state changes & media publis (Television & emitting)
            emit VoteCasted(_voter);
            updateLiveTelevision();
            Voted = true;
        }

    }

    function voteSortingAlgorithm() external afterVotingEnds returns (bool Won, bool Inconclusive){
        uint index;
        forSorting.push(RegisteredCandidates[index]);//pushes to  array in storage (since solidity doesnt `push()` to memory)
        for (uint j = 1; j < numberOfCandidates - 1; j++) {
            uint cacheLastIndexinForSortingArray = forSorting.length -1;
            Candidate memory cache = forSorting[cacheLastIndexinForSortingArray];
            if (RegisteredCandidates[j].VoteCount > cache.VoteCount) {
                delete forSorting;
                forSorting.push(cache);
            }
            else if ( RegisteredCandidates[j].VoteCount == cache.VoteCount  ){
                forSorting.push(cache);
            }
            else{ continue;}
        }
        declareWinner();
        Won = votingEndedWithAWinner;
        Inconclusive = votingEndedAsDrawOrInconclusive;
    }

    function isRegisteredVoter(address _voter) public view returns(bool) {
        if (_voter == address(0)) {_voter = msg.sender;} 
        return RegisteredVoters[_voter];
    }

    function revealWinner()public view returns(Candidate memory) {
        return winner;
    }

    function fetchCandidateWithId(uint8 _id) public view returns(Candidate memory) {
        return RegisteredCandidates[_id];
    }

    function getMaxIndexForCandidates() public view returns (uint) {
        return candidates.length - 1;
    }
    /**
    @dev This is equivalent of a live TV
     */
    
    function watchLiveTelevision() public view returns(Candidate[] memory) {
        return candidates;
    }

    function updateLiveTelevision() private {}

    function batchVoting(bytes[] calldata sig) external {}

    function updateFactoryRecords( bool _votingEndedWithAWinner) internal {
        if (_votingEndedWithAWinner){
            worldWarIV_MitigationFactory.updateRecordsForWinner(winner, contractUniqueDeployID);
        } else {
            uint cacheLength = forSorting.length;
            string [] memory _tiedWinners = new string[](cacheLength);
            for (uint i; i < cacheLength; i++){
                _tiedWinners[i] = forSorting[i].Name;
            }
            worldWarIV_MitigationFactory.updateRecordsForInconclusive(_tiedWinners,contractUniqueDeployID);
        }
    }
}
