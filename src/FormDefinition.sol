// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

struct Form {
    address creator;
    uint256 createdAt;
    string name;
    string description;
    string[] questions;
}

interface IRewardLogic {
    // @title Set reward for form
    // @param formId Form ID
    function addReward(uint256 formId) payable external;

    // @title Reward user
    // @param _user User address
    // @param formId Form ID
    function reward(address _user, uint256 formId) external;

    // @title Claim reward
    // @param _user User address
    // @param token Token address
    function claim(address _user, IERC20 token) external;

    // @title Get rewards
    // @param _user User address
    // @param token Token address
    function getRewards(address _user, IERC20 token) external view returns (uint256);

    // @title Get award trigger
    // @return Award trigger
    // @dev This function should return the trigger for the reward logic
    // 1 - On submission
    // 2 - On sponsor approval
    function getAwardTrigger() external pure returns (int8);
}

struct FormSettings {
    RewardRule rewardRule;
    IRewardLogic rewardLogic;
}

struct RewardRule {
    int256[] intSettings;
    IERC20 token;
}

struct Submission {
    string dataHash;
    string cid;
    address submitter;
    uint256 submittedAt;
}

