// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {Owned} from "./Owned.sol";

import {IRewardLogic} from "./FormDefinition.sol";

contract Registry is Owned {
    address private current;

    IRewardLogic[] private rewardContracts;
    mapping(IRewardLogic => bool) private rewardContractsExist;

    constructor() Owned(){}

    event Updated(
        address indexed current
    );

    function update(address _contract) public onlyOwner {
        current = _contract;
        
        emit Updated(current);
    }

    function get() public view returns (address) {
        return current;
    }

    function addRewardContract(IRewardLogic rewardLogic) public onlyOwner {
        if (rewardContractsExist[rewardLogic]) {
            return;
        }
        rewardContracts.push(rewardLogic);
        rewardContractsExist[rewardLogic] = true;
    }

    function getRewardContracts() public view returns (IRewardLogic[] memory) {
        return rewardContracts;
    }

    function checkAllowedRewardContract(IRewardLogic rewardLogic) public view returns (bool) {
        return rewardContractsExist[rewardLogic];
    }

    function removeRewardContract(IRewardLogic rewardLogic) public onlyOwner {
        for (uint256 i = 0; i < rewardContracts.length; i++) {
            if (rewardContracts[i] == rewardLogic) {
                rewardContracts[i] = rewardContracts[rewardContracts.length - 1];
                rewardContracts.pop();
                rewardContractsExist[rewardLogic] = false;
                break;
            }
        }
    }
}
