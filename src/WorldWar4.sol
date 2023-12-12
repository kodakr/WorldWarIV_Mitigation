// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WorldWarIVMitigationFactory} from "./PeaceFactory.sol";
import {IWorldWar4_Mitigation} from "./interface/IWorldWar4_Mitigation.sol";
import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";


//author: https://twitter.com/Kodak_Rome

contract WorldWarIV_Mitigation is CCIPReceiver,EIP712("WorldWar4", "1"), //
    IWorldWar4_Mitigation , AutomationCompatibleInterface
{
    ///////////////////////////////////////////////////======Custom Datatype======////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // All custom Data-type are imported Fron interface IWorldWar4_Mitigation

    ///////////////////////////////////////////////////======State Variables======////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //The total no of options or candidates
    uint256 public numberOfCandidates;

    // The admin
    address public immutable admin;

    //Time stamp for voting start
    uint256 public votingStarts;

    //Timestamp for voting end
    uint256 public votingEnds;

    //interval before computation and result
    uint public immutable delayB4Computation;

    //total count of allowed voters
    uint public RegisteredVoterCount;

    //Done registering candidates
    bool candidatesRegistrationDone;
    
    //Count of all votes
    uint256 private allVoteCount;

    //If votingEndedAsDrawOrInconclusive
    bool private EndedAsDrawOrInconclusive; 

    //If voting ended With a winner
    bool private EndedWithAWinner;

    //Contracts unique Identifier generated with chainlink VRFv2
    bytes32 contractUniqueDeployID;

    bool consensusReached;

    // Candidate or option emerged winner
    Candidate private winner;

    //An array displaying current state of voting while voting is on
    Candidate[] candidates; // liveTelevision

    // Just An util for `sortingAlgorithm()`
    Candidate[] private forSorting;

    // The factory (for callback)
    WorldWarIVMitigationFactory worldWarIV_MitigationFactory;

    //Security: a map of valid and registered Voters. Only them can Vote to prevent sybil attack on election
    mapping(address => bool) private RegisteredVoters;

    //mapping of candidates Id to candidate
    mapping(uint256 Id => Candidate) RegisteredCandidates;

    //If voter has voted
    mapping(address => bool) voted;

    //attempted but failed voters
    mapping(address => bool) failedVoters;

    //succesful voters via CCIP route
    mapping (address => bool) succesfulCCIPVoter;

    ///////////////////////////////////////////////////======Errors Declaration======///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    error ZeroVotingduration();
    error zeroCandidate();
    error OnlyAdminAllowed();
    error InvalidNumOfVoters();
    error VotingShouldStartASAP();
    error CandidatesRegisterationEnded();
    error NotVotingPeriod();
    error NotARegisteredVoter();
    error InvalidIdRange();
    error VotingNotEnded();
    error SortingError();
    error InvalidArrayLengthForBatch();

    ///////////////////////////////////////////////////======Events Declaration======///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // future investigation on Abraham lincoln Presidency
    event CandidatesRegistered(string _candidate);
    event VoterRegistered(address indexed _voter);
    event VoteCasted(address indexed _voter);
    event EmergedWinner(Candidate _winner);
    event VotingInconclusiveDraw();

    ///////////////////////////////////////////////////======Modifiers======///////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //ensures only the Admin has access to call func
    modifier OnlyAdmin() {
        if (msg.sender != admin) revert OnlyAdminAllowed();
        _;
    }

    //This ensures that a candidates' registration is a on is only registered once
    modifier OneTimeOperation() {
        if (candidatesRegistrationDone) revert CandidatesRegisterationEnded();
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
        uint256 _delayB4Computation,
        WorldWarIVMitigationFactory _factory,
        bytes32 _uniqueID,
        address Router
    ) CCIPReceiver(Router) {
        // if (numberOfCandidates == 0) revert zeroCandidate();
        if (_timeUntilVotingEnds <= _timeUntilVotingStarts) revert ZeroVotingduration();
        admin = _admin;
        votingStarts = block.timestamp + _timeUntilVotingStarts;
        votingEnds = block.timestamp + _timeUntilVotingEnds;
        worldWarIV_MitigationFactory = _factory;
        delayB4Computation = _delayB4Computation;
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
            //Security: Skips any possible inclusion of null address and previously voted addrress
            if (_voters[i] != address(0) && (!voted[_voters[i]])) {
                RegisteredVoters[_voters[i]] = true;
                emit VoterRegistered(_voters[i]);
                ++RegisteredVoterCount;
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

    function voteSortingAlgorithm() internal /*OnlyAdmin*/ afterVotingEnds returns (bool Won, bool Inconclusive) {
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
    /**
    @dev silently skips invalid and returns no. of invalid voters / addreses
     */
    function batchVoting(bytes[]calldata sigArray, SignVote[] memory signedStructArray ) external WhileVotingOn { 
        if (sigArray.length != signedStructArray.length) revert InvalidArrayLengthForBatch();
        for (uint i= 0; i < sigArray.length; i++) {
            bytes memory signedVote = sigArray[i];
            SignVote memory aSignedVote = signedStructArray[i];



            bytes32 hashStruct = keccak256(abi.encode(aSignedVote));
            bytes32 digest = _hashTypedDataV4(hashStruct);


            // verify sig and
            address signer = ECDSA.recover(digest,signedVote);
            uint candidate = aSignedVote.CandidateToVote;
            address claimedSigner = aSignedVote.Self;
            if (signer != claimedSigner || signer == address(0) || (! verifyCandidateIndex(candidate)) || voted[signer] || (! RegisteredVoters[signer]) || signedVote.length != 65) {
                if (signer != address(0)){
                    failedVoters[signer] = true;
                }
                continue;
            } else {
                _vote(candidate,signer);

            }

           
        }
    }

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
        if (! verifyCandidateIndex(_candidateIdOrIndex)) revert InvalidIdRange();
        //Security: disenfranchise Immediately (Can only vote once)
        RegisteredVoters[_voter] = false;
        allVoteCount++;
        RegisteredCandidates[_candidateIdOrIndex].VoteCount++;
        if (!RegisteredVoters[_voter]) {
            //Security: expected to be always true. Just for accuracy b4 state changes & media publish (Television & emitting)
            emit VoteCasted(_voter);
            voted[_voter] = true;
            Voted = true;
            if (allVoteCount % 10 == 0){ //Feature: updates live television after every 10 votes.
                updateLiveTelevision();
            }
        }
    }

    function updateLiveTelevision() private {
        delete candidates;
        for (uint r; r < numberOfCandidates; r++){
            Candidate memory c = RegisteredCandidates[r];
            candidates.push(c);
        }
    }

    function updateFactoryRecords(bool _votingEndedWithAWinner) internal {
        if (_votingEndedWithAWinner) {
            worldWarIV_MitigationFactory.updateRecordsForWinnerCallback(winner, contractUniqueDeployID);
        } else {
            uint256 cacheLength = forSorting.length;
            string[] memory _tiedWinners = new string[](cacheLength);
            for (uint256 i; i < cacheLength; i++) {
                _tiedWinners[i] = forSorting[i].Name;
            }
            worldWarIV_MitigationFactory.updateRecordsForInconclusiveCallback(_tiedWinners, contractUniqueDeployID);
        }
    }

    function hasVoted(address _inquirer) internal view returns (bool) {
        return voted[_inquirer];
    }
    ///////////////////////////////////////////////////======CCIP-Utils======/////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function checkUpkeep(bytes calldata ) external view override returns (bool upkeepNeeded, bytes memory retData){
        uint256 cachTime = block.timestamp; //delayB4Computation
        if((! consensusReached) && cachTime >= (votingEnds + delayB4Computation)){
            upkeepNeeded = true;
            retData = hex"";
        }
    }

    function performUpkeep(bytes calldata) external override {
        voteSortingAlgorithm();
        //make idempotent
        consensusReached = true;
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override  {
        uint candidate = abi.decode(any2EvmMessage.data, (uint));
        address sender = abi.decode(any2EvmMessage.sender, (address));
        _vote(candidate, sender);
        succesfulCCIPVoter[sender] = true;
    }

    function WasCCIPsuccesful(address _voter) public view returns(bool){
        return succesfulCCIPVoter[_voter];
    }

    

    ///////////////////////////////////////////////////======Getter Functions======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getMaxIndexForCandidates() public view returns (uint256) {
        return candidates.length - 1;
    }

    function verifyCandidateIndex(uint _candidateIdOrIndex) public view returns(bool){
         if (_candidateIdOrIndex > getMaxIndexForCandidates()) {
            return false;
         } else {
            return true;
         }

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