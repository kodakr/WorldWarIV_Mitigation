// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "forge-std/console.sol";
// import {WorldWarIV_Mitigation, WorldWarIVMitigationFactory} from "../src/WorldWar4.sol";
// import {IWorldWar4_MitigationFactory, IWorldWar4_Mitigation} from "../src/interface/IWorldWarIV_MitigationFactory.sol";
// //import {IWorldWar4_Mitigation} from "../src/interface/IWorldWar4_Mitigation.sol";
// import {MitigationScript} from "../script/Counter.s.sol";

// contract CounterTest is Test {
//     //WorldWarIV worldwar;
//     address PeaceAdmin = makeAddr("Peaceadmin");
//     address admin = makeAddr("admin");
//     address hacker = makeAddr("hacker");
//     address voter1 = makeAddr("voter1");
//     address voter2 = makeAddr("voter2");
//     address voter3 = makeAddr("voter3");
//     address voter4 = makeAddr("voter4");
//     address voter5 = makeAddr("voter5");
//     address nonVoter1 = makeAddr("nonVoter1");
//     address[] registerVotersArray;
//     address Router;
//     WorldWarIV_Mitigation.Candidate[] _candidates;
//     string[] CandidatesNames;
//     WorldWarIVMitigationFactory factory;
//     bytes32 _id;
//     IWorldWar4_Mitigation worldwar;
//     MitigationScript script;

//     function setUp() public {
//         script = new MitigationScript();
//         address payable Factory = script.run();
//         factory = WorldWarIVMitigationFactory(Factory);
//         worldwar = factory.deployPeace(admin, 3 hours, 1 days,Router);
//         //worldwar = new WorldWarIV(admin, 3 hours, 1 days,factory, _id);
//         generatevotersArray();
//         vm.prank(admin);
//         registerVoters();
//         vm.startPrank(admin);
//         registerCandidates();
//         vm.stopPrank();
//     }

//     function registerVoters() private {
//         worldwar.RegisterVoters(registerVotersArray);
//     }

//     function registerCandidates() private {
//         CandidatesNames.push("Abraham Lincoln");
//         CandidatesNames.push("Mark Zuckerberg");
//         CandidatesNames.push("Elon Musk");
//         CandidatesNames.push("Apple CEO");
//         CandidatesNames.push("Kodak Rome");
//         worldwar.RegisterCandidates(CandidatesNames);
//     }

//     function generatevotersArray() private {
//         registerVotersArray.push(voter1);
//         registerVotersArray.push(voter2);
//         registerVotersArray.push(voter3);
//         registerVotersArray.push(voter4);
//         registerVotersArray.push(voter5);
//     }
//     //==========================Tests================================

//     function testVotersRegistered() public {
//         vm.startPrank(voter2);
//         bool registered = worldwar.isRegisteredVoter(voter2);
//         vm.stopPrank();
//         assertTrue(registered);
//     }
//     // function testAll() public {

//     // }

//     function testVoting() public {
//         vm.warp(block.timestamp + 3 hours);
//         vm.prank(voter2);
//         worldwar.vote(0);
//         vm.warp(block.timestamp + 1 days);
//         vm.prank(admin);
//         (bool a,) = worldwar.voteSortingAlgorithm();
//         bool truth = worldwar.votingEndedWithAWinner();
//         IWorldWar4_Mitigation.Candidate memory _winner = worldwar.revealWinner();
//         string memory bb = _winner.Name;
//         console.log("kkkkkkk++", _winner.Name);
//         assertEq0(bytes(bb), bytes("Abraham Lincoln"));
//         assertTrue(truth);
//         assertTrue(a);
//     }
//     // function testConstructor() public {

//     // }
//     // function testViewFunctions() public {
//     //     worldwar.getMaxIndexForCandidates();
//     // }

//     ///////////////////////////////////
//     //        Expected Reverts      //
//     /////////////////////////////////
//     function testrevertOnDoubleVoteAttempt() public {
//         vm.warp(block.timestamp + 3 hours);
//         vm.prank(voter2);
//         worldwar.vote(0);
//         vm.warp(block.timestamp + 2 hours);
//         //attempt second voting
//         vm.expectRevert(WorldWarIV_Mitigation.NotARegisteredVoter.selector);
//         vm.prank(voter2);
//         worldwar.vote(0);
//     }

//     ///////////////////////////////////
//     //        Expected Reverts      //
//     /////////////////////////////////
// }
