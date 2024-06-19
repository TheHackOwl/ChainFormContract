// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRewardLogic, FormSettings, RewardRule, LogicMeta} from "./FormDefinition.sol";

abstract contract RewardLogic is IRewardLogic{
    address private owner;
    mapping(uint256 => FormSettings) internal formSettings;
    mapping(address => mapping(IERC20 => uint)) internal tokenRewards;
}

contract FixedReward is RewardLogic {
    using SafeERC20 for IERC20;

    mapping(uint256 => RewardAccount) internal rewards;

    struct RewardAccount {
        uint256 remainingRewardNumber;
    }

    function addReward(uint256 formId) payable external{
        RewardRule memory rule = formSettings[formId].rewardRule;
        require(rule.intSettings.length == 2, "Invalid reward settings.");

        IERC20 token = rule.token;
        require(token != IERC20(address(0)), "Invalid reward token.");

        int256 rewardAmount = rule.intSettings[0];
        int256 rewardNumber = rule.intSettings[1];

        RewardAccount storage rewardAccount = rewards[formId];

        rewardAccount.remainingRewardNumber = uint256(rewardNumber);

        require(rewardAmount > 0, "Invalid reward amount.");
        require(rewardNumber > 0, "Invalid reward number.");

        uint256 totalRewardAmount = uint256(rewardAmount * rewardNumber);
        require(token.balanceOf(msg.sender) >= totalRewardAmount, "Insufficient balance.");
        token.safeTransferFrom(msg.sender, address(this), totalRewardAmount);
    }

    function reward(address _user, uint256 formId) external override returns(uint256 rewardAmount) {
        RewardAccount storage rewardAccount = rewards[formId];
        if (rewardAccount.remainingRewardNumber <= 0) {
            return 0;
        }

        RewardRule memory rule = formSettings[formId].rewardRule;
        rewardAmount = uint(rule.intSettings[0]);
        IERC20 token = rule.token;

        rewardAccount.remainingRewardNumber -= 1;
        tokenRewards[_user][token] += rewardAmount;
    }



    function getMetaData() external pure override returns (LogicMeta memory) {
        string[] memory argsDescription = new string[](2);
        argsDescription[0] = "Reward Amount";
        argsDescription[1] = "Reward Number";
        return LogicMeta("Fixed Reward", "Fixed reward for each submission.", "1.0.0", argsDescription, 2, 1);
    }
}

contract LotteryReward is RewardLogic {
    using SafeERC20 for IERC20;

    mapping(uint256 => RewardAccount) internal rewards;

    struct RewardAccount {
        uint256 remainingRewardNumber;
    }

    function addReward(uint256 formId) payable external{
        RewardRule memory rule = formSettings[formId].rewardRule;
        require(rule.intSettings.length == 3, "Invalid reward settings.");

        IERC20 token = rule.token;
        require(token != IERC20(address(0)), "Invalid reward token.");

        int256 rewardAmount = rule.intSettings[0];
        int256 rewardNumber = rule.intSettings[1];
        int256 rewardRate = rule.intSettings[2];

        RewardAccount storage rewardAccount = rewards[formId];

        rewardAccount.remainingRewardNumber = uint256(rewardNumber);

        require(rewardAmount > 0, "Invalid reward amount.");
        require(rewardNumber > 0, "Invalid reward number.");
        require(rewardRate > 0 && rewardRate < 100, "Invalid reward rate.");

        uint256 totalRewardAmount = uint256(rewardAmount * rewardNumber);
        require(token.balanceOf(msg.sender) >= totalRewardAmount, "Insufficient balance.");
        token.safeTransferFrom(msg.sender, address(this), totalRewardAmount);
    }

    function reward(address _user, uint256 formId) external override returns(uint256 rewardAmount) {
        RewardAccount storage rewardAccount = rewards[formId];
        if (rewardAccount.remainingRewardNumber <= 0) {
            return 0;
        }

        RewardRule memory rule = formSettings[formId].rewardRule;
        rewardAmount = uint256(rule.intSettings[0]);
        uint256 rate = uint256(rule.intSettings[2]);

        // Lottery
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _user, formId))) % 100;
        if (randomNumber >= rate) {
            return 0;
        }

        IERC20 token = rule.token;
        rewardAccount.remainingRewardNumber -= 1;
        tokenRewards[_user][token] += rewardAmount;
    }

    function getMetaData() external pure override returns (LogicMeta memory) {
        string[] memory argsDescription = new string[](3);
        argsDescription[0] = "Reward Amount";
        argsDescription[1] = "Reward Number";
        argsDescription[2] = "Winning Rate, between 0-100";
        return LogicMeta("Lottery Reward", "Lottery reward for each submission.", "1.0.0", argsDescription, 3, 1);
    }
}