// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {WorldWarIV, WorldWarIVMitigationFactory } from "../src/WorldWar4.sol"; 
import {IWorldWar4_MitigationFactory} from "../src/interface/IWorldWarIV_MitigationFactory.sol";
import "forge-std/console.sol";

contract CounterTest is Test {
    //WorldWarIV worldwar;
    address admin = makeAddr("admin");
    address hacker = makeAddr("hacker");
    address voter1 = makeAddr("voter1");
    address voter2 = makeAddr("voter2");
    address voter3 = makeAddr("voter3");
    address voter4 = makeAddr("voter4");
    address voter5 = makeAddr("voter5");
    address nonVoter1 = makeAddr("nonVoter1");
    address PeaceAdmin = makeAddr("Peaceadmin");
    address [] registerVotersArray;
    WorldWarIV.Candidate [] _candidates;
    string [] CandidatesNames;
    WorldWarIVMitigationFactory factory;
    bytes32 _id;
    IWorldWar4_MitigationFactory worldwar;

    
    function setUp() public {
        factory = new WorldWarIVMitigationFactory(PeaceAdmin);
        worldwar = factory.deployPeace(admin, 3 hours, 1 days);
        //worldwar = new WorldWarIV(admin, 3 hours, 1 days,factory, _id);
        generatevotersArray();
        vm.prank(admin);
        registerVoters();
        vm.prank(admin);
        registerCandidates();
    }
    function registerVoters() private {
        //worldwar.RegisterCandidates()
        worldwar.RegisterVoters(registerVotersArray);
    }

    function registerCandidates() public {
        CandidatesNames.push ("Abraham Lincoln");
        CandidatesNames.push ("Mark Zuckerberg");
        CandidatesNames.push ("Elon Musk");
        CandidatesNames.push ("Apple CEO");
        CandidatesNames.push ("Kodak Rome");
        worldwar.RegisterCandidates(CandidatesNames);
    }
    function generatevotersArray() private {
        registerVotersArray.push(voter1);
        registerVotersArray.push(voter2);
        registerVotersArray.push(voter3);
        registerVotersArray.push(voter4);    
        registerVotersArray.push(voter5);
    }
    //==========================Tests================================

    function testVotersRegistered() public {
        vm.startPrank(voter2);
        bool registered = worldwar.isRegisteredVoter(voter2);
        vm.stopPrank();
        assertTrue(registered);
        
    }
    // function testAll() public {

    // }

    function testVoting() public {
        vm.warp(block.timestamp + 3 hours);
        vm.prank(voter2);
        worldwar.vote(0);
        vm.warp(block.timestamp + 1 days);
        vm.prank(admin);
        (bool a,) = worldwar.voteSortingAlgorithm();
        bool truth = worldwar.votingEndedWithAWinner();
        assertTrue( truth);
    }

    function testrevertOnDoubleVoteAttempt()public {
        // vm.prank(voter2);
        // worldwar.vote(0);
        // vm.prank(admin);
        // worldwar.voteSortingAlgorithm();
        // bool truth = worldwar.votingEndedWithAWinner;
        // assertTrue( truth);
    }

    ///////////////////////////////////
    //        Expected Reverts      //
    /////////////////////////////////

    ///////////////////////////////////
    //        Expected Reverts      //
    /////////////////////////////////

}