// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IAutomationRegistryConsumer} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/IAutomationRegistryConsumer.sol";
import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {AutomationRegistrarInterface} from "./interfaces/AutomationRegistrarInterface.sol";
import {Governable} from "flashliquidity-acs/contracts/Governable.sol";
import {IAutomationStation} from "./interfaces/IAutomationStation.sol";

/**
 * @title AutomationStation
 * @author Oddcod3 (@oddcod3)
 * @notice This contract is used for managing upkeeps in the Chainlink Automation Network.
 */
contract AutomationStation is IAutomationStation, AutomationCompatibleInterface, Governable {
    using SafeERC20 for IERC20;

    error AutomationStation__AlreadyInitialized();
    error AutomationStation__NoRegisteredUpkeep();
    error AutomationStation__InconsistentParamsLength();
    error AutomationStation__RefuelNotNeeded();
    error AutomationStation__CannotDismantle();
    error AutomationStation__UpkeepRegistrationFailed();
    error AutomationStation__TooEarlyForNextRefuel();

    /// @notice Represents the configuration settings for refueling upkeeps in the Automation Station.
    /// @dev This struct holds settings that determine the behavior of the refueling process for upkeeps.
    struct RefuelConfig {
        uint96 refuelAmount; // The amount of LINK tokens to refuel an upkeep.
        uint96 stationUpkeepMinBalance; // The minimum balance threshold for the station's upkeep.
        uint32 minDelayNextRefuel; // The minimum delay time (in seconds) required between successive refuels. (station upkeep excluded)
    }

    /// @dev Reference to the LinkTokenInterface, used for LINK token interactions.
    LinkTokenInterface public immutable i_linkToken;
    /// @dev Reference to the IAutomationRegistryConsumer, providing functionalities to interact with the Chainlink Automation Registry.
    IAutomationRegistryConsumer public immutable i_registry;
    /// @dev Reference to the AutomationRegistrarInterface, used for registering, managing, and querying upkeeps.
    AutomationRegistrarInterface public immutable i_registrar;
    /// @dev Refueling configuration for upkeeps.
    RefuelConfig private s_refuelConfig;
    /// @dev An array of upkeep IDs managed by this station, allowing tracking and management of multiple upkeeps.
    uint256[] private s_upkeepIDs;
    /// @dev Unique identifier for this station's upkeep registered in the Chainlink Automation Network.
    uint256 private s_stationUpkeepId;
    /// @dev Mapping from upkeep ID to last refuel timestamp.
    mapping(uint256 upkeepID => uint256 lastRefuelTimestamp) private s_lastRefuelTimestamp;

    event UpkeepRegistered(uint256 upkeepID);
    event UpkeepRemoved(uint256 upkeepID);
    event StationDismantled(uint256 stationUpkeepID);

    constructor(
        address governor,
        address linkToken,
        address registry,
        address registrar,
        uint96 refuelAmount,
        uint96 stationUpkeepMinBalance,
        uint32 minDelayNextRefuel
    ) Governable(governor) {
        i_linkToken = LinkTokenInterface(linkToken);
        i_registry = IAutomationRegistryConsumer(registry);
        i_registrar = AutomationRegistrarInterface(registrar);
        s_refuelConfig = RefuelConfig({
            refuelAmount: refuelAmount,
            stationUpkeepMinBalance: stationUpkeepMinBalance,
            minDelayNextRefuel: minDelayNextRefuel
        });
    }

    /// @inheritdoc IAutomationStation
    function initialize(uint96 initializationAmount) external onlyGovernor {
        if (s_stationUpkeepId > 0) revert AutomationStation__AlreadyInitialized();
        AutomationRegistrarInterface.RegistrationParams memory params = AutomationRegistrarInterface.RegistrationParams({
            name: "AutomationStation",
            encryptedEmail: new bytes(0),
            upkeepContract: address(this),
            gasLimit: 500000,
            adminAddress: address(this),
            triggerType: 0,
            checkData: new bytes(0),
            triggerConfig: new bytes(0),
            offchainConfig: new bytes(0),
            amount: initializationAmount
        });
        s_stationUpkeepId = _registerUpkeep(params);
    }

    /// @inheritdoc IAutomationStation
    function dismantle() external onlyGovernor {
        uint256 stationUpkeepID = s_stationUpkeepId;
        if (stationUpkeepID == 0 || s_upkeepIDs.length > 0) revert AutomationStation__CannotDismantle();
        i_registry.cancelUpkeep(stationUpkeepID);
        emit StationDismantled(stationUpkeepID);
    }

    /// @inheritdoc IAutomationStation
    function setRefuelConfig(uint96 refuelAmount, uint96 stationUpkeepMinBalance, uint32 minDelayNextReful)
        external
        onlyGovernor
    {
        s_refuelConfig = RefuelConfig({
            refuelAmount: refuelAmount,
            stationUpkeepMinBalance: stationUpkeepMinBalance,
            minDelayNextRefuel: minDelayNextReful
        });
    }

    /// @inheritdoc IAutomationStation
    function forceStationRefuel(uint96 refuelAmount) external onlyGovernor {
        i_registry.addFunds(s_stationUpkeepId, refuelAmount);
    }

    /// @inheritdoc IAutomationStation
    function addUpkeep(
        address upkeepContract,
        uint96 amount,
        uint32 gasLimit,
        uint8 triggerType,
        string memory name,
        bytes calldata checkData,
        bytes calldata triggerConfig,
        bytes calldata offchainConfig
    ) external onlyGovernor {
        AutomationRegistrarInterface.RegistrationParams memory params = AutomationRegistrarInterface.RegistrationParams({
            name: name,
            encryptedEmail: new bytes(0),
            upkeepContract: upkeepContract,
            gasLimit: gasLimit,
            adminAddress: address(this),
            triggerType: triggerType,
            checkData: checkData,
            triggerConfig: triggerConfig,
            offchainConfig: offchainConfig,
            amount: amount
        });
        s_upkeepIDs.push(_registerUpkeep(params));
    }

    /// @inheritdoc IAutomationStation
    function removeUpkeep(uint256 upkeepIndex) external onlyGovernor {
        uint256 upkeepsLen = s_upkeepIDs.length;
        if (upkeepsLen == 0) revert AutomationStation__NoRegisteredUpkeep();
        uint256 upkeepID = s_upkeepIDs[upkeepIndex];
        if (upkeepIndex < upkeepsLen - 1) {
            s_upkeepIDs[upkeepIndex] = s_upkeepIDs[upkeepsLen - 1];
        }
        s_upkeepIDs.pop();
        i_registry.cancelUpkeep(upkeepID);
        emit UpkeepRemoved(upkeepID);
    }

    /// @inheritdoc IAutomationStation
    function recoverERC20(address to, address[] memory tokens, uint256[] memory amounts) external onlyGovernor {
        uint256 tokensLen = tokens.length;
        if (tokensLen != amounts.length) revert AutomationStation__InconsistentParamsLength();
        for (uint256 i; i < tokensLen;) {
            IERC20(tokens[i]).safeTransfer(to, amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function withdrawUpkeeps(uint256[] calldata upkeepIDs) external {
        uint256 upkeepsLen = upkeepIDs.length;
        for (uint256 i; i < upkeepsLen;) {
            i_registry.withdrawFunds(upkeepIDs[i], address(this));
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc AutomationCompatibleInterface
    function performUpkeep(bytes calldata performData) external {
        uint256 upkeepIndex = abi.decode(performData, (uint256));
        uint256 upkeepID;
        uint256 minBalance;
        RefuelConfig memory config = s_refuelConfig;
        if (upkeepIndex == type(uint256).max) {
            upkeepID = s_stationUpkeepId;
            minBalance = config.stationUpkeepMinBalance;
        } else {
            upkeepID = s_upkeepIDs[upkeepIndex];
            minBalance = i_registry.getMinBalance(upkeepID);
        }
        if (i_registry.getBalance(upkeepID) > minBalance) revert AutomationStation__RefuelNotNeeded();
        if (block.timestamp - s_lastRefuelTimestamp[upkeepID] < config.minDelayNextRefuel) {
            revert AutomationStation__TooEarlyForNextRefuel();
        }
        s_lastRefuelTimestamp[upkeepID] = block.timestamp;
        i_linkToken.approve(address(i_registry), config.refuelAmount);
        i_registry.addFunds(s_upkeepIDs[upkeepIndex], config.refuelAmount);
    }

    /**
     * @dev Internal function to register a new upkeep.
     * @param params The `RegistrationParams` struct from the `AutomationRegistrarInterface` containing the details necessary for registering an upkeep.
     * @return upkeepID The ID assigned to the newly registered upkeep.
     * @notice This function reverts with `AutomationStation__UpkeepRegistrationFailed` if the registration returns a zero ID.
     */
    function _registerUpkeep(AutomationRegistrarInterface.RegistrationParams memory params)
        internal
        returns (uint256 upkeepID)
    {
        i_linkToken.approve(address(i_registrar), params.amount);
        upkeepID = i_registrar.registerUpkeep(params);
        if (upkeepID == 0) revert AutomationStation__UpkeepRegistrationFailed();
        emit UpkeepRegistered(upkeepID);
    }

    /// @inheritdoc AutomationCompatibleInterface
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        uint256 upkeepsLen = s_upkeepIDs.length;
        uint256 upkeepID;
        if (i_registry.getBalance(s_stationUpkeepId) <= s_refuelConfig.stationUpkeepMinBalance) {
            return (true, abi.encode(type(uint256).max));
        }
        for (uint256 i; i < upkeepsLen;) {
            upkeepID = s_upkeepIDs[i];
            if (i_registry.getBalance(upkeepID) <= i_registry.getMinBalance(upkeepID)) {
                return (true, abi.encode(i));
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function getStationUpkeepID() external view returns (uint256) {
        return s_stationUpkeepId;
    }

    /// @inheritdoc IAutomationStation
    function getUpkeepIdAtIndex(uint256 upkeepIndex) external view returns (uint256) {
        return s_upkeepIDs[upkeepIndex];
    }

    /// @inheritdoc IAutomationStation
    function allUpkeepsLength() external view returns (uint256) {
        return s_upkeepIDs.length;
    }

    /// @inheritdoc IAutomationStation
    function getRefuelConfig() external view returns (uint96, uint96, uint32) {
        RefuelConfig memory config = s_refuelConfig;
        return (config.refuelAmount, config.stationUpkeepMinBalance, config.minDelayNextRefuel);
    }
}
