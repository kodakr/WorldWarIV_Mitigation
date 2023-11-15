// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Script.sol";
import {WorldWarIVMitigationFactory} from "../src/PeaceFactory.sol";

contract MitigationScript is Script {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address admin;
    WorldWarIVMitigationFactory factory;
    function setUp() public {}

    function run() public  returns (address){
        vm.startBroadcast();
        factory = new WorldWarIVMitigationFactory(admin);
        vm.stopBroadcast();
        return factory;
        //console.log("addr==+===", address(PeaceFactory));
    }
}
