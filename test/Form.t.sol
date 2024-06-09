// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Form.sol";

contract FormTest is Test {
    Form public form;

    function setUp() public {
        string[] memory questions = new string[](1);
        questions[0] = "What is your name?";
        form = new Form("Test Form", "This is a test form", questions);
    }

    function test_GetFormInfo() public view {
        Form.FormInfo memory formInfo = form.getFormInfo();
        assertEq(formInfo.name, "Test Form");
        assertEq(formInfo.description, "This is a test form");
        assertEq(formInfo.questions.length, 1);
    }

    function test_AddFormRecord() public {
        form.addFormRecord(1, "hash");
        Form.FormRecord memory formRecord = form.getFormRecord(0);
        assertEq(formRecord.cid, 1);
        assertEq(formRecord.hash, "hash");
    }
}
