// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20, IRewardLogic, FormSettings, RewardRule} from "./FormDefinition.sol";

abstract contract RewardLogic is IRewardLogic{
    address private owner;
    mapping(uint256 => FormSettings) internal rewardSettings;
    mapping(address => mapping(IERC20 => uint)) internal tokenRewards;

    function claim(address _user, IERC20 token) external {
        uint256 rewardAmount = tokenRewards[msg.sender][token];
        tokenRewards[msg.sender][token] = 0;
        // transfer reward to user
        token.transfer(_user, rewardAmount);
    }

    function getRewards(address _user, IERC20 token) external view returns (uint256) {
        return tokenRewards[_user][token];
    }
}

contract FixedReward is RewardLogic {
    mapping(uint256 => RewardAccount) internal rewards;

    struct RewardAccount {
        uint256 remainingRewardNumber;
    }

    function addReward(uint256 formId) payable external{
        RewardRule memory rule = rewardSettings[formId].rewardRule;
        require(rule.intSettings.length > 0, "Invalid reward settings.");
        require(rule.token != IERC20(address(0)), "Invalid reward token.");
        
        int256 rewardAmount = rule.intSettings[0];
        int256 rewardNumber = rule.intSettings[1];

        RewardAccount storage rewardAccount = rewards[formId];
        
        rewardAccount.remainingRewardNumber = uint256(rewardNumber);

        require(rewardAmount > 0, "Invalid reward amount.");
        require(rewardNumber > 0, "Invalid reward number.");

        uint256 totalRewardAmount = uint256(rewardAmount * rewardNumber);
        uint256 value = rule.token.balanceOf(msg.sender);
        revert("value");
        require(rule.token.balanceOf(msg.sender) >= totalRewardAmount, "Insufficient balance.");
        
        rule.token.transfer(address(this), totalRewardAmount);
    }

    function reward(address _user, uint256 formId) external override {
        RewardAccount storage rewardAccount = rewards[formId];
        if (rewardAccount.remainingRewardNumber <= 0) {
            return;
        }
        
        RewardRule memory rule = rewardSettings[formId].rewardRule;
        uint256 rewardAmount = uint(rule.intSettings[0]);
        IERC20 token = rule.token;

        rewardAccount.remainingRewardNumber -= 1;
        tokenRewards[_user][token] += rewardAmount;
    }

    function getAwardTrigger() external pure override returns (int8) {
        return 1;
    }
}

