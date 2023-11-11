// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {WorldWarIV} from "./WorldWar4.sol";

contract WorldWarIVMitigationFactory {
    WorldWarIV.Candidate winner;
    struct Record {
        address Contract;
        string Winner; // Null if voting is inconclusive or tied result
        bool Inconclusive;
    }

    uint public fee;
    address public immutable peaceAdmin;
    mapping (bytes32 contractUniqueDeployID => address ) deployedContracts;
    
    mapping (bytes32 contractUniqueDeployID => Record ) ArchiveConclusive;
    mapping (bytes32 contractUniqueDeployID => string [] Names ) ArchiveInconclusive;

    mapping (address => bool) recordsUpdated;
    //mapping();

    error AdminOnlyFunction();
    error InvalidSender();
    error RecordAlreadyUpdated();

    event FeeUpdated(uint newFee);
    event PeaceDeployed(address indexed Peace, address deployer, address admin);
    event ArchiveUpdated(bytes32 id);
    event ConfigurationUpdated();

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

    constructor(address _peaceAdmin) {
        peaceAdmin = _peaceAdmin;
    }
    //votingEndedAsDrawOrInconclusive

    // function deployPeace(address _owner) public returns(address Peace){
    //     assembly {
    //         Peace := create(0,)

    //     }
    // }

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
    function updateRecordsForInconclusive(string [] memory _forSorting, bytes32 _id) public Check(_id) {
        ArchiveInconclusive[_id] = _forSorting;
        recordsUpdated[msg.sender] = true;
    }
    //function deployImmediateStartVoting() public onlyIfAdmin

    function viewConclusiveArchive(bytes32 _Id) public view returns(Record memory){
        return ArchiveConclusive[_Id];
    }

    function viewInconclusiveArchive(bytes32 _Id) public view returns (string [] memory){
        return ArchiveInconclusive [_Id];
    }
    receive() external payable {}
}
