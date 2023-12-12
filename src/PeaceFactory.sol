// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WorldWarIV_Mitigation} from "./WorldWar4.sol";
import {IWorldWar4_Mitigation} from "./interface/IWorldWar4_Mitigation.sol";
import {IWorldWar4_MitigationFactory} from "./interface/IWorldWarIV_MitigationFactory.sol";
import {VRFv2Consumer} from "./VRFv2Consumer.sol";

contract WorldWarIVMitigationFactory is IWorldWar4_MitigationFactory {
    //WorldWarIVMitigationFactory contract address on sepolia = 0x691162D966A43f43700545577d0C3b54E69c95ED 
    // videoLiink https://www.loom.com/share/5dace74a472d4f77803b740e0643a118?sid=89ab2e7f-1448-4dc4-b782-e02174ec19a0
    ///////////////////////////////////////////////////======Custom Datatype======///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // All custom Data-type are imported Fron interface IWorldWar4_MitigationFactory

    ///////////////////////////////////////////////////======State======/////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Deployment fee
    uint256 public minFee;

    //factory asdmin address
    address payable public peaceAdmin;

    //fee receipient address
    address feeRecipient;

    // if chainlinkVRFv2 is initialized
    bool public chainlinktInitialized;

    //Total feedback counts
    uint public feedbkCount;

    // foundry local chainid for local testing
    uint constant LOCALFOUNDRYCHAINID = 31337;

    //mapping `UiniqueId` to contract address
    mapping(bytes32 contractUniqueDeployID => address) deployedContracts;

    //archive for conclusive voting (see winner)
    mapping(bytes32 contractUniqueDeployID => Record) ArchiveConclusive;

    //Archive for inconclusive voting (see tie)
    mapping(bytes32 contractUniqueDeployID => string[] Names) ArchiveInconclusive;

    //if a contracts result have been updated
    mapping(address => bool) recordsUpdated;

    //Serial of feedbacks
    mapping(uint => bytes) feedBacks;

    //just a counter of local test (may remove on mainnet)
    uint256 private a;

    //Instance of VRFv2consumer contract
    VRFv2Consumer public VRFconsumerContract;

    ///////////////////////////////////////////////////======Error Declarations======///////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    error AdminOnlyFunction();
    error ExceedsFeedBackMaxLength();
    error InvalidSender();
    error RecordAlreadyUpdated();
    error InsufficientFee(uint256 _fee);
    error ChainlinkAlreadyInitialized();
    error VRFv2InitializationFailed();
    error InvalidNumbersGenerated();

    ///////////////////////////////////////////////////======Events======//////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    event FeeUpdated(uint256 newFee);
    event PeaceDeployed(address indexed Peace, address deployer, address admin);
    event ArchiveUpdated(bytes32 id);
    event ConfigurationUpdated();
    event FeedbackReceived(address sender);

    ///////////////////////////////////////////////////======Modifiers======///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
    /**
    @dev ensures Chainlink VRFv2 is initialized and never re-initialized
     */
    modifier initilizer(){
        if (chainlinktInitialized) revert ChainlinkAlreadyInitialized();
        _;
    }
    ///////////////////////////////////////////////////======StateChangers======/////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    constructor() {
        peaceAdmin = payable(msg.sender);
        _initializeChainlinkVRFv2();
        //Security: reverts if unsuccesful. This prevents subsequent unexpected overwrites on archive
        if (address(VRFconsumerContract) == address(0))  revert VRFv2InitializationFailed(); 
        chainlinktInitialized = true;
    }
    /**
    @dev This is the specific function that deploys an instance of the contract
    @param _owner would be the admin of the to-be-deployed contract (WorldWarIV_Mitigation)
    @param _timeUntilVotingStarts is amount of time (from now) till voting starts. proly registration window
    @param _timeUntilVotingEnds is amount of time (from now) till voting ends. At which no more voting. Only then can `voteSortingAlgorithm()` be called and result displayed.
    @param CCIPRouter address of CCIPRoouter
     */
    function deployPeace(address _owner, uint256 _timeUntilVotingStarts, uint256 _timeUntilVotingEnds,uint256 _delayB4Computation, address CCIPRouter)
        public
        payable
        returns (IWorldWar4_Mitigation Peace)
    {
        uint256 cachedMsgValue = msg.value;
        if (cachedMsgValue < minFee) revert InsufficientFee(minFee); //checks fee
        address newPeace = _deploy(_owner, _timeUntilVotingStarts, _timeUntilVotingEnds,_delayB4Computation,CCIPRouter);
        Peace = IWorldWar4_Mitigation(newPeace); //returns interface of instance
    }

    

    

    function updateRecordsForWinnerCallback(WorldWarIV_Mitigation.Candidate memory _winner, bytes32 _id) external Check(_id) {
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
    /**
    @dev This allows for any usesr or non-user to give some feedback to the protacol. Feedback string should be straight to the point not a long note.
    For Security and efficiency, string is converted to bytes b4 storing
     */
    function feedBack (string memory _feedback) external returns(bool success){
        bytes memory feedBack_ = abi.encodePacked(_feedback);
        if (feedBack_.length > 250 ) revert ExceedsFeedBackMaxLength();
        feedBacks[++feedbkCount] = feedBack_;
        success = true;
        emit FeedbackReceived(msg.sender);
    }

    

    ///////////////////////////////////////////////////======Utils======//////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _deploy(address _owner, uint256 _timeUntilVotingStarts, uint256 _timeUntilVotingEnds, uint256 _delayB4Computation, address CCIPRouter)
        internal
        returns (address peace)
    {
        bytes32 UniqueId; // used as salt and as unique identifier
        if (block.chainid != LOCALFOUNDRYCHAINID) {
            UniqueId = generateUniqueRandomIdWithChainlinkVRV2F();
        } else {
            UniqueId = generateUniqueIdForFoundryLocalTest(); //This is to generate Id for local foundry test. code / function will be removed on mainnet.
        }

        bytes memory creationCode = abi.encodePacked(
            type(WorldWarIV_Mitigation).creationCode, 
            abi.encode(_owner, _timeUntilVotingStarts, _timeUntilVotingEnds, _delayB4Computation, this, UniqueId, CCIPRouter)
        );
        // Just so u know I fuck in assembly too. lol!
        assembly {
            peace := create2(0, add(creationCode, 0x20), mload(creationCode), UniqueId)
            //ensures deployed else value trapped
            if iszero(extcodesize(peace)) {
                revert(0, 0)
            }
        }

    }

    //VRF
    //V2Consumer address on Sepolia 0x93fe8684B7083150fDC767d5Cbb9F9cF6d51AfAB (old!)
    // consumer ID 7497
    /**
    @dev this function generates randon Nums from VRFv2. Note that the consumer contract was deployed during initialization.
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

        //algo simply check for the rare num
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

    ///////////////////////////////////////////////////======Getters======/////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // future investigation on Abraham lincoln Presidency
    function viewConclusiveArchive(bytes32 _Id) public view returns (Record memory) {
        return ArchiveConclusive[_Id];
    }

    function viewInconclusiveArchive(bytes32 _Id) public view returns (string[] memory) {
        return ArchiveInconclusive[_Id];
    }

    ///////////////////////////////////////////////////======Admin-Func======/////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //function deployImmediateStartVoting() public onlyIfAdmin
    function withdrawFees(address _collector) external PeaceAdminOnly {
        uint256 cachebal = address(this).balance;
        (bool success,) = _collector.call{value: cachebal}("");
        require(success, "withdrawal failed");
    }

    function adminConfig(address _admin, uint256 _fee) public PeaceAdminOnly returns (bool) {
        minFee = _fee;
        if (_admin != address(0) && _admin != peaceAdmin) {
            peaceAdmin = payable(_admin);
        }
        return true;
    } 

    function readFeedBack(uint count) public view returns(string memory){
        bytes memory feedBackBytes = feedBacks[count];
        return abi.decode(abi.encode(feedBackBytes), (string)); // encodes bytes for efficient decoding to string
    }

    receive() external payable {}
}
