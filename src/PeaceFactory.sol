// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WorldWarIV} from "./WorldWar4.sol";
import {IWorldWar4_Mitigation} from "./interface/IWorldWar4_Mitigation.sol";
import {IWorldWar4_MitigationFactory} from "./interface/IWorldWarIV_MitigationFactory.sol";
import {VRFv2Consumer} from "./VRFv2Consumer.sol";

contract WorldWarIVMitigationFactory is IWorldWar4_MitigationFactory {
    ///////////////////////////////////////////////////======Custom Datatype======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////======State======/////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    uint256 public fee;
    address payable public peaceAdmin;
    address feeRecipient;
    bool chainlinktInitialized;
    uint public feedbkCount;
    uint constant LOCALFOUNDRYCHAINID = 31337;
    mapping(bytes32 contractUniqueDeployID => address) deployedContracts;
    mapping(bytes32 contractUniqueDeployID => Record) ArchiveConclusive;
    mapping(bytes32 contractUniqueDeployID => string[] Names) ArchiveInconclusive;
    mapping(address => bool) recordsUpdated;
    mapping(uint => bytes) feedBacks;
    uint256 private a;
    VRFv2Consumer VRFconsumerContract;

    ///////////////////////////////////////////////////======Error Declarations======///////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    error AdminOnlyFunction();
    error ExceedsFeedBackLength();
    error InvalidSender();
    error RecordAlreadyUpdated();
    error InsufficientFee(uint256 _fee);
    error ChainlinkAlreadyInitialized();
    error VRFv2InitializationFailed();
    error InvalidNumbersGenerated();

    ///////////////////////////////////////////////////======Events======////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    event FeeUpdated(uint256 newFee);
    event PeaceDeployed(address indexed Peace, address deployer, address admin);
    event ArchiveUpdated(bytes32 id);
    event ConfigurationUpdated();
    event FeedbackReceived(address sender);

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

    modifier initilizer(){
        if (chainlinktInitialized) revert ChainlinkAlreadyInitialized();
        _;
    }
    ///////////////////////////////////////////////////======StateChangers======/////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(address _peaceAdmin) {
        peaceAdmin = payable(_peaceAdmin);
        _initializeChainlinkVRFv2();
        if (address(VRFconsumerContract) == address(0))  revert VRFv2InitializationFailed();
        chainlinktInitialized = true;
    }

    function deployPeace(address _owner, uint256 _timeUntilVotingStarts, uint256 _timeUntilVotingEnds, address CCIPRouter)
        public
        payable
        returns (IWorldWar4_Mitigation Peace)
    {
        uint256 cachedMsgValue = msg.value;
        if (cachedMsgValue < fee) revert InsufficientFee(fee);
        address newPeace = _deploy(_owner, _timeUntilVotingStarts, _timeUntilVotingEnds,CCIPRouter);
        Peace = IWorldWar4_Mitigation(newPeace);
    }

    // function immediateVoting(address _owner, uint _timeUntilVotingStarts, uint _timeUntilVotingEnds) public payable returns (IWorldWar4_Mitigation Peace) {
    //     Peace = deployPeace{value: msg.value} (_owner,_timeUntilVotingStarts,_timeUntilVotingEnds);

    // }

    function adminConfig(address _admin, uint256 _fee) public PeaceAdminOnly returns (bool) {
        //
        fee = _fee;
        if (_admin != address(0) && _admin != peaceAdmin) {
            peaceAdmin = payable(_admin);
        }
        return true;
    } //callbackOnWinning
    //callbackOnIncocnclusive

    function updateRecordsForWinnerCallback(WorldWarIV.Candidate memory _winner, bytes32 _id) external Check(_id) {
        string memory cacheName = _winner.Name;
        ArchiveConclusive[_id] = Record({Contract: msg.sender, Winner: cacheName, Inconclusive: false});
        recordsUpdated[msg.sender] = true;
    }

    function updateRecordsForInconclusiveCallback(string[] memory _forSorting, bytes32 _id) external Check(_id) {
        ArchiveInconclusive[_id] = _forSorting;
        recordsUpdated[msg.sender] = true;
    }

    function _initializeChainlinkVRFv2() internal initilizer {
        VRFconsumerContract = new VRFv2Consumer(7497);
        
    }

    function feedBack (string memory _feedback) external returns(bool success){
        bytes memory feedBack_ = abi.encodePacked(_feedback);
        if (feedBack_.length > 250 ) revert ExceedsFeedBackLength();
        feedBacks[++feedbkCount] = feedBack_;
        success = true;
        emit FeedbackReceived(msg.sender);
    }

    

    ///////////////////////////////////////////////////======Utils======/////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _deploy(address _owner, uint256 _timeUntilVotingStarts, uint256 _timeUntilVotingEnds, address CCIPRouter)
        internal
        returns (address peace)
    {
        bytes32 UniqueId; // used as salt
        if (block.chainid != LOCALFOUNDRYCHAINID) {
            UniqueId = generateUniqueRandomIdWithChainlinkVRV2F();
        } else {
            UniqueId = generateUniqueIdForFoundryLocalTest();
        }

        bytes memory creationCode = abi.encodePacked(
            type(WorldWarIV).creationCode, 
            abi.encode(_owner, _timeUntilVotingStarts, _timeUntilVotingEnds, this, UniqueId, CCIPRouter)
        );
        // Just so u know I fuck in assembly too. lol!
        assembly {
            peace := create2(0, add(creationCode, 0x20), mload(creationCode), UniqueId)
            if iszero(extcodesize(peace)) {
                revert(0, 0)
            }
        }

    }

    //VRFV2Consumer address on Sepolia 0x93fe8684B7083150fDC767d5Cbb9F9cF6d51AfAB
    // consumer ID 7497
    /**
    @dev this function generates randon Nums from VRFv2. Note that the consumer contract has deployed durin initialization.
    And its owned by this factory contract. Hence factory can simply call for Rand num generation.
    The design implemented here to ensure "UniqueIdGeneration" is 
    1. Fetching two RandNum,
    2. If one has been previously used (checks mapping), then the 2nd is used.
    3. if both , Reverts. 
     */
    function generateUniqueRandomIdWithChainlinkVRV2F() internal returns (bytes32 _uniqueID) {
        
        uint requestId = VRFconsumerContract.requestRandomWords();
        (, uint256[] memory randomWords) = VRFconsumerContract.getRequestStatus(requestId);
        uint cacheLengthOfRandomWords = randomWords.length;
        //UniqueIdGeneration: If rand number has been previously used, then uses the 2nd RandNum. If both
        //are used, Reverts (Extremely rare)
        for(uint i; i < cacheLengthOfRandomWords; i++) {
           _uniqueID = keccak256(abi.encode(randomWords[i]));
            if (deployedContracts[_uniqueID] == address(0)) {
                return _uniqueID;
            }
            if (i == cacheLengthOfRandomWords - 1) revert InvalidNumbersGenerated(); // revert if all generated numbers have been used previously

        }
        
    }
    function generateUniqueIdForFoundryLocalTest() internal returns (bytes32) {
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

    function getFeedBack(uint count) public view returns(string memory){
        bytes memory feedBackBytes = feedBacks[count];
        return abi.decode(abi.encode(feedBackBytes), (string));
    }

    receive() external payable {}
}
