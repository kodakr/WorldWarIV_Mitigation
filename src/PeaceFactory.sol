// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WorldWarIV} from "./WorldWar4.sol";
import {IWorldWar4_Mitigation} from "./interface/IWorldWar4_Mitigation.sol";
import {IWorldWar4_MitigationFactory} from "./interface/IWorldWarIV_MitigationFactory.sol";

contract WorldWarIVMitigationFactory is IWorldWar4_MitigationFactory {
    ///////////////////////////////////////////////////======Custom Datatype======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////======State======/////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    uint256 public fee;
    address payable public peaceAdmin;
    address feeRecipient;
    mapping(bytes32 contractUniqueDeployID => address) deployedContracts;
    mapping(bytes32 contractUniqueDeployID => Record) ArchiveConclusive;
    mapping(bytes32 contractUniqueDeployID => string[] Names) ArchiveInconclusive;
    mapping(address => bool) recordsUpdated;

    uint256 private a;
    ///////////////////////////////////////////////////======Error Declarations======///////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    error AdminOnlyFunction();
    error InvalidSender();
    error RecordAlreadyUpdated();
    error InsufficientFee(uint256 _fee);

    ///////////////////////////////////////////////////======Events======////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    event FeeUpdated(uint256 newFee);
    event PeaceDeployed(address indexed Peace, address deployer, address admin);
    event ArchiveUpdated(bytes32 id);
    event ConfigurationUpdated();

    ///////////////////////////////////////////////////======Modifiers======/////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    modifier PeaceAdminOnly() {
        if (msg.sender != peaceAdmin) revert AdminOnlyFunction();
        _;
    }

    modifier Check(bytes32 id) {
        // check to recognise sender
        // callable by sender only once
        // can only change state mapped to its address
        if (msg.sender != deployedContracts[id]) revert InvalidSender();
        if (recordsUpdated[msg.sender] == true && ArchiveConclusive[id].Contract != address(0)) {
            revert RecordAlreadyUpdated();
        }
        _;
    }
    ///////////////////////////////////////////////////======StateChangers======/////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(address _peaceAdmin) {
        peaceAdmin = payable(_peaceAdmin);
    }

    function deployPeace(address _owner, uint256 _timeUntilVotingStarts, uint256 _timeUntilVotingEnds)
        public
        payable
        returns (IWorldWar4_Mitigation Peace)
    {
        uint256 cachedMsgValue = msg.value;
        if (cachedMsgValue < fee) revert InsufficientFee(fee);
        address newPeace = _deploy(_owner, _timeUntilVotingStarts, _timeUntilVotingEnds);
        Peace = IWorldWar4_Mitigation(newPeace);
    }

    function immediateVoting() public {}

    function adminConfig(address _admin, uint256 _fee) public PeaceAdminOnly returns (bool) {
        //
        fee = _fee;
        if (_admin != address(0) && _admin != peaceAdmin) {
            peaceAdmin = payable(_admin);
        }
        return true;
    }

    function updateRecordsForWinner(WorldWarIV.Candidate memory _winner, bytes32 _id) external Check(_id) {
        string memory cacheName = _winner.Name;
        ArchiveConclusive[_id] = Record({Contract: msg.sender, Winner: cacheName, Inconclusive: false});
        recordsUpdated[msg.sender] = true;
    }

    function updateRecordsForInconclusive(string[] memory _forSorting, bytes32 _id) external Check(_id) {
        ArchiveInconclusive[_id] = _forSorting;
        recordsUpdated[msg.sender] = true;
    }

    ///////////////////////////////////////////////////======Utils======/////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _deploy(address _owner, uint256 _timeUntilVotingStarts, uint256 _timeUntilVotingEnds)
        internal
        returns (address peace)
    {
        bytes32 _Id = generateUniqueRandomIdWithChainlinkVRV2F(); // used as salt

        bytes memory creationCode = abi.encodePacked(
            type(WorldWarIV).creationCode, 
            abi.encode(_owner, _timeUntilVotingStarts, _timeUntilVotingEnds, this, _Id)
        );
        // Just so u know I fuck in assembly too. lol!
        assembly {
            peace := create2(0, add(creationCode, 0x20), mload(creationCode), _Id)
            if iszero(extcodesize(peace)) {
                revert(0, 0)
            }
        }

        // peace = address( new WorldWarIV{salt: _Id}(_owner,_timeUntilVotingStarts, _timeUntilVotingEnds, this, _Id)); // @audit without salt
        // deployedContracts[_Id] = peace;
    }

    //VRFV2Consumer address on Sepolia 0x93fe8684B7083150fDC767d5Cbb9F9cF6d51AfAB
    // consumer ID 7497

    function generateUniqueRandomIdWithChainlinkVRV2F() internal returns (bytes32 _id) {
        return keccak256(abi.encode(++a));
    }

    ///////////////////////////////////////////////////======Getters======///////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function viewConclusiveArchive(bytes32 _Id) public view returns (Record memory) {
        return ArchiveConclusive[_Id];
    }

    function viewInconclusiveArchive(bytes32 _Id) public view returns (string[] memory) {
        return ArchiveInconclusive[_Id];
    }

    ///////////////////////////////////////////////////======Admin======/////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //function deployImmediateStartVoting() public onlyIfAdmin
    function withdrawFees(address _collector) external PeaceAdminOnly {
        uint256 cachebal = address(this).balance;
        (bool success,) = _collector.call{value: cachebal}("");
        require(success, "withdrawal failed");
    }
    //This funct is only for destroying testnet version

    function selfdestructcontract() public {
        selfdestruct(peaceAdmin);
    }

    receive() external payable {}
}
