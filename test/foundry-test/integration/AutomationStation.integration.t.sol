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
    uint96 refuelAmount = 2 ether;
    uint96 stationUpkeepMinBalance = 1 ether;
    uint32 minDelayNextRefuel = 6 hours;
    bytes4 registerUpkeepSelector = 0x3f678e11;
    bytes registrationParams;

    struct RegistrationParams {
        string name;
        bytes encryptedEmail;
        address upkeepContract;
        uint32 gasLimit;
        address adminAddress;
        uint8 triggerType;
        bytes checkData;
        bytes triggerConfig;
        bytes offchainConfig;
        uint96 amount;
    }

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/polygon");
        station = new AutomationStation(
            governor,
            address(linkToken),
            registrar,
            registerUpkeepSelector,
            refuelAmount,
            stationUpkeepMinBalance,
            minDelayNextRefuel
        );
        registrationParams = abi.encode(
            RegistrationParams({
                name: "test",
                encryptedEmail: new bytes(0),
                upkeepContract: address(station),
                gasLimit: 500000,
                adminAddress: address(station),
                triggerType: 0,
                checkData: new bytes(0),
                triggerConfig: new bytes(0),
                offchainConfig: new bytes(0),
                amount: 5 ether
            })
        );
        vm.prank(registry);
        IERC20(linkToken).transfer(governor, 100 ether);
        vm.startPrank(governor);
        IERC20(linkToken).transfer(address(station), 5 ether);
        station.initialize(5 ether, registrationParams);
        (bool success, bytes memory returnData) =
            registry.staticcall(abi.encodeWithSignature("getForwarder(uint256)", station.getStationUpkeepID()));
        if (!success) revert();
        station.setForwarder(abi.decode(returnData, (address)));
        vm.stopPrank();
        assertNotEq(station.getStationUpkeepID(), 0);
    }

    function testIntegration__AutomationStation_addUpkeep() public {
        vm.startPrank(governor);
        IERC20(linkToken).transfer(address(station), 5 ether);
        station.createUpkeep(5 ether, registrationParams);
        vm.stopPrank();
        assertEq(station.allUpkeepsLength(), 1);
        assertNotEq(station.getUpkeepIdAtIndex(0), 0);
    }

    function testIntegration__AutomationStation_cancelAndWithdrawUpkeep() public {
        vm.startPrank(governor);
        IERC20(linkToken).transfer(address(station), 5 ether);
        station.createUpkeep(5 ether, registrationParams);
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
        IERC20(linkToken).transfer(address(station), 8 ether);
        station.createUpkeep(5 ether, registrationParams);
        (bool upkeepNeeded, bytes memory performData) = station.checkUpkeep(new bytes(0));
        assertFalse(upkeepNeeded);
        station.setRefuelConfig(2 ether, 6 ether, 6 hours);
        (upkeepNeeded, performData) = station.checkUpkeep(new bytes(0));
        uint256 upkeepIndex = abi.decode(performData, (uint256));
        assertTrue(upkeepNeeded);
        assertEq(upkeepIndex, type(uint256).max);
        vm.stopPrank();
    }
}
