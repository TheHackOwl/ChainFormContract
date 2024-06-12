// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

contract ChainForm {
    struct Form {
        address creator;
        uint256 createdAt;
        string name;
        string description;
        string[] questions;
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
    function createForm(string memory _name, string memory _description, string[] memory _questions) public {
        uint256 formId = forms.length;
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
}
