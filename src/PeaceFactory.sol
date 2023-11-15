// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {WorldWarIV} from "./WorldWar4.sol";
import { IWorldWar4_Mitigation } from "./interface/IWorldWar4_Mitigation.sol";

contract WorldWarIVMitigationFactory {
    WorldWarIV.Candidate winner;

     ///////////////////////////////////////////////////======Custom Datatype======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    struct Record {
        address Contract;
        string Winner; // Null if voting is inconclusive or tied result
        bool Inconclusive;
    }

     ///////////////////////////////////////////////////======State======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    uint public fee;
    address public immutable peaceAdmin;
    mapping (bytes32 contractUniqueDeployID => address ) deployedContracts;
    mapping (bytes32 contractUniqueDeployID => Record ) ArchiveConclusive;
    mapping (bytes32 contractUniqueDeployID => string [] Names ) ArchiveInconclusive;
    mapping (address => bool) recordsUpdated;

    uint private a;
    //mapping();
     ///////////////////////////////////////////////////======Error Declarations======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    error AdminOnlyFunction();
    error InvalidSender();
    error RecordAlreadyUpdated();

     ///////////////////////////////////////////////////======Events======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    event FeeUpdated(uint newFee);
    event PeaceDeployed(address indexed Peace, address deployer, address admin);
    event ArchiveUpdated(bytes32 id);
    event ConfigurationUpdated();

     ///////////////////////////////////////////////////======Modifiers======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    modifier PeaceAdminOnly {
        if (msg.sender != peaceAdmin) revert AdminOnlyFunction();
        _;
    }
    modifier Check(bytes32 id) {
        // check to recognise sender
        // callable by sender only once
        // can only change state mapped to its address
        if (msg.sender != deployedContracts[id]) revert InvalidSender();
        if (recordsUpdated[msg.sender] == true && ArchiveConclusive[id].Contract != address(0)) revert RecordAlreadyUpdated();
        _;
    }
     ///////////////////////////////////////////////////======StateChangers======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor(address _peaceAdmin) {
        peaceAdmin = _peaceAdmin;
    }
    //votingEndedAsDrawOrInconclusive

    function deployPeace(address _owner, uint _timeUntilVotingStarts,uint _timeUntilVotingEnds) public returns (IWorldWar4_Mitigation Peace){
        address newPeace = _deploy(_owner, _timeUntilVotingStarts, _timeUntilVotingEnds);
        Peace = IWorldWar4_Mitigation(newPeace);
    }

    function immediateVoting() public {}

    function adminConfig() public view PeaceAdminOnly returns(bool) {
        //
        return true;
    }

    function updateRecordsForWinner(WorldWarIV.Candidate memory _winner, bytes32 _id) external Check(_id) {
        string memory cacheName = _winner.Name;
        ArchiveConclusive[_id] = Record({
            Contract: msg.sender,
            Winner: cacheName,
            Inconclusive: false
        });
        recordsUpdated[msg.sender] = true;
    }

    function updateRecordsForInconclusive(string [] memory _forSorting, bytes32 _id) external Check(_id) {
        ArchiveInconclusive[_id] = _forSorting;
        recordsUpdated[msg.sender] = true;
    }

     ///////////////////////////////////////////////////======Utils======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _deploy(address _owner, uint _timeUntilVotingStarts,uint _timeUntilVotingEnds) internal returns(address){
        bytes32 _Id = generateUniqueRandomId(); // used as salt
        address peace = address( new WorldWarIV{salt: _Id}(_owner,_timeUntilVotingStarts, _timeUntilVotingEnds, this, _Id)); // @audit without salt
    }

    function generateUniqueRandomId() internal returns(bytes32 _id){
        return keccak256(abi.encode(++a));
    }

     ///////////////////////////////////////////////////======Getters======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function viewConclusiveArchive(bytes32 _Id) public view returns(Record memory){
        return ArchiveConclusive[_Id];
    }

    function viewInconclusiveArchive(bytes32 _Id) public view returns (string [] memory){
        return ArchiveInconclusive [_Id];
    }

     ///////////////////////////////////////////////////======Admin======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //function deployImmediateStartVoting() public onlyIfAdmin
    function withdrawFees(address _collector) external PeaceAdminOnly {
        uint cachebal = address(this).balance;
        (bool success,) = _collector.call{value: cachebal}("");
        require(success, "withdrawal failed");
    }
    receive() external payable {}
}
