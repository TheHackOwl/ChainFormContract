// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20, IRewardLogic} from "./FormDefinition.sol";

abstract contract RewardLogic  is IRewardLogic{
    mapping(address => mapping(IERC20 => uint)) internal tokenRewards;

    function claim(address _user, IERC20 token) external {
        uint256 rewardAmount = tokenRewards[msg.sender][token];
        tokenRewards[msg.sender][token] = 0;
        // transfer reward to user
        token.transfer(_user, rewardAmount);
    }

    function getRewards(address _user) external view returns (uint256) {
        return 0;
    }
}

contract FixedReward is RewardLogic {
    function reward(address _user, uint256 formId) external override {
        
    }
}

