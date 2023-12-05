// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {WorldWarIVMitigationFactory} from "../src/PeaceFactory.sol";

contract MitigationScript is Script {
    address admin;
    //WorldWarIVMitigationFactory factory;

    function setUp() public {}

    function run(address _Peaceadmin) public returns (address payable factory) {
        vm.startBroadcast();
        factory = payable(address(new WorldWarIVMitigationFactory(_Peaceadmin)));
        vm.stopBroadcast();
    }
}
