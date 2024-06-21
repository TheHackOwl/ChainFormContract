// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Form, Submission, RewardRule, FormSettings, IRewardLogic} from "./FormDefinition.sol";
import {Owned} from "./Owned.sol";
import {RevertReasonParser} from "./utils.sol";
import {Registry} from "./Registry.sol";

contract ChainForm is Owned {
    mapping(uint256 => FormSettings) internal formSettings;
    mapping(address => mapping(IERC20 => uint)) private tokenRewards; // Mapping from user address to token to reward amount

    Form[] private forms;
    mapping(uint256 => Submission[]) private submissions; // Mapping from form ID to submissions
    mapping(address => uint256[]) private userForms; // Mapping from user address to list of form IDs
    mapping(uint256 => mapping(address => bool)) private hasSubmitted; // Mapping to check if a user has submitted a form
    Registry registry;

    using SafeERC20 for IERC20;
    using RevertReasonParser for bytes;

    constructor(Registry _registry) Owned() {
        registry = _registry;
    }

    event FormCreated(uint256 indexed formId, address indexed creator, bool indexed isPublic,uint256 timestamp);

    // @title Create a new form
    function createForm(string memory _name, string memory _description, string[] memory _questions, FormSettings memory _formSettings) external payable returns (uint256 formId) {
        require(bytes(_name).length > 0, "Name should not be empty.");
        require(_questions.length > 0, "Questions should not be empty.");
        formId = forms.length;
        forms.push(Form(msg.sender, block.timestamp, _name, _description, _questions));
        setFormSettings(formId, _formSettings);
        userForms[msg.sender].push(formId);
        emit FormCreated(formId, msg.sender, _formSettings.isPublic, block.timestamp);
    }

    // @title Set form settings
    // @param _formId Form ID
    // @param _formSettings Form settings
    function setFormSettings(uint256 _formId, FormSettings memory _formSettings) private {
        IRewardLogic rewardLogic = _formSettings.rewardLogic;
        if (registry.checkAllowedRewardContract(rewardLogic)) {
            formSettings[_formId] = _formSettings;
            require(_formSettings.rewardRule.token != IERC20(address(0)), "Invalid reward token.");
            (bool success, bytes memory retData) = address(rewardLogic).delegatecall(abi.encodeWithSignature("addReward(uint256)", _formId));
            if (!success) {
                revert(retData.getRevertMsg());
            }
        } else if (rewardLogic != IRewardLogic(address(0))) {
            revert("Invalid reward logic.");
        } else {
            formSettings[_formId] = _formSettings;
        }
    }

    // @title Get forms by creator
    // @param _creator Creator address
    function getMyForms() public view returns (uint256[] memory) {
        return userForms[msg.sender];
    }

    // @title Get form by ID
    // @param _formId Form ID
    // @return Form object
    function getForm(uint256 _formId) public view returns (Form memory, FormSettings memory) {
        require(_formId < forms.length, "Form does not exist.");
        return (forms[_formId], formSettings[_formId]);
    }

    // @title Get public forms by page
    // @param _page Page number
    // @param _perPage Number of forms per page
    // @return Form array
    // @dev order by id desc
    function getFormsByPage(uint256 _page, uint256 _perPage) public view returns (Form[] memory result) {
        require(_page > 0, "Page number should be greater than 0.");
        require(_perPage > 0, "Per page should be greater than 0.");

        uint256 start = (_page - 1) * _perPage;
        uint256 end = start + _perPage;
        if (end > forms.length) {
            end = forms.length;
        }

        if (start >= end) {
            return new Form[](0);
        }

        result = new Form[](end - start);
        for (uint256 i = start; i < end; i++) {
            if (i == forms.length) {
                break;
            }
            result[i - start] = forms[forms.length - i - 1];
        }
    }

    // @title Reward changed event
    // @param changeType Change type 1.reward 2.claim
    // @param user User address
    // @param token Reward token
    // @param formId Form ID
    // @param rewardAmount Reward amount
    // @param timestamp Timestamp
    event RewardChanged(uint8 indexed changeType, address indexed user, IERC20 token, uint256 formId, uint256 rewardAmount, uint256 timestamp);

    // @title Submit form responses
    // @param _formId Form ID
    // @param _dataHash IPFS data hash
    // @param _cid IPFS CID
    function submitForm(uint256 _formId, string memory _dataHash, string memory _cid) external returns (uint256 submissionId) {
        require(_formId < forms.length, "Form does not exist.");
        require(!hasSubmitted[_formId][msg.sender], "You have already submitted this form.");
        FormSettings memory settings = formSettings[_formId];
        require(settings.expireAt == 0 || block.timestamp < settings.expireAt, "Form has expired.");
        submissionId = submissions[_formId].length;
        submissions[_formId].push(Submission(_dataHash, _cid, msg.sender, block.timestamp));
        hasSubmitted[_formId][msg.sender] = true;

        // Reward user
        if (settings.rewardLogic != IRewardLogic(address(0))) {
            IRewardLogic rewardLogic = settings.rewardLogic;
            if (rewardLogic.getMetaData().trigger == 1) {
                (bool success, bytes memory data) = address(rewardLogic).delegatecall(abi.encodeWithSignature("reward(address,uint256)", msg.sender, _formId));
                if (!success) {
                    revert("Failed to reward user.");
                }
                uint256 rewardAmount = abi.decode(data, (uint256));
                if (rewardAmount > 0) {
                    emit RewardChanged(1, msg.sender, settings.rewardRule.token, _formId, rewardAmount, block.timestamp);
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

    // @title Get rewards for user
    // @param token Reward token
    // @return Reward amount
    function getRewards(IERC20 token) public view returns (uint256) {
        return tokenRewards[msg.sender][token];
    }

    // @title Claim reward
    // @param token Reward token
    function claim(IERC20 token) external {
        uint256 rewardAmount = tokenRewards[msg.sender][token];
        require(rewardAmount > 0, "No rewards to claim.");

        tokenRewards[msg.sender][token] = 0;
        // transfer reward to user
        token.safeIncreaseAllowance(address(this), rewardAmount);
        token.safeTransferFrom(address(this), msg.sender, rewardAmount);
        emit RewardChanged(2, msg.sender, token, 0, rewardAmount, block.timestamp);
    }
}
