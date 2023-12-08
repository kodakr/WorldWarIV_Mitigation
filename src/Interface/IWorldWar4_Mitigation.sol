// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IWorldWar4_Mitigation {
    struct Candidate {
        uint8 Id;
        string Name;
        uint256 VoteCount;
    }
    struct SignVote {
    address Self;
    uint256 CandidateToVote;
    }
    //address Addr;

    function RegisterVoters(address[] memory _voters) external returns (bool);
    function RegisterCandidates(string[] memory _candidates) external returns (bool);
    function isVotingCurrentlyOn() external view returns (bool);
    function vote(uint8 _candidateIdOrIndex) external returns (bool);
    function voteSortingAlgorithm() external returns (bool Won, bool Inconclusive);
    function isRegisteredVoter(address _voter) external view returns (bool);
    function revealWinner() external view returns (Candidate memory);
    function fetchCandidateWithId(uint8 _id) external view returns (Candidate memory);
    function getMaxIndexForCandidates() external view returns (uint256);
    function watchLiveTelevision() external view returns (Candidate[] memory);
    function batchVoting(bytes[]calldata sigArray, SignVote[] memory signedStructArray ) external;
    function votingEndedWithAWinner() external view returns (bool);
    function votingEndedAsDrawOrInconclusive() external view returns (bool);
}
