// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {Registry} from "./Registry.sol";

contract ChainForm {
    struct Form {
        address creator;
        uint256 createdAt;
        string name;
        string description;
        string[] questions;
    }

    function _getRevertMsg(bytes memory returnData) internal pure returns (string memory) {
        // If the return data length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return 'Transaction reverted silently';

        assembly {
        // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }

    struct Submission {
        string dataHash;
        string cid;
        address submitter;
        uint256 submittedAt;
    }

    Form[] private forms;
    mapping(uint256 => Submission[]) private submissions; // Mapping from form ID to submissions
    mapping(address => uint256[]) private userForms; // Mapping from user address to list of form IDs
    mapping(uint256 => mapping(address => bool)) private hasSubmitted; // Mapping to check if a user has submitted a form

    // Create a new form
    function createForm(string memory _name, string memory _description, string[] memory _questions) public returns (uint256 formId) {
        formId = forms.length;
        forms.push(Form(msg.sender, block.timestamp, _name, _description, _questions));
        userForms[msg.sender].push(formId);
    }

    // Get forms by creator
    function getMyForms() public view returns (uint256[] memory) {
        return userForms[msg.sender];
    }

    function getForm(uint256 _formId) public view returns (Form memory) {
        require(_formId < forms.length, "Form does not exist.");
        return forms[_formId];
    }

    // Submit form responses
    function submitForm(uint256 _formId, string memory _dataHash, string memory _cid) public {
        require(_formId < forms.length, "Form does not exist.");
        require(!hasSubmitted[_formId][msg.sender], "You have already submitted this form.");
        submissions[_formId].push(Submission(_dataHash, _cid, msg.sender, block.timestamp));
        hasSubmitted[_formId][msg.sender] = true;
    }

    // Get submissions for a form
    function getSubmissions(uint256 _formId) public view returns (Submission[] memory) {
        require(_formId < forms.length, "Form does not exist.");
        return submissions[_formId];
    }

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
