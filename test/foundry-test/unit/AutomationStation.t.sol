// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";
import {AutomationStation} from "../../../contracts/AutomationStation.sol";
import {Governable} from "flashliquidity-acs/contracts/Governable.sol";

contract AutomationStationTest is Test {
    AutomationStation station;
    ERC20Mock linkToken;
    address governor = makeAddr("governor");
    address bob = makeAddr("bob");
    address registrar = makeAddr("registrar");
    address registry = makeAddr("registry");

    function setUp() public {
        linkToken = new ERC20Mock("MockLINK", "LINK");
        linkToken.mintTo(governor, 100 ether);
        station = new AutomationStation(governor, address(linkToken), registry, registrar, 2 ether, 1 ether, 6 hours);
    }

    function test__AutomationStation_initializeOnlyGovernor() public {
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
        station.initialize(5 ether);
    }

    function test__AutomationStation_dismantleOnlyGovernor() public {
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
        station.dismantle();
    }

    function test__AutomationStation_setRefuelConfig() public {
        uint96 newRefuelAmount = 4 ether;
        uint96 newStationUpkeepMinBalance = 2 ether;
        uint32 newMinDelayNextRefuel = 4 hours;
        (uint96 refuelAmount, uint96 stationUpkeepMinBalance, uint32 minDelayNextRefuel) = station.getRefuelConfig();
        assertNotEq(refuelAmount, newRefuelAmount);
        assertNotEq(stationUpkeepMinBalance, newStationUpkeepMinBalance);
        assertNotEq(minDelayNextRefuel, newMinDelayNextRefuel);
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
        station.setRefuelConfig(newRefuelAmount, newStationUpkeepMinBalance, newMinDelayNextRefuel);
        vm.prank(governor);
        station.setRefuelConfig(newRefuelAmount, newStationUpkeepMinBalance, newMinDelayNextRefuel);
        (refuelAmount, stationUpkeepMinBalance, minDelayNextRefuel) = station.getRefuelConfig();
        assertEq(refuelAmount, newRefuelAmount);
        assertEq(stationUpkeepMinBalance, newStationUpkeepMinBalance);
        assertEq(minDelayNextRefuel, newMinDelayNextRefuel);
    }

    function test__AutomationStation_addUpkeepOnlyGovernor() public {
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
        station.addUpkeep(bob, 5 ether, 500000, 0, "test", new bytes(0), new bytes(0), new bytes(0));
    }

    function test__AutomationStation_removeUpkeepOnlyGovernor() public {
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
        station.removeUpkeep(0);
    }

    function test__AutomationStation_recoverERC20() public {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = address(linkToken);
        amounts[0] = 1 ether;
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
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
