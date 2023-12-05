// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IWorldWar4_Mitigation} from "./IWorldWar4_Mitigation.sol";
//import {WorldWarIVMitigationFactory} from "../PeaceFactory.sol";

interface IWorldWar4_MitigationFactory {
    struct Record {
        address Contract;
        string Winner; // Null if voting is inconclusive or tied result
        bool Inconclusive;
    }

    function withdrawFees(address _collector) external;
    function deployPeace(address _owner, uint256 _timeUntilVotingStarts, uint256 _timeUntilVotingEnds)
        external
        payable
        returns (IWorldWar4_Mitigation Peace);
    function viewInconclusiveArchive(bytes32 _Id) external view returns (string[] memory);
    function viewConclusiveArchive(bytes32 _Id) external view returns (Record memory);
}
