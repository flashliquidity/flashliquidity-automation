// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAutomationStation {
    /**
     * @dev Initializes the station.
     * @param initializationAmount Amount of LINK tokens to fund the station upkeep.
     */
    function initialize(uint96 initializationAmount) external;

    /// @dev Dismantles the station by canceling the station upkeep.
    function dismantle() external;

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
     * @dev Forces the refuel of the station upkeep with the specified amount.
     * @param refuelAmount The amount of LINK tokens to refuel.
     */
    function forceStationRefuel(uint96 refuelAmount) external;

    /**
     * @dev Register a new upkeep to the station.
     * @param upkeepContract The contract address of the upkeep.
     * @param amount The amount of LINK tokens to fund the upkeep.
     * @param gasLimit The gas limit for the upkeep execution.
     * @param triggerType The type of trigger for the upkeep.
     * @param name The name of the upkeep.
     * @param checkData Data for the checkUpkeep function.
     * @param triggerConfig Configuration for the trigger.
     * @param offchainConfig Offchain configuration for the upkeep.
     */
    function addUpkeep(
        address upkeepContract,
        uint96 amount,
        uint32 gasLimit,
        uint8 triggerType,
        string memory name,
        bytes calldata checkData,
        bytes calldata triggerConfig,
        bytes calldata offchainConfig
    ) external;

    /**
     * @dev Removes an upkeep from the station by its index.
     * @param upkeepIndex The index of the upkeep in the station's array.
     */
    function removeUpkeep(uint256 upkeepIndex) external;

    /**
     * @dev Recovers ERC20 tokens sent to the contract.
     * @param to Address to send the recovered tokens.
     * @param tokens Array of token addresses.
     * @param amounts Array of amounts of tokens to recover.
     */
    function recoverERC20(address to, address[] memory tokens, uint256[] memory amounts) external;

    /**
     * @dev Withdraws LINK tokens from canceled upkeeps.
     * @param upkeepIDs Array of upkeep IDs to withdraw funds from.
     */
    function withdrawUpkeeps(uint256[] calldata upkeepIDs) external;

    /// @return stationUpkeepID The station upkeep.
    function getStationUpkeepID() external view returns (uint256 stationUpkeepID);

    /**
     * @param upkeepIndex The index in the array of upkeeps.
     * @return upkeepId The ID of the upkeep at the specified index.
     */
    function getUpkeepIdAtIndex(uint256 upkeepIndex) external view returns (uint256);

    /// @return upkeepsLength The total number of upkeeps registered in this station.
    function allUpkeepsLength() external view returns (uint256 upkeepsLength);

    /**
     * @notice Retrieves the current refueling configuration settings for the Automation Station.
     * @return refuelAmount The amount of LINK tokens currently set for each refuel operation.
     * @return stationUpkeepMinBalance The current minimum balance in LINK tokens that an upkeep should maintain.
     * @return minDelayNextRefuel The current minimum time interval (in seconds) required between consecutive refuel operations.
     */
    function getRefuelConfig()
        external
        view
        returns (uint96 refuelAmount, uint96 stationUpkeepMinBalance, uint32 minDelayNextRefuel);
}
