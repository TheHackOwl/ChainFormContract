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
    function reward(address _user, uint256 formId) external;

    function claim(address _user, IERC20 token ) external;
    function getRewards(address _user) external view returns (uint256);
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

