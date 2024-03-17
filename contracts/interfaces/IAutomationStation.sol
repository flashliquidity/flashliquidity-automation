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
     * @dev Sets the amount of LINK tokens used for refueling upkeeps.
     * @param refuelAmount The new refuel amount in LINK tokens.
     */
    function setRefuelAmount(uint96 refuelAmount) external;

    /**
     * @dev Sets the minimum balance threshold for the station upkeep.
     * @param minBalance The new minimum balance in LINK tokens.
     */
    function setStationUpkeepMinBalance(uint96 minBalance) external;

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

    /// @return refuelAmount The amount of LINK tokens used for refueling.
    function getRefuelAmount() external view returns (uint96 refuelAmount);

    /// @return stationUpkeepMinBalance The minimum balance required in LINK tokens for the station's upkeep.
    function getStationUpkeepMinBalance() external view returns (uint256 stationUpkeepMinBalance);
}
