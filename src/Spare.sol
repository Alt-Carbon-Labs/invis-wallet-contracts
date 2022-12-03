// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title The EthBalanceMonitor contract
 * @notice A contract compatible with Chainlink Automation Network that monitors and funds eth addresses
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract TrialPeriodMonitor is
    ConfirmedOwner,
    Pausable,
    AutomationCompatibleInterface
{
    // observed limit of 45K + 10k buffer
    uint256 private constant MIN_GAS_FOR_TRANSFER = 55_000;
    uint256 public counter;

    // event FundsAdded(uint256 amountAdded, uint256 newBalance, address sender);
    // event FundsWithdrawn(uint256 amountWithdrawn, address payee);
    event TopUpSucceeded(address indexed recipient);
    event TopUpFailed(address indexed recipient);
    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
    // event MinWaitPeriodUpdated(
    //     uint256 oldMinWaitPeriod,
    //     uint256 newMinWaitPeriod
    // );
    event Expire(uint256 timestamp);
    event Perform(uint256[] timestamp);
    event CharCreated(Character char);
    event CharUpdated(Character char);

    error InvalidWatchList();
    error OnlyKeeperRegistry();
    error DuplicateAddress(address duplicate);

    struct Target {
        bool isTrialActive;
        uint56 expiryTimestamp;
        uint56 lastUpdatedTimestamp; 
    }
    
    struct Character {
        uint256 id;
        bool isTrialActive;
        uint256 expiryTimestamp;
    }

    address private s_keeperRegistryAddress;
    uint256[] private s_expiryTimes;
    mapping(address => Target) internal s_targets;
    // timestamp => character
    mapping(uint256 => Character) internal s_characters;

    /**
     * 
     */
    constructor(
        // address keeperRegistryAddress,
        // uint256 _timeBetweenExpiries
    ) ConfirmedOwner(msg.sender) {
        counter = 5;
        // timeBetweenExpiries = _timeBetweenExpiries;
        // setKeeperRegistryAddress(keeperRegistryAddress);
    }

    /**
     * @notice Sets the list of addresses to watch and their funding parameters
     */
    function setExpiryTimes(
    ) external {
        uint256[] memory watchList = new uint256[](counter);
        for (uint256 idx = 1; idx <= counter; idx++) {
            uint256 expiryTime = block.timestamp + (5 * idx);
            watchList[idx-1] = expiryTime; 
            
            s_characters[expiryTime] = Character ({
                id: idx-1,
                isTrialActive: true,
                expiryTimestamp: expiryTime
            });
            
            emit CharCreated(s_characters[expiryTime]);
            
        }
        
        s_expiryTimes = watchList;
    }

    function getExpiryTimes()
        public
        view 
        returns (uint256[] memory expiryTimes)
    {
        return s_expiryTimes;
    }

    /**
     * @notice Gets a list of addresses that are under funded
     * @return list of addresses that are underfunded
     */
    // function getUnderfundedAddresses() public view returns (address[] memory) {
    //     address[] memory watchList = s_watchList;
    //     address[] memory needsFunding = new address[](watchList.length);
    //     uint256 count = 0;
    //     // uint256 minWaitPeriod = s_minWaitPeriodSeconds;
    //     uint256 balance = address(this).balance;
    //     Target memory target;
    //     for (uint256 idx = 0; idx < watchList.length; idx++) {
    //         target = s_targets[watchList[idx]];
    //         if (
    //             target.lastTopUpTimestamp <= block.timestamp &&
    //             balance >= target.topUpAmountWei &&
    //             watchList[idx].balance < target.minBalanceWei
    //         ) {
    //             needsFunding[count] = watchList[idx];
    //             count++;
    //             balance -= target.topUpAmountWei;
    //         }
    //     }
    //     if (count != watchList.length) {
    //         assembly {
    //             mstore(needsFunding, count)
    //         }
    //     }
    //     return needsFunding;
    // }

    /**
     * @notice Send funds to the addresses provided
     */
    function makeExpire(uint256[] memory needsExpiry) public whenNotPaused {
        Character memory updateTarget;
        for (uint256 idx = 0; idx < needsExpiry.length; idx++) {
            updateTarget = s_characters[needsExpiry[idx]];

            updateTarget.isTrialActive = false;
            emit CharUpdated(updateTarget);
        }
    }

    /**
     * @notice Get list of addresses that are underfunded and return payload compatible with Chainlink Automation Network
     * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoded list of addresses that need funds
     */
    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        whenNotPaused
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256[] memory needsExpiry = getExpiryTimes();
        upkeepNeeded = needsExpiry.length > 0;
        performData = abi.encode(needsExpiry);
        return (upkeepNeeded, performData);
    }

    /**
     * @notice Called by Chainlink Automation Node to send funds to underfunded addresses
     * @param performData The abi encoded list of addresses to fund
     */
    function performUpkeep(
        bytes calldata performData
    ) external override whenNotPaused {
        uint256[] memory needsExpiry = abi.decode(performData, (uint256[]));
        makeExpire(needsExpiry);
    }

    /**
     * @notice Withdraws the contract balance
     * @param amount The amount of eth (in wei) to withdraw
     * @param payee The address to pay
     */
    // function withdraw(
    //     uint256 amount,
    //     address payable payee
    // ) external onlyOwner {
    //     require(payee != address(0));
    //     emit FundsWithdrawn(amount, payee);
    //     payee.transfer(amount);
    // }

    /**
     * @notice Receive funds
     */
    // receive() external payable {
    //     emit FundsAdded(msg.value, address(this).balance, msg.sender);
    // }

    /**
     * @notice Sets the Chainlink Automation registry address
     */
    function setKeeperRegistryAddress(
        address keeperRegistryAddress
    ) public onlyOwner {
        require(keeperRegistryAddress != address(0));
        emit KeeperRegistryAddressUpdated(
            s_keeperRegistryAddress,
            keeperRegistryAddress
        );
        s_keeperRegistryAddress = keeperRegistryAddress;
    }

    /**
     * @notice Sets the minimum wait period (in seconds) for addresses between funding
     */
    // function setMinWaitPeriodSeconds(uint256 period) public onlyOwner {
    //     emit MinWaitPeriodUpdated(s_minWaitPeriodSeconds, period);
    //     s_minWaitPeriodSeconds = period;
    // }

    /**
     * @notice Gets the Chainlink Automation registry address
     */
    function getKeeperRegistryAddress()
        external
        view
        returns (address keeperRegistryAddress)
    {
        return s_keeperRegistryAddress;
    }

    /**
     * @notice Gets the minimum wait period
     */
    // function getMinWaitPeriodSeconds() external view returns (uint256) {
    //     return s_minWaitPeriodSeconds;
    // }

    /**
     * @notice Gets configuration information for an address on the watchlist
     */
    // function getAccountInfo(
    //     address targetAddress
    // )
    //     external
    //     view
    //     returns (
    //         bool isActive,
    //         uint96 minBalanceWei,
    //         uint96 topUpAmountWei,
    //         uint56 lastTopUpTimestamp
    //     )
    // {
    //     Target memory target = s_targets[targetAddress];
    //     return (
    //         target.isTrialActive,
    //         target.expiryTimestamp,
    //         target.lastUpdatedTimestamp
    //     );
    // }

    /**
     * @notice Pauses the contract, which prevents executing performUpkeep
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyKeeperRegistry() {
        if (msg.sender != s_keeperRegistryAddress) {
            revert OnlyKeeperRegistry();
        }
        _;
    }
}
