// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import "./Form.sol";

contract FormManager {
    struct FormRecord {
        uint256 formId;
        address creator;
    }


    mapping(address => uint256[]) public formsByCreator;

    // Array of forms
    Form[] public forms;

    function createForm(string memory name, string memory description, string[] memory questions) public {
        Form form = new Form(name, description, questions);
        formsByCreator[msg.sender].push(forms.length);
        forms.push(form);
    }

    function getForm(uint256 index) public view returns (Form) {
        require(index >= 0 && index < forms.length, "Form not found");
        return forms[index];
    }

    function getMyForms(uint256 pageNumber, uint256 pageCount) public view returns (Form.FormInfo[] memory myForms, uint256 formCount) {
        require(pageNumber > 0, "Page number should be greater than 0");
        require(pageCount > 0, "Page count should be greater than 0");

        uint256 start = (pageNumber - 1) * pageCount;
        uint256 end = start + pageCount;
        uint256[] memory formIds = formsByCreator[msg.sender];
        formCount = formIds.length;
        if (end > formCount) {
            end = formCount;
        }
        if (end - start <= 0) {
            myForms = new Form.FormInfo[](0);
            return (myForms, formCount);
        }
        myForms = new Form.FormInfo[](end - start);
        for (uint256 i = start; i < end; i++) {
            myForms[i - start] = getForm(formIds[i]).getFormInfo();
        }
    }
}

