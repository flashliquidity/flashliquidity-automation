// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAutomationStation {
    /// @notice Represents the configuration settings for refueling upkeeps in the Automation Station.
    /// @dev This struct holds settings that determine the behavior of the refueling process for upkeeps.
    struct RefuelConfig {
        uint96 refuelAmount; // The amount of LINK tokens to refuel an upkeep.
        uint96 stationUpkeepMinBalance; // The minimum balance threshold for the station's upkeep.
        uint32 minDelayNextRefuel; // The minimum delay time (in seconds) required between successive refuels. (station upkeep excluded)
    }

    /**
     * @dev Initializes the station.
     * @param approveAmountLINK Amount of LINK tokens approved to the registrar, must be equal or greater of the amount encoded in the registrationParams.
     * @param registrationParams Encoded registration params.
     */
    function initialize(uint256 approveAmountLINK, bytes calldata registrationParams) external;

    /// @dev Dismantles the station by canceling the station upkeep.
    function dismantle() external;

    /// @param forwarder The new Automation forwarder address.
    function setForwarder(address forwarder) external;

    /// @param registrar The new Automation registrar address.
    function setRegistrar(address registrar) external;

    /// @param registerUpkeepSelector The new registerUpkeep function selector of the Automation registrar.
    function setRegisterUpkeepSelector(bytes4 registerUpkeepSelector) external;

    /**
     * @notice Updates the configuration settings for refueling upkeeps in the Automation Station.
     * @dev Sets the new refueling configuration for the station. This includes the amount of tokens for refueling,
     *      the minimum balance threshold for upkeeps, and the minimum delay between refuels.
     * @param refuelAmount The amount of tokens (e.g., LINK) to be used for each refuel operation.
     * @param stationUpkeepMinBalance The minimum balance of the station upkeep.
     * @param minDelayNextReful The minimum time interval (in seconds) required between consecutive refuel operations.
     */
    function setRefuelConfig(uint96 refuelAmount, uint96 stationUpkeepMinBalance, uint32 minDelayNextReful) external;

    /**
     * @dev Recovers ERC20 tokens sent to the contract.
     * @param to Address to send the recovered tokens.
     * @param tokens Array of token addresses.
     * @param amounts Array of amounts of tokens to recover.
     */
    function recoverERC20(address to, address[] memory tokens, uint256[] memory amounts) external;

    /**
     * @dev Forces the refuel of the station upkeep with the specified amount.
     * @param refuelAmount The amount of LINK tokens to refuel.
     */
    function forceStationRefuel(uint96 refuelAmount) external;

    /**
     * @dev Forces the refuel of a registered upkeep with the specified amount.
     * @param upkeepIndex The index in the s_upkeepIDs array of the upkeep to refuel
     * @param refuelAmount The amount of LINK tokens to refuel.
     */
    function forceUpkeepRefuel(uint256 upkeepIndex, uint96 refuelAmount) external;

    /**
     * @dev Register a new upkeep, add its upkeepID to the s_upkeepIDs array of the station if max auto-approval has not been hit.
     * @param approveAmountLINK Amount of LINK tokens approved to the registrar, must be equal or greater of the amount encoded in the registrationParams.
     * @param registrationParams Encoded registration params.
     */
    function createUpkeep(uint256 approveAmountLINK, bytes calldata registrationParams) external;

    /**
     * @dev Add multiple upkeep to the s_upkeepIDs array of the station.
     * @param upkeepIDs Array of upkeep IDs to be added.
     */
    function addUpkeeps(uint256[] calldata upkeepIDs) external;
    /**
     * @dev Removes an upkeep from the station by its index.
     * @param upkeepIndex The index of the upkeep in the station's array.
     */
    function removeUpkeep(uint256 upkeepIndex) external;

    /**
     * @dev Pauses a set of upkeeps identified by their IDs.
     * @param upkeepIDs An array of `uint256` IDs of the upkeeps to be paused.
     */
    function pauseUpkeeps(uint256[] calldata upkeepIDs) external;

    /**
     * @dev Unpauses a set of upkeeps identified by their IDs.
     * @param upkeepIDs An array of `uint256` IDs of the upkeeps to be unpaused.
     */
    function unpauseUpkeeps(uint256[] calldata upkeepIDs) external;

    /**
     * @dev Withdraws LINK tokens from canceled upkeeps.
     * @param upkeepIDs Array of upkeep IDs to withdraw funds from.
     */
    function withdrawUpkeeps(uint256[] calldata upkeepIDs) external;

    /**
     * @notice Migrate a batch of upkeeps from an old registry to a new one.
     * @param oldRegistry The address of the current registry holding the upkeeps.
     * @param newRegistry The address of the new registry to which the upkeeps will be transferred.
     * @param upkeepIDs An array of `uint256` IDs representing the upkeeps to be migrated.
     */
    function migrateUpkeeps(address oldRegistry, address newRegistry, uint256[] calldata upkeepIDs) external;

    /// @return stationUpkeepRegistry The address of the station upkeep registry.
    function getStationUpkeepRegistry() external view returns (address stationUpkeepRegistry);

    /// @return stationUpkeepID The station upkeep.
    function getStationUpkeepID() external view returns (uint256 stationUpkeepID);

    /// @return forwarder The automation forwarder address.
    function getForwarder() external view returns (address forwarder);

    /// @return registrar The automation registrar address.
    function getRegistrar() external view returns (address);

    /// @return registerUpkeepSelector The function selector for registerUpkeep function of the registrar.
    function getRegisterUpkeepSelector() external view returns (bytes4 registerUpkeepSelector);

    /**
     * @param upkeepIndex The index in the array of upkeeps.
     * @return upkeepId The ID of the upkeep at the specified index.
     */
    function getUpkeepIdAtIndex(uint256 upkeepIndex) external view returns (uint256);

    /// @return upkeepsLength The total number of upkeeps registered in this station.
    function allUpkeepsLength() external view returns (uint256 upkeepsLength);

    /**
     * @notice Retrieves the current refueling configuration settings for the Automation Station.
     * @return refuelConfig RefuelConfig struct.
     */
    function getRefuelConfig() external view returns (RefuelConfig memory refuelConfig);
}
