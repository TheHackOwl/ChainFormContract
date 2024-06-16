// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Form, Submission, RewardRule, FormSettings, IRewardLogic} from "./FormDefinition.sol";
import {Owned} from "./Owned.sol";
import {RevertReasonParser} from "./utils.sol";

contract ChainForm is Owned {
    mapping(uint256 => FormSettings) internal rewardSettings;
    
    Form[] private forms;
    mapping(uint256 => Submission[]) private submissions; // Mapping from form ID to submissions
    mapping(address => uint256[]) private userForms; // Mapping from user address to list of form IDs
    mapping(uint256 => mapping(address => bool)) private hasSubmitted; // Mapping to check if a user has submitted a form
    mapping(IRewardLogic => bool) private rewardLogics;
    

    using RevertReasonParser for bytes;

    constructor() Owned() {}

    // @title Create a new form
    function createForm(string memory _name, string memory _description, string[] memory _questions, FormSettings memory _formSettings) external payable returns (uint256 formId) {
        require(bytes(_name).length > 0, "Name should not be empty.");
        require(_questions.length > 0, "Questions should not be empty.");
        formId = forms.length;
        forms.push(Form(msg.sender, block.timestamp, _name, _description, _questions));
        IRewardLogic rewardLogic = _formSettings.rewardLogic;
        if (rewardLogics[rewardLogic]){
            setFormSettings(formId, _formSettings);
            (bool success, bytes memory retData) = address(rewardLogic).delegatecall(abi.encodeWithSignature("addReward(uint256)", formId));
            if (!success) {
                revert(retData.getRevertMsg());
            }
        } else if (rewardLogic != IRewardLogic(address(0))) {
            revert("Invalid reward logic.");
        }
        userForms[msg.sender].push(formId);
    }

    // @title Set form settings
    // @param _formId Form ID
    // @param _formSettings Form settings
    function setFormSettings(uint256 _formId, FormSettings memory _formSettings) private {
        FormSettings memory formSettings = rewardSettings[_formId];
        require(formSettings.rewardLogic == IRewardLogic(address(0)), "Form settings already set.");
        require(_formSettings.rewardRule.token != IERC20(address(0)), "Invalid reward token.");
        _formSettings.rewardRule.token.balanceOf(msg.sender);
        rewardSettings[_formId] = _formSettings;
    } 

    // @title Add reward logic
    // @param _rewardLogic Reward logic contract
    function addRewardLogic(IRewardLogic _rewardLogic) external onlyOwner {
        rewardLogics[_rewardLogic] = true;
    }

    // @title Get forms by creator
    // @param _creator Creator address
    function getMyForms() public view returns (uint256[] memory) {
        return userForms[msg.sender];
    }

    // @title Get form by ID
    // @param _formId Form ID
    // @return Form object
    function getForm(uint256 _formId) public view returns (Form memory) {
        require(_formId < forms.length, "Form does not exist.");
        return forms[_formId];
    }

    // @title Submit form responses
    // @param _formId Form ID
    // @param _dataHash IPFS data hash
    // @param _cid IPFS CID
    function submitForm(uint256 _formId, string memory _dataHash, string memory _cid) external returns (uint256 submissionId) {
        require(_formId < forms.length, "Form does not exist.");
        require(!hasSubmitted[_formId][msg.sender], "You have already submitted this form.");
        submissionId = submissions[_formId].length;
        submissions[_formId].push(Submission(_dataHash, _cid, msg.sender, block.timestamp));
        hasSubmitted[_formId][msg.sender] = true;

        // Reward user
        if (rewardSettings[_formId].rewardLogic != IRewardLogic(address(0))) {
            IRewardLogic rewardLogic = rewardSettings[_formId].rewardLogic;
            if (rewardLogic.getAwardTrigger() == 1) {
                (bool success, ) = address(rewardLogic).delegatecall(abi.encodeWithSignature("reward(address,uint256)", msg.sender, _formId));
                if (!success) {
                    revert("Failed to reward user.");
                }
            }
        }
    }

    // @title Check if user has submitted a form
    // @param _formId Form ID
    // @return Boolean value
    function hasUserSubmitted(uint256 _formId) public view returns (bool) {
        return hasSubmitted[_formId][msg.sender];
    }

    // @title Get submissions for a form
    // @param _formId Form ID
    // @return Submission array
    function getSubmissions(uint256 _formId) public view returns (Submission[] memory) {
        require(_formId < forms.length, "Form does not exist.");
        return submissions[_formId];
    }

    // @title Get submissions by page
    // @param _formId Form ID
    // @param _page Page number
    // @param _perPage Number of submissions per page
    // @return Submission array
    function getSubmissionsByPage(uint256 _formId, uint256 _page, uint256 _perPage) public view returns (Submission[] memory) {
        require(_formId < forms.length, "Form does not exist.");
        require(_page > 0, "Page number should be greater than 0.");
        require(_perPage > 0, "Per page should be greater than 0.");

        uint256 start = (_page - 1) * _perPage;
        uint256 end = start + _perPage;
        if (end > submissions[_formId].length) {
            end = submissions[_formId].length;
        }

        Submission[] memory result = new Submission[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = submissions[_formId][i];
        }

        return result;
    }
}
