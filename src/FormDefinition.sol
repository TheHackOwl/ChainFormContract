// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

struct LogicMeta {
    string name;
    string description;
    string version;
    string[] argsDescription;
    int8 argsNumber;
    int8 trigger;
}

interface IRewardLogic {
    // @title Set reward for form
    // @param formId Form ID
    function addReward(uint256 formId) payable external;

    // @title Reward user
    // @param _user User address
    // @param formId Form ID
    // @return rewardAmount Reward amount
    function reward(address _user, uint256 formId) external returns(uint256 rewardAmount);

    // @title Get this reward logic meta data
    // @return Reward logic meta data
    // @dev This function should return the trigger for the reward logic
    // 1 - On submission
    // 2 - On sponsor approval
    function getMetaData() external pure returns (LogicMeta memory);
}

struct FormSettings {
    RewardRule rewardRule;
    IRewardLogic rewardLogic;
    uint256 expireAt;
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

