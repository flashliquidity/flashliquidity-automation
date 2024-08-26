// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IAutomationRegistryConsumer} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/IAutomationRegistryConsumer.sol";
import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {IAutomationForwarder} from "@chainlink/contracts/src/v0.8/automation/interfaces/IAutomationForwarder.sol";
import {MigratableKeeperRegistryInterfaceV2} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/MigratableKeeperRegistryInterfaceV2.sol";
import {IAutomationStation} from "./interfaces/IAutomationStation.sol";

/**
 * @title AutomationStation
 * @author Oddcod3 (@oddcod3)
 * @notice This contract provides a single entry point for managing multiple upkeeps in the Chainlink Automation Network.
 * @notice It supports programmatic registration, unregistration, pausing/unpausing and migration of upkeeps.
 * @notice Additionally, it enables automated funding to ensure all managed upkeeps maintain the required minimum balance for continued operation.
 */
contract AutomationStation is IAutomationStation, AutomationCompatibleInterface, Ownable2Step {
    using SafeERC20 for IERC20;

    error AutomationStation__AlreadyInitialized();
    error AutomationStation__NoRegisteredUpkeep();
    error AutomationStation__InconsistentParamsLength();
    error AutomationStation__RefuelNotNeeded();
    error AutomationStation__CannotDismantle();
    error AutomationStation__UpkeepRegistrationFailed();
    error AutomationStation__TooEarlyForNextRefuel();
    error AutomationStation__NotFromForwarder();

    uint256 internal constant MAX_UINT256 = type(uint256).max;
    /// @dev Reference to the LinkTokenInterface, used for LINK token interactions.
    LinkTokenInterface public immutable i_linkToken;
    /// @dev Refueling configuration for upkeeps.
    RefuelConfig private s_refuelConfig;
    /// @dev Chainlink Automation forwarder of the station upkeep.
    IAutomationForwarder private s_forwarder;
    /// @dev Chainlink Automation Registrar address.
    address private s_registrar;
    /// @dev Chainlink Automation Registrar registerUpkeep function selector.
    bytes4 private s_registerUpkeepSelector;
    /// @dev Array of upkeep IDs managed by this station.
    uint256[] private s_upkeepIDs;
    /// @dev ID of the station upkeep.
    uint256 private s_stationUpkeepID;
    /// @dev Mapping from upkeep ID to last refuel timestamp.
    mapping(uint256 upkeepID => uint256 lastRefuelTimestamp) private s_lastRefuelTimestamp;

    event UpkeepRegistered(uint256 upkeepID);
    event UpkeepUnregistered(uint256 upkeepID);
    event UpkeepsAdded(uint256[] upkeepIDs);
    event UpkeepRemoved(uint256 upkeepID);
    event UpkeepsMigrated(address indexed oldRegistry, address indexed newRegistry, uint256[] upkeepIDs);
    event StationDismantled(uint256 stationUpkeepID);
    event RegistrarChanged(address newRegistrar);
    event ForwarderChanged(address newForwarder);

    constructor(
        address linkToken,
        address registrar,
        bytes4 registerUpkeepSelector,
        uint96 refuelAmount,
        uint96 stationUpkeepMinBalance,
        uint32 minDelayNextRefuel,
        uint256 approveLinkAmount
    ) Ownable2Step() {
        i_linkToken = LinkTokenInterface(linkToken);
        s_registerUpkeepSelector = registerUpkeepSelector;
        s_registrar = registrar;
        s_refuelConfig = RefuelConfig({
            refuelAmount: refuelAmount,
            stationUpkeepMinBalance: stationUpkeepMinBalance,
            minDelayNextRefuel: minDelayNextRefuel
        });
        if (approveLinkAmount > 0) i_linkToken.approve(registrar, approveLinkAmount);
    }

    /// @inheritdoc IAutomationStation
    function initialize(address registry, bytes calldata registrationParams) external onlyOwner returns (uint256 stationUpkeepID) {
        if (s_stationUpkeepID > 0) revert AutomationStation__AlreadyInitialized();
        stationUpkeepID = _registerUpkeep(registrationParams);
        if(stationUpkeepID == 0) return stationUpkeepID;
        s_stationUpkeepID = stationUpkeepID;
        if(registry != address(0)) {
            (bool success, bytes memory returnData) =
                registry.staticcall(abi.encodeWithSignature("getForwarder(uint256)", stationUpkeepID));
            if (success) {
                address forwarder = abi.decode(returnData, (address));
                s_forwarder = IAutomationForwarder(forwarder);
                emit ForwarderChanged(forwarder);
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function dismantle() external onlyOwner {
        uint256 stationUpkeepID = s_stationUpkeepID;
        if (stationUpkeepID == 0 || s_upkeepIDs.length > 0) revert AutomationStation__CannotDismantle();
        s_stationUpkeepID = 0;
        _getStationUpkeepRegistry().cancelUpkeep(stationUpkeepID);
        emit StationDismantled(stationUpkeepID);
    }

    /// @inheritdoc IAutomationStation
    function setForwarder(address forwarder) external onlyOwner {
        s_forwarder = IAutomationForwarder(forwarder);
        emit ForwarderChanged(forwarder);
    }

    /// @inheritdoc IAutomationStation
    function setRegistrar(address registrar) external onlyOwner {
        s_registrar = registrar;
        emit RegistrarChanged(registrar);
    }

    /// @inheritdoc IAutomationStation
    function setRegisterUpkeepSelector(bytes4 registerUpkeepSelector) external onlyOwner {
        s_registerUpkeepSelector = registerUpkeepSelector;
    }
    
    /// @inheritdoc IAutomationStation
    function setStationUpkeepID(uint256 stationUpkeepID) external onlyOwner {
        s_stationUpkeepID = stationUpkeepID;
    }

    /// @inheritdoc IAutomationStation
    function setRefuelConfig(uint96 refuelAmount, uint96 stationUpkeepMinBalance, uint32 minDelayNextReful)
        external
        onlyOwner
    {
        s_refuelConfig = RefuelConfig({
            refuelAmount: refuelAmount,
            stationUpkeepMinBalance: stationUpkeepMinBalance,
            minDelayNextRefuel: minDelayNextReful
        });
    }

    /// @inheritdoc IAutomationStation
    function approveLinkToRegistrar(uint256 amount) external onlyOwner {
        i_linkToken.approve(s_registrar, amount);
    }

    /// @inheritdoc IAutomationStation
    function recoverERC20(address to, address[] memory tokens, uint256[] memory amounts) external onlyOwner {
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
    function forceStationRefuel(uint96 refuelAmount) external onlyOwner {
        _getStationUpkeepRegistry().addFunds(s_stationUpkeepID, refuelAmount);
    }

    /// @inheritdoc IAutomationStation
    function forceUpkeepRefuel(uint256 upkeepID, uint96 refuelAmount) external onlyOwner {
        _getStationUpkeepRegistry().addFunds(upkeepID, refuelAmount);
    }

    /// @inheritdoc IAutomationStation
    function registerUpkeep(bytes calldata registrationParams) external onlyOwner returns (uint256 upkeepID) {
        upkeepID = _registerUpkeep(registrationParams);
        if (upkeepID > 0) {
            s_upkeepIDs.push(upkeepID);
            emit UpkeepRegistered(upkeepID);
        }
    }

    /// @inheritdoc IAutomationStation
    function unregisterUpkeep(uint256 upkeepIndex) external onlyOwner {
        uint256 upkeepID = _removeUpkeep(upkeepIndex);
        _getStationUpkeepRegistry().cancelUpkeep(upkeepID);
        emit UpkeepUnregistered(upkeepID);
    }

    /// @inheritdoc IAutomationStation
    function addUpkeeps(uint256[] calldata upkeepIDs) external onlyOwner {
        uint256 upkeepsLen = upkeepIDs.length;
        uint256 upkeepID;
        for (uint256 i; i < upkeepsLen;) {
            upkeepID = upkeepIDs[i];
            s_upkeepIDs.push(upkeepID);
            unchecked {
                ++i;
            }
        }
        emit UpkeepsAdded(upkeepIDs);
    }

    /// @inheritdoc IAutomationStation
    function removeUpkeep(uint256 upkeepIndex) external onlyOwner {
        uint256 upkeepID = _removeUpkeep(upkeepIndex);
        emit UpkeepRemoved(upkeepID);
    }

    /// @inheritdoc IAutomationStation
    function pauseUpkeeps(uint256[] calldata upkeepIDs) external onlyOwner {
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
    function unpauseUpkeeps(uint256[] calldata upkeepIDs) external onlyOwner {
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
        onlyOwner
    {
        MigratableKeeperRegistryInterfaceV2(oldRegistry).migrateUpkeeps(upkeepIDs, newRegistry);
        emit UpkeepsMigrated(oldRegistry, newRegistry, upkeepIDs);
    }

    /// @inheritdoc IAutomationStation
    function autoMigrate(address newRegistry)
        external
        onlyOwner
    {
        uint256 upkeepsLen = s_upkeepIDs.length;
        uint256[] memory upkeepIDs = new uint256[](upkeepsLen + 1);
        for(uint256 i; i < upkeepsLen; ) {
            upkeepIDs[i] = s_upkeepIDs[i];
            unchecked {
                ++i;
            }
        }
        upkeepIDs[upkeepsLen] = s_stationUpkeepID;
        address currentRegistry = address(_getStationUpkeepRegistry());
        MigratableKeeperRegistryInterfaceV2(currentRegistry).migrateUpkeeps(upkeepIDs, newRegistry);
        emit UpkeepsMigrated(currentRegistry, newRegistry, upkeepIDs);
    }

    /// @inheritdoc AutomationCompatibleInterface
    function performUpkeep(bytes calldata performData) external {
        if (msg.sender != address(s_forwarder)) revert AutomationStation__NotFromForwarder();
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        uint256 upkeepIndex = abi.decode(performData, (uint256));
        uint256 stationUpkeepID = s_stationUpkeepID;
        uint256 upkeepID;
        uint256 minBalance;
        RefuelConfig memory config = s_refuelConfig;
        if (upkeepIndex == MAX_UINT256) {
            upkeepID = s_stationUpkeepID;
            minBalance = config.stationUpkeepMinBalance;
        } else {
            upkeepID = s_upkeepIDs[upkeepIndex];
            minBalance = registry.getMinBalance(upkeepID);
        }
        if (registry.getBalance(upkeepID) > minBalance) revert AutomationStation__RefuelNotNeeded();
        if (stationUpkeepID != upkeepID) {
            if (block.timestamp - s_lastRefuelTimestamp[upkeepID] < config.minDelayNextRefuel) {
                revert AutomationStation__TooEarlyForNextRefuel();
            }
            s_lastRefuelTimestamp[upkeepID] = block.timestamp;
        }
        i_linkToken.approve(address(registry), config.refuelAmount);
        registry.addFunds(upkeepID, config.refuelAmount);
    }

    /**
     * @dev Internal function to register a new upkeep.
     * @param registrationParams Encoded registration params.
     * @return upkeepID The ID assigned to the newly registered upkeep.
     * @notice This function reverts with `AutomationStation__UpkeepRegistrationFailed` if the registration fails.
     */
    function _registerUpkeep(bytes calldata registrationParams) internal returns (uint256 upkeepID) {
        (bool success, bytes memory returnData) =
            s_registrar.call(bytes.concat(s_registerUpkeepSelector, registrationParams));
        if (!success) revert AutomationStation__UpkeepRegistrationFailed();
        return abi.decode(returnData, (uint256));
    }

    function _removeUpkeep(uint256 upkeepIndex) internal returns (uint256) {
        uint256 upkeepsLen = s_upkeepIDs.length;
        if (upkeepsLen == 0) revert AutomationStation__NoRegisteredUpkeep();
        uint256 upkeepID = s_upkeepIDs[upkeepIndex];
        if (upkeepIndex < upkeepsLen - 1) {
            s_upkeepIDs[upkeepIndex] = s_upkeepIDs[upkeepsLen - 1];
        }
        s_upkeepIDs.pop();
        return upkeepID;
    }

    function _getStationUpkeepRegistry() internal view returns (IAutomationRegistryConsumer registry) {
        return s_forwarder.getRegistry();
    }

    /// @inheritdoc AutomationCompatibleInterface
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        if (registry.getBalance(s_stationUpkeepID) <= s_refuelConfig.stationUpkeepMinBalance) {
            return (true, abi.encode(MAX_UINT256));
        }
        uint256 upkeepsLen = s_upkeepIDs.length;
        uint256 upkeepID;
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
    function getRefuelConfig() external view returns (RefuelConfig memory) {
        return s_refuelConfig;
    }
}
