// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ChainForm} from "../src/ChainForm.sol";
import {console} from "forge-std/Console.sol";

contract ChainFormTest is Test {
    ChainForm private chainForm;

    // Setup before testing
    function setUp() public {
        chainForm = new ChainForm();
    }

    // test create form
    function testCreateForm() public {
        string[] memory questions = new string[](2);
        questions[0] = "What is your name?";
        questions[1] = "How old are you?";

        vm.startPrank(address(0x1)); // impersonate user address 0x1
        chainForm.createForm("Survey", "A simple survey.", questions);
        uint256[] memory forms = chainForm.getMyForms();
        assertEq(forms.length, 1);
        vm.stopPrank();
    }

    // Test submission form
    function testSubmitForm() public {
        string[] memory questions = new string[](1);
        questions[0] = "Do you like programming?";

        vm.startPrank(address(0x2));
        chainForm.createForm("Tech Survey", "Tech related survey.", questions);
        uint256 formId = chainForm.getMyForms()[0];

        string memory dataHash = "datahash";
        string memory cid = "cid";
        chainForm.submitForm(formId, dataHash, cid);
        assertEq(chainForm.getSubmissions(formId).length, 1);
        vm.stopPrank();
    }

    // testing for repeated form submissions
    function testFailSubmitFormTwice() public {
        string[] memory questions = new string[](1);
        questions[0] = "Do you like Solidity?";

        vm.startPrank(address(0x3));
        chainForm.createForm("Dev Survey", "Developer survey.", questions);
        uint256 formId = chainForm.getMyForms()[0];

        string memory dataHash = "datahash";
        string memory cid = "cid";
        chainForm.submitForm(formId, dataHash, cid);
        chainForm.submitForm(formId, dataHash, cid); // This commit should fail
        vm.stopPrank();
    }
}
