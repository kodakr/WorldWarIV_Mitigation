// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WorldWarIVMitigationFactory} from "./PeaceFactory.sol";
import {IWorldWar4_Mitigation} from "./interface/IWorldWar4_Mitigation.sol";
import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
//author: https://twitter.com/Kodak_Rome

contract WorldWarIV is
    IWorldWar4_Mitigation //WorldWarIV_Mitigation
{
    ///////////////////////////////////////////////////======Custom Datatype======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////======State Variables======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    uint256 public numberOfCandidates;
    address public immutable admin;
    uint256 public votingStarts;
    uint256 public votingEnds;
    bool candidatesRegistrationDone;
    uint256 private allVoteCount;
    bool private EndedAsDrawOrInconclusive; //votingEndedAsDrawOrInconclusive
    bool private EndedWithAWinner;
    bytes32 contractUniqueDeployID;
    Candidate private winner;
    Candidate[] candidates; // liveTelevision
    Candidate[] private forSorting;
    WorldWarIVMitigationFactory worldWarIV_MitigationFactory;
    //Security: a map of valid and registered Voters. Only them can Vote to prevent sybil attack on election
    mapping(address => bool) private RegisteredVoters;
    mapping(uint256 Id => Candidate) RegisteredCandidates;
    mapping(address => bool) voted;

    ///////////////////////////////////////////////////======Errors Declaration======///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

    ///////////////////////////////////////////////////======Events Declaration======///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // future investigation on Abraham lincoln Presidency
    event CandidatesRegistered(string _candidate);
    event VoterRegistered(address indexed _voter);
    event VoteCasted(address indexed _voter);
    event EmergedWinner(Candidate _winner);
    event VotingInconclusiveDraw();

    ///////////////////////////////////////////////////======Modifiers======///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //ensures only the Admin has access to call func
    modifier OnlyAdmin() {
        if (msg.sender != admin) revert OnlyAdminAllowed();
        _;
    }

    //This ensures that a candidates' registration is a on is only registered once
    modifier OneTimeOperation() {
        if (candidatesRegistrationDone) revert CandidatesAlreadyRegistered();
        _;
    }

    modifier WhileVotingOn() {
        if (!isVotingCurrentlyOn()) revert NotVotingPeriod();
        _;
    }

    modifier RegisteredVoter() {
        if (!isRegisteredVoter(msg.sender)) revert NotARegisteredVoter();
        _;
    }

    modifier afterVotingEnds() {
        if (block.timestamp <= votingEnds) revert VotingNotEnded();
        _;
    }

    ///////////////////////////////////////////////////======State Changers======///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Allows a deployer to irrevocably assign an admin (Itself or other)
     * @param _admin address with admin priviledge in this deploy
     * @param _timeUntilVotingStarts is time from now till voting starts. perhaps registration period. eg 3 days, 4 weeks, 1 years (for National Presidential Election)
     * Ubiquity: 
     * 1 years = for National presidential election
     * 0 = For Instant decision
     * @param _timeUntilVotingEnds is time from deployment till votng stops. Time when Admin can then sort votes and declare winner.
     * @param _factory is factory (deployer) 
     * @param _uniqueID automatically generated using chainlink.
     */
    constructor(
        address _admin,
        uint256 _timeUntilVotingStarts,
        uint256 _timeUntilVotingEnds,
        WorldWarIVMitigationFactory _factory,
        bytes32 _uniqueID
    ) {
        // if (numberOfCandidates == 0) revert zeroCandidate();
        if (_timeUntilVotingEnds <= _timeUntilVotingStarts) revert ZeroVotingduration();
        admin = _admin;
        votingStarts = block.timestamp + _timeUntilVotingStarts;
        votingEnds = block.timestamp + _timeUntilVotingEnds;
        worldWarIV_MitigationFactory = _factory;
        contractUniqueDeployID = _uniqueID;
    }
    /**
     * @dev Registers new voters. Skips registration of previously voted addr. does this **silently** and not by revert. As reverting would
     * introduce an attack surface for DOS in batch registration operation(eg: say In US state election, only 1 invalid out of >1000 is required to DOS entire batch process. 
     * Skipping silently is an ooptimal practice imo).
     * @param _voters is an array of voters addr to be registered. Batch operation enabled.
     */

    function RegisterVoters(address[] memory _voters) public OnlyAdmin returns (bool) {
        for (uint256 i = 0; i < _voters.length; i++) {
            if (_voters[i] != address(0) && (!voted[_voters[i]])) {
                //Security: Skips any possible inclusion of null address and previously voted addrress
                RegisteredVoters[_voters[i]] = true;
                emit VoterRegistered(_voters[i]);
            }
        }
        return true;
    }
    /**
     * @dev programatically setUp the Candidate data type with the given string[] input Only. 
     * @param _candidates array consisting of candidates
     * For ease and ensuring IDs are of consecutive Increment and Votecount
     * starts from 0 (unmanipulated)
     * Security: Input as strings[] instead of Candidates[] prevents potential manipulation by admin. eg input Candidate.Votecount with +ve integer.
     * Hence programatically setting up Candidate struct is more secure and trustless for all.
     * @dev Note that this is a once only event. Callable only once.
     */

    function RegisterCandidates(string[] memory _candidates) public OnlyAdmin OneTimeOperation returns (bool) {
        numberOfCandidates = _candidates.length;

        for (uint8 i = 0; i < numberOfCandidates; i++) {
            candidates.push(Candidate({Id: i, Name: _candidates[i], VoteCount: 0}));
            Candidate storage cd = RegisteredCandidates[i];
            cd = candidates[i];
            emit CandidatesRegistered(_candidates[i]);
            // RegisteredCandidates[i] = _candidates[i];
            // candidates.push(_candidates[i]);
        }
        candidatesRegistrationDone = true;
        return true;
    }

    function vote(uint8 _candidateIdOrIndex) public WhileVotingOn RegisteredVoter returns (bool) {
        return _vote(_candidateIdOrIndex, msg.sender);
    }

    function voteSortingAlgorithm() external OnlyAdmin afterVotingEnds returns (bool Won, bool Inconclusive) {
        uint256 index;
        forSorting.push(RegisteredCandidates[index]); //pushes to  array in storage (since solidity doesnt `push()` to memory)
        for (uint256 j = 1; j < numberOfCandidates - 1; j++) {
            uint256 cacheLastIndexinForSortingArray = forSorting.length - 1;
            Candidate memory cache = forSorting[cacheLastIndexinForSortingArray];
            if (RegisteredCandidates[j].VoteCount > cache.VoteCount) {
                delete forSorting;
                forSorting.push(cache);
            } else if (RegisteredCandidates[j].VoteCount == cache.VoteCount) {
                forSorting.push(cache);
            } else {
                continue;
            }
        }
        declareWinner();
        Won = EndedWithAWinner;
        Inconclusive = EndedAsDrawOrInconclusive;
    }

    function batchVoting(bytes[] calldata sig) external {}

    //////////////////////////////////////////////////======Utils======//////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function declareWinner() private {
        if (forSorting.length == 1) {
            winner = forSorting[0];
            EndedWithAWinner = true;
            emit EmergedWinner(forSorting[0]);
        } else {
            if (forSorting.length == 0) revert SortingError(); // Hopefully Unreachable code line. The reason my test coverage wont hit 100%. Lol!
            EndedAsDrawOrInconclusive = true;
            emit VotingInconclusiveDraw();
        }
        updateFactoryRecords(EndedWithAWinner);
    }

    function _vote(uint256 _candidateIdOrIndex, address _voter) private returns (bool Voted) {
        if (_candidateIdOrIndex > getMaxIndexForCandidates()) revert InvalidIdRange();
        //Security: disenfranchise Immediately (Can only vote once)
        RegisteredVoters[_voter] = false;
        allVoteCount++;
        RegisteredCandidates[_candidateIdOrIndex].VoteCount++;
        if (!RegisteredVoters[_voter]) {
            //Security: expected to be always true. Just for accuracy b4 state changes & media publish (Television & emitting)
            emit VoteCasted(_voter);
            updateLiveTelevision();
            voted[_voter] = true;
            Voted = true;
        }
    }

    function updateLiveTelevision() private {}

    function updateFactoryRecords(bool _votingEndedWithAWinner) internal {
        if (_votingEndedWithAWinner) {
            worldWarIV_MitigationFactory.updateRecordsForWinner(winner, contractUniqueDeployID);
        } else {
            uint256 cacheLength = forSorting.length;
            string[] memory _tiedWinners = new string[](cacheLength);
            for (uint256 i; i < cacheLength; i++) {
                _tiedWinners[i] = forSorting[i].Name;
            }
            worldWarIV_MitigationFactory.updateRecordsForInconclusive(_tiedWinners, contractUniqueDeployID);
        }
    }

    function hasVoted(address _inquirer) internal view returns (bool) {
        return voted[_inquirer];
    }

    ///////////////////////////////////////////////////======Getter Functions======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getMaxIndexForCandidates() public view returns (uint256) {
        return candidates.length - 1;
    }

    /**
     * @dev This is equivalent of a live TV. Returns the current state of voting while voting is on.
     */
    function watchLiveTelevision() public view WhileVotingOn returns (Candidate[] memory) {
        return candidates;
    }

    function isRegisteredVoter(address _voter) public view returns (bool) {
        if (_voter == address(0)) _voter = msg.sender;
        return RegisteredVoters[_voter];
    }

    function revealWinner() public view returns (Candidate memory) {
        return winner;
    }

    function fetchCandidateWithId(uint8 _id) public view returns (Candidate memory) {
        return RegisteredCandidates[_id];
    }

    function isVotingCurrentlyOn() public view returns (bool) {
        uint256 cachedTimestamp = block.timestamp;
        if (cachedTimestamp >= votingStarts && cachedTimestamp <= votingEnds) {
            return true;
        }
        return false;
    }

    function wasMyVoteSuccessful() public view returns (bool) {
        return hasVoted(msg.sender);
    }

    function votingEndedWithAWinner() public view returns (bool) {
        return EndedWithAWinner;
    }

    function votingEndedAsDrawOrInconclusive() public view returns (bool) {
        return EndedAsDrawOrInconclusive;
    }
}
