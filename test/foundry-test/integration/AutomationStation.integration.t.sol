// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AutomationStation} from "../../../contracts/AutomationStation.sol";
import {Governable} from "flashliquidity-acs/contracts/Governable.sol";

contract AutomationStationIntegrationTest is Test {
    AutomationStation station;
    address registry = address(0x08a8eea76D2395807Ce7D1FC942382515469cCA1);
    address registrar = address(0x0Bc5EDC7219D272d9dEDd919CE2b4726129AC02B);
    address linkToken = address(0xb0897686c545045aFc77CF20eC7A532E3120E0F1);
    address governor = address(0x95E05C9870718cb171C04080FDd186571475027E);
    address verifierProxy = address(0x478Aa2aC9F6D65F84e09D9185d126c3a17c2a93C);
    address bob = makeAddr("bob");
    uint32 priceMaxStaleness = 86400;
    uint256 polygonFork;

    function setUp() public {
        polygonFork = vm.createSelectFork("https://rpc.ankr.com/polygon");
        station = new AutomationStation(governor, linkToken, registry, registrar);
        vm.prank(registry);
        IERC20(linkToken).transfer(governor, 100 ether);
    }

    function testIntegration__AutomationStation_initialize() public {
        vm.startPrank(governor);
        IERC20(linkToken).transfer(address(station), 5 ether);
        station.initialize(5 ether);
        vm.stopPrank();
        assertNotEq(station.getStationUpkeepID(), 0);
    }

    function testIntegration__AutomationStation_addUpkeep() public {
        vm.startPrank(governor);
        IERC20(linkToken).transfer(address(station), 5 ether);
        station.addUpkeep(address(this), 5 ether, 500000, 0, "test", new bytes(0), new bytes(0), new bytes(0));
        vm.stopPrank();
        assertEq(station.allUpkeepsLength(), 1);
        assertNotEq(station.getUpkeepIdAtIndex(0), 0);
    }

    function testIntegration__AutomationStation_cancelAndWithdrawUpkeep() public {
        vm.startPrank(governor);
        IERC20(linkToken).transfer(address(station), 5 ether);
        station.addUpkeep(address(this), 5 ether, 500000, 0, "test", new bytes(0), new bytes(0), new bytes(0));
        uint256[] memory upkeepIDs = new uint256[](1);
        upkeepIDs[0] = station.getUpkeepIdAtIndex(0);
        station.removeUpkeep(0);
        vm.stopPrank();
        vm.roll(block.number + 50);
        station.withdrawUpkeeps(upkeepIDs);
        assertEq(station.allUpkeepsLength(), 0);
        assertEq(IERC20(linkToken).balanceOf(address(station)), 4900000000000000000);
    }

    function testIntegration__AutomationStation_checkUpkeep() public {
        vm.startPrank(governor);
        IERC20(linkToken).transfer(address(station), 6 ether);
        station.initialize(5 ether);
        station.addUpkeep(address(this), 1 ether, 5000000, 0, "test", new bytes(0), new bytes(0), new bytes(0));
        (bool upkeepNeeded, bytes memory performData) = station.checkUpkeep(new bytes(0));
        (uint256 upkeepIndex) = abi.decode(performData, (uint256));
        assertEq(upkeepIndex, 0);
        station.setStationUpkeepMinBalance(6 ether);
        (upkeepNeeded, performData) = station.checkUpkeep(new bytes(0));
        (upkeepIndex) = abi.decode(performData, (uint256));
        assertEq(upkeepIndex, type(uint256).max);
        vm.stopPrank();
    }
}