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
        station = new AutomationStation(governor, address(linkToken), registry, registrar);
    }

    function test__AutomationStation_initializeOnlyGovernor() public {
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
        station.initialize(5 ether);
    }

    function test__AutomationStation_dismantleOnlyGovernor() public {
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
        station.dismantle();
    }

    function test__AutomationStation_setRefuelAmount() public {
        uint96 newRefuelAmount = 4 ether;
        assertNotEq(station.getRefuelAmount(), newRefuelAmount);
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
        station.setRefuelAmount(newRefuelAmount);
        vm.prank(governor);
        station.setRefuelAmount(newRefuelAmount);
        assertEq(station.getRefuelAmount(), newRefuelAmount);
    }

    function test__AutomationStation_setStationUpkeepMinBalance() public {
        uint96 newMinUpkeepBalance = 4 ether;
        assertNotEq(station.getStationUpkeepMinBalance(), newMinUpkeepBalance);
        vm.expectRevert(Governable.Governable__NotAuthorized.selector);
        station.setStationUpkeepMinBalance(newMinUpkeepBalance);
        vm.prank(governor);
        station.setStationUpkeepMinBalance(newMinUpkeepBalance);
        assertEq(station.getStationUpkeepMinBalance(), newMinUpkeepBalance);
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
