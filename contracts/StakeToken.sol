//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakeToken is Ownable, ERC20 {
    using SafeMath for uint256;

    // Payable address can receive Ether
    address payable public _owner;

    // Set the Token buy price for 1 ether
    uint256 public buyPrice = 1000;

    // Set the Threshold Period for withdrawal
    uint256 public thresholdTime = 1 * 24 * 60 * 60 * 7;

    // Set the Reward percentage 1%
    uint256 public a1 = 1;

    // Declare new Stake struct
    struct Stake {
        uint256 amount;
        uint256 createdTimestamp;
    }

    /** We usually require to know who are all the stakeholders.*/
    mapping(address => Stake) public stakeholders;

    // The accumulated rewards for each stakeholder.

    mapping(address => uint256) internal rewards;

    constructor() payable ERC20("StakeToken", "STN") {
        uint256 initialSupply = 1000;

        _owner = payable(owner());

        // Mint the new set of tokens
        _mint(_owner, initialSupply);
    }

    function buyToken() public payable returns (bool) {
        //Get the amount paid in ether
        uint256 amount = msg.value;

        // Calculate the amount ot of tokens to buy
        // Based on how much Ether was sent/paid
        uint256 amountToBuy = amount.mul(buyPrice);

        _mint(msg.sender, amountToBuy);

        return true;
    }

    // Update the total Supply of tokens
    function incrementTotalSupply(uint256 amount)
        public
        view
        returns (uint256)
    {
        return SafeMath.add(amount, totalSupply());
    }

    // Modify Token Buy Price
    function modifyTokenBuyPrice(uint256 _buyPrice)
        public
        onlyOwner
        returns (bool)
    {
        buyPrice = _buyPrice;
        return true;
    }

    // ===================  STAKING MECHANISM ===================
    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake) public returns (bool) {
        // get stake balance
        uint256 stackBalance = getStackBalance(msg.sender);

        // create  a new stake with Timestamp
        stakeholders[msg.sender] = Stake(
            stackBalance.add(_stake),
            block.timestamp + thresholdTime
        );

        // Deduct tokens from accounts
        // Call _burn() so token cannot be spent after staked.
        _burn(msg.sender, _stake);

        return true;
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake) public {
        // get stake balance
        uint256 stackBalance = getStackBalance(msg.sender);

        // create a new stake with a new Timestamp
        stakeholders[msg.sender] = Stake(
            stackBalance.sub(_stake),
            block.timestamp + thresholdTime
        );
        _mint(msg.sender, _stake);
    }

    /**
     * @notice Get stack balance of a given  stakeholder account.
     * @param _addr The stakeholder account address.
     */
    function getStackBalance(address _addr) public view returns (uint256) {
        return stakeholders[_addr].amount;
    }

    /**
     * @notice Check if stakeholder is already in the list of stakeholders.
     * @param _stakeholder The stakeholder to add.
     */
    function isStakeholder(address _stakeholder) public view returns (bool) {
        return (stakeholders[_stakeholder].amount > 0) ? true : false;
    }

    // ===================  REWARD MECHANISM =================== //
    modifier exceededThresholdTime() {
        require(
            block.timestamp > stakeholders[msg.sender].createdTimestamp,
            "Can not reward because Threshold period is not reached!"
        );
        _;
    }

    /**
     * @notice Reward the stakeholders after Threshold period is reached.
     */
    function rewardStakeHolder() public exceededThresholdTime {
        // Calculate the Stakeholder rewards
        uint256 _rewards = calcStackReward(msg.sender);

        _mint(msg.sender, _rewards);
    }

    /**
     * @notice This method Calculate the reward of stakeholders
     * @param _stakeholder The Address of the Stakeholder
     */
    function calcStackReward(address _stakeholder)
        internal
        view
        returns (uint256)
    {
        // Check the Stakeholder balance
        uint256 balance = getStackBalance(_stakeholder);

        // Require that the Stakeholder balance is greater 0
        require(balance > 0, "Stakeholder balance is negative");

        return balance * (a1.div(100));
    }
}
