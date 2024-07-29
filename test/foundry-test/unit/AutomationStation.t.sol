// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";
import {AutomationStation} from "../../../contracts/AutomationStation.sol";

contract AutomationStationTest is Test {
    AutomationStation station;
    ERC20Mock linkToken;
    address governor = makeAddr("governor");
    address bob = makeAddr("bob");
    address registry = makeAddr("registry");
    address registrar = makeAddr("registrar");
    bytes revertNotOwnerMsg = "Ownable: caller is not the owner";
    bytes4 registerUpkeepSelector = 0x3f678e11;

    function setUp() public {
        linkToken = new ERC20Mock("MockLINK", "LINK");
        linkToken.mintTo(governor, 100 ether);
        vm.prank(governor);
        station = new AutomationStation(
            address(linkToken), registrar, registerUpkeepSelector, 2 ether, 1 ether, 6 hours, type(uint256).max
        );
    }

    function test__AutomationStation_initializeOnlyGovernor() public {
        vm.expectRevert(revertNotOwnerMsg);
        station.initialize(registry, new bytes(0));
    }

    function test__AutomationStation_dismantleOnlyGovernor() public {
        vm.expectRevert(revertNotOwnerMsg);
        station.dismantle();
    }

    function test__AutomationStation_forceStationRefuelOnlyGovernor() public {
        vm.expectRevert(revertNotOwnerMsg);
        station.forceStationRefuel(5 ether);
    }

    function test__AutomationStation_forceUpkeepRefuelOnlyGovernor() public {
        vm.expectRevert(revertNotOwnerMsg);
        station.forceUpkeepRefuel(0, 5 ether);
    }

    function test__AutomationStation_setForwarder() public {
        assertNotEq(station.getForwarder(), bob);
        vm.expectRevert(revertNotOwnerMsg);
        station.setForwarder(bob);
        vm.prank(governor);
        station.setForwarder(bob);
        assertEq(station.getForwarder(), bob);
    }

    function test__AutomationStation_setRegistrar() public {
        assertNotEq(station.getRegistrar(), bob);
        vm.expectRevert(revertNotOwnerMsg);
        station.setRegistrar(bob);
        vm.prank(governor);
        station.setRegistrar(bob);
        assertEq(station.getRegistrar(), bob);
    }

    function test__AutomationStation_setRegisterUpkeepSelector() public {
        bytes4 funcSelector = 0x69696969;
        assertNotEq(station.getRegisterUpkeepSelector(), funcSelector);
        vm.expectRevert(revertNotOwnerMsg);
        station.setRegisterUpkeepSelector(funcSelector);
        vm.prank(governor);
        station.setRegisterUpkeepSelector(funcSelector);
        assertEq(station.getRegisterUpkeepSelector(), funcSelector);
    }

    function test__AutomationStation_setRefuelConfig() public {
        uint96 newRefuelAmount = 4 ether;
        uint96 newStationUpkeepMinBalance = 2 ether;
        uint32 newMinDelayNextRefuel = 4 hours;
        AutomationStation.RefuelConfig memory refuelConfig = station.getRefuelConfig();
        assertNotEq(refuelConfig.refuelAmount, newRefuelAmount);
        assertNotEq(refuelConfig.stationUpkeepMinBalance, newStationUpkeepMinBalance);
        assertNotEq(refuelConfig.minDelayNextRefuel, newMinDelayNextRefuel);
        vm.expectRevert(revertNotOwnerMsg);
        station.setRefuelConfig(newRefuelAmount, newStationUpkeepMinBalance, newMinDelayNextRefuel);
        vm.prank(governor);
        station.setRefuelConfig(newRefuelAmount, newStationUpkeepMinBalance, newMinDelayNextRefuel);
        refuelConfig = station.getRefuelConfig();
        assertEq(refuelConfig.refuelAmount, newRefuelAmount);
        assertEq(refuelConfig.stationUpkeepMinBalance, newStationUpkeepMinBalance);
        assertEq(refuelConfig.minDelayNextRefuel, newMinDelayNextRefuel);
    }

    function test__AutomationStation_registerUpkeepOnlyGovernor() public {
        vm.expectRevert(revertNotOwnerMsg);
        station.registerUpkeep(new bytes(0));
    }

    function test__AutomationStation_unregisterUpkeepOnlyGovernor() public {
        vm.expectRevert(revertNotOwnerMsg);
        station.unregisterUpkeep(0);
    }

    function test__AutomationStation_addUpkeeps() public {
        uint256[] memory upkeepIDs = new uint256[](1);
        upkeepIDs[0] = 69;
        assertEq(station.allUpkeepsLength(), 0);
        vm.expectRevert(revertNotOwnerMsg);
        station.addUpkeeps(upkeepIDs);
        vm.prank(governor);
        station.addUpkeeps(upkeepIDs);
        assertEq(station.allUpkeepsLength(), 1);
    }

    function test__AutomationStation_removeUpkeep() public {
        uint256[] memory upkeepIDs = new uint256[](1);
        upkeepIDs[0] = 69;
        vm.expectRevert(revertNotOwnerMsg);
        station.removeUpkeep(0);
        vm.startPrank(governor);
        vm.expectRevert(AutomationStation.AutomationStation__NoRegisteredUpkeep.selector);
        station.removeUpkeep(0);
        station.addUpkeeps(upkeepIDs);
        station.removeUpkeep(0);
        vm.stopPrank();
        assertEq(station.allUpkeepsLength(), 0);
    }

    function test__AutomationStation_recoverERC20() public {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = address(linkToken);
        amounts[0] = 1 ether;
        vm.expectRevert(revertNotOwnerMsg);
        station.recoverERC20(bob, tokens, amounts);
        vm.startPrank(governor);
        linkToken.transfer(address(station), 1 ether);
        assertTrue(linkToken.balanceOf(address(station)) == 1 ether);
        assertTrue(linkToken.balanceOf(bob) == 0);
        station.recoverERC20(bob, tokens, amounts);
        assertTrue(linkToken.balanceOf(address(station)) == 0);
        assertTrue(linkToken.balanceOf(bob) == 1 ether);
        vm.stopPrank();
    }
}
