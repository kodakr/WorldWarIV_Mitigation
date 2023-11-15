// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IWorldWar4_Mitigation} from "./IWorldWar4_Mitigation.sol";


interface IWorldWar4_MitigationFactory {
    function withdrawFees(address _collector) external;
    function deployPeace(address _owner, uint _timeUntilVotingStarts,uint _timeUntilVotingEnds) external returns (IWorldWar4_Mitigation Peace);
    function withdrawFees(address _collector) external;
    function viewInconclusiveArchive(bytes32 _Id) external view returns (string [] memory);
    function viewConclusiveArchive(bytes32 _Id) external view returns(Record memory);
    
    
}