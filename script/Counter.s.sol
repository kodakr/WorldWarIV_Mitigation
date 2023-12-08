// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {WorldWarIVMitigationFactory} from "../src/PeaceFactory.sol";

contract MitigationScript is Script {
    address admin;
    //WorldWarIVMitigationFactory factory;

    function setUp() public {}

    function run() public returns (address payable factory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        factory = payable(address(new WorldWarIVMitigationFactory()));
        vm.stopBroadcast();
        console.log("addr=====",factory);
    }

}

// 0x03905e60759b03979314f5a5bA788C93E20cdC8c
    // forge script script\Counter.s.sol:MitigationScript --rpc-url $SEPOLIA_URL --broadcast --verify -vvvv

    //https://sepolia.infura.io/v3/3d05647a39544dafab60d295c1ece741

