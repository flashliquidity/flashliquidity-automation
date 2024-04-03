// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IAutomationRegistryConsumer} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/IAutomationRegistryConsumer.sol";
import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {IAutomationForwarder} from "@chainlink/contracts/src/v0.8/automation/interfaces/IAutomationForwarder.sol";
import {MigratableKeeperRegistryInterfaceV2} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/MigratableKeeperRegistryInterfaceV2.sol";
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
    error AutomationStation__NotFromForwarder();

    /// @notice Represents the configuration settings for refueling upkeeps in the Automation Station.
    /// @dev This struct holds settings that determine the behavior of the refueling process for upkeeps.
    struct RefuelConfig {
        uint96 refuelAmount; // The amount of LINK tokens to refuel an upkeep.
        uint96 stationUpkeepMinBalance; // The minimum balance threshold for the station's upkeep.
        uint32 minDelayNextRefuel; // The minimum delay time (in seconds) required between successive refuels. (station upkeep excluded)
    }

    /// @dev Reference to the LinkTokenInterface, used for LINK token interactions.
    LinkTokenInterface public immutable i_linkToken;
    /// @dev Refueling configuration for upkeeps.
    RefuelConfig private s_refuelConfig;
    /// @dev Automation forwarder for the station upkeep.
    IAutomationForwarder private s_forwarder;
    /// @dev Automation registrar address
    address private s_registrar;
    /// @dev Function selector of the registrar registerUpkeep function.
    bytes4 private s_registerUpkeepSelector;
    /// @dev An array of upkeep IDs managed by this station, allowing tracking and management of multiple upkeeps.
    uint256[] private s_upkeepIDs;
    /// @dev Unique identifier for this station's upkeep registered in the Chainlink Automation Network.
    uint256 private s_stationUpkeepID;
    /// @dev Mapping from upkeep ID to last refuel timestamp.
    mapping(uint256 upkeepID => uint256 lastRefuelTimestamp) private s_lastRefuelTimestamp;

    event UpkeepRegistered(uint256 upkeepID);
    event UpkeepRemoved(uint256 upkeepID);
    event UpkeepsMigrated(address indexed oldRegistry, address indexed newRegistry, uint256[] upkeepIDs);
    event StationDismantled(uint256 stationUpkeepID);
    event RegistrarChanged(address newRegistrar);
    event ForwarderChanged(address newForwarder);

    constructor(
        address governor,
        address linkToken,
        address registrar,
        bytes4 registerUpkeepSelector,
        uint96 refuelAmount,
        uint96 stationUpkeepMinBalance,
        uint32 minDelayNextRefuel
    ) Governable(governor) {
        i_linkToken = LinkTokenInterface(linkToken);
        s_registerUpkeepSelector = registerUpkeepSelector;
        s_registrar = registrar;
        s_refuelConfig = RefuelConfig({
            refuelAmount: refuelAmount,
            stationUpkeepMinBalance: stationUpkeepMinBalance,
            minDelayNextRefuel: minDelayNextRefuel
        });
    }

    /// @inheritdoc IAutomationStation
    function initialize(uint256 approveAmountLINK, bytes calldata registrationParams) external onlyGovernor {
        if (s_stationUpkeepID > 0) revert AutomationStation__AlreadyInitialized();
        s_stationUpkeepID = _registerUpkeep(approveAmountLINK, registrationParams);
    }

    /// @inheritdoc IAutomationStation
    function dismantle() external onlyGovernor {
        uint256 stationUpkeepID = s_stationUpkeepID;
        if (stationUpkeepID == 0 || s_upkeepIDs.length > 0) revert AutomationStation__CannotDismantle();
        s_stationUpkeepID = 0;
        _getStationUpkeepRegistry().cancelUpkeep(stationUpkeepID);
        emit StationDismantled(stationUpkeepID);
    }

    /// @inheritdoc IAutomationStation
    function setForwarder(address forwarder) external onlyGovernor {
        s_forwarder = IAutomationForwarder(forwarder);
        emit ForwarderChanged(forwarder);
    }

    /// @inheritdoc IAutomationStation
    function setRegistrar(address registrar) external onlyGovernor {
        s_registrar = registrar;
        emit RegistrarChanged(registrar);
    }

    /// @inheritdoc IAutomationStation
    function setRegisterUpkeepSelector(bytes4 registerUpkeepSelector) external onlyGovernor {
        s_registerUpkeepSelector = registerUpkeepSelector;
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
    function forceStationRefuel(uint96 refuelAmount) external onlyGovernor {
        _getStationUpkeepRegistry().addFunds(s_stationUpkeepID, refuelAmount);
    }

    /// @inheritdoc IAutomationStation
    function createUpkeep(uint256 approveAmountLINK, bytes calldata registrationParams) external onlyGovernor {
        uint256 upkeepID = _registerUpkeep(approveAmountLINK, registrationParams);
        if (upkeepID > 0) {
            s_upkeepIDs.push(upkeepID);
            emit UpkeepRegistered(upkeepID);
        }
    }

    /// @inheritdoc IAutomationStation
    function addUpkeeps(uint256[] calldata upkeepIDs) external onlyGovernor {
        uint256 upkeepsLen = upkeepIDs.length;
        uint256 upkeepID;
        for (uint256 i; i < upkeepsLen;) {
            upkeepID = upkeepIDs[i];
            s_upkeepIDs.push(upkeepID);
            emit UpkeepRegistered(upkeepID);
        }
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
        _getStationUpkeepRegistry().cancelUpkeep(upkeepID);
        emit UpkeepRemoved(upkeepID);
    }

    /// @inheritdoc IAutomationStation
    function pauseUpkeeps(uint256[] calldata upkeepIDs) external onlyGovernor {
        uint256 upkeepsLen = upkeepIDs.length;
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        for (uint256 i; i < upkeepsLen;) {
            registry.pauseUpkeep(upkeepIDs[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function unpauseUpkeeps(uint256[] calldata upkeepIDs) external onlyGovernor {
        uint256 upkeepsLen = upkeepIDs.length;
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        for (uint256 i; i < upkeepsLen;) {
            registry.unpauseUpkeep(upkeepIDs[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function withdrawUpkeeps(uint256[] calldata upkeepIDs) external {
        uint256 upkeepsLen = upkeepIDs.length;
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        for (uint256 i; i < upkeepsLen;) {
            registry.withdrawFunds(upkeepIDs[i], address(this));
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function migrateUpkeeps(address oldRegistry, address newRegistry, uint256[] calldata upkeepIDs)
        external
        onlyGovernor
    {
        MigratableKeeperRegistryInterfaceV2(oldRegistry).migrateUpkeeps(upkeepIDs, newRegistry);
        emit UpkeepsMigrated(oldRegistry, newRegistry, upkeepIDs);
    }

    /// @inheritdoc AutomationCompatibleInterface
    function performUpkeep(bytes calldata performData) external {
        IAutomationForwarder forwarder = s_forwarder;
        if (msg.sender != address(forwarder)) revert AutomationStation__NotFromForwarder();
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        uint256 upkeepIndex = abi.decode(performData, (uint256));
        uint256 stationUpkeepID = s_stationUpkeepID;
        uint256 upkeepID;
        uint256 minBalance;
        RefuelConfig memory config = s_refuelConfig;
        if (upkeepIndex == type(uint256).max) {
            upkeepID = s_stationUpkeepID;
            minBalance = config.stationUpkeepMinBalance;
        } else {
            upkeepID = s_upkeepIDs[upkeepIndex];
            minBalance = registry.getMinBalance(upkeepID);
        }
        if (registry.getBalance(upkeepID) > minBalance) revert AutomationStation__RefuelNotNeeded();
        if (block.timestamp - s_lastRefuelTimestamp[upkeepID] < config.minDelayNextRefuel) {
            revert AutomationStation__TooEarlyForNextRefuel();
        }
        if (stationUpkeepID != upkeepID) s_lastRefuelTimestamp[upkeepID] = block.timestamp;
        i_linkToken.approve(address(registry), config.refuelAmount);
        registry.addFunds(upkeepID, config.refuelAmount);
    }

    /**
     * @dev Internal function to register a new upkeep.
     * @param approveAmountLINK Amount of LINK tokens approved to the registrar.
     * @param registrationParams Encoded registration params.
     * @return upkeepID The ID assigned to the newly registered upkeep.
     * @notice This function reverts with `AutomationStation__UpkeepRegistrationFailed` if the registration returns a zero ID.
     */
    function _registerUpkeep(uint256 approveAmountLINK, bytes calldata registrationParams)
        internal
        returns (uint256 upkeepID)
    {
        address registrar = s_registrar;
        i_linkToken.approve(registrar, approveAmountLINK);
        (bool success, bytes memory returnData) =
            registrar.call(bytes.concat(s_registerUpkeepSelector, registrationParams));
        if (!success) revert AutomationStation__UpkeepRegistrationFailed();
        return abi.decode(returnData, (uint256));
    }

    function _getStationUpkeepRegistry() internal view returns (IAutomationRegistryConsumer registry) {
        return s_forwarder.getRegistry();
    }

    /// @inheritdoc AutomationCompatibleInterface
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        uint256 upkeepsLen = s_upkeepIDs.length;
        uint256 upkeepID;
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        if (registry.getBalance(s_stationUpkeepID) <= s_refuelConfig.stationUpkeepMinBalance) {
            return (true, abi.encode(type(uint256).max));
        }
        for (uint256 i; i < upkeepsLen;) {
            upkeepID = s_upkeepIDs[i];
            if (registry.getBalance(upkeepID) <= registry.getMinBalance(upkeepID)) {
                return (true, abi.encode(i));
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function getStationUpkeepRegistry() external view returns (address) {
        return address(_getStationUpkeepRegistry());
    }

    /// @inheritdoc IAutomationStation
    function getStationUpkeepID() external view returns (uint256) {
        return s_stationUpkeepID;
    }

    /// @inheritdoc IAutomationStation
    function getForwarder() external view returns (address) {
        return address(s_forwarder);
    }

    /// @inheritdoc IAutomationStation
    function getRegistrar() external view returns (address) {
        return s_registrar;
    }

    /// @inheritdoc IAutomationStation
    function getRegisterUpkeepSelector() external view returns (bytes4) {
        return s_registerUpkeepSelector;
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
