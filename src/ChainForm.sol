// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {Form, Submission, FormSettings, IRewardLogic} from "./FormDefinition.sol";

contract ChainForm {
    Form[] private forms;
    mapping(uint256 => Submission[]) private submissions; // Mapping from form ID to submissions
    mapping(address => uint256[]) private userForms; // Mapping from user address to list of form IDs
    mapping(uint256 => mapping(address => bool)) private hasSubmitted; // Mapping to check if a user has submitted a form
    mapping(uint256 => IRewardLogic) private rewardLogics;


    // @title Create a new form
    function createForm(string memory _name, string memory _description, string[] memory _questions, FormSettings memory _formSettings) public returns (uint256 formId) {
        formId = forms.length;
        forms.push(Form(msg.sender, block.timestamp, _name, _description, _questions));
        userForms[msg.sender].push(formId);
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
    function submitForm(uint256 _formId, string memory _dataHash, string memory _cid) public returns (uint256 submissionId) {
        require(_formId < forms.length, "Form does not exist.");
        require(!hasSubmitted[_formId][msg.sender], "You have already submitted this form.");
        submissionId = submissions[_formId].length;
        submissions[_formId].push(Submission(_dataHash, _cid, msg.sender, block.timestamp));
        hasSubmitted[_formId][msg.sender] = true;
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
