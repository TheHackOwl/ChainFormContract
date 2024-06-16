// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";

import {ChainForm} from "../src/ChainForm.sol";
import {IERC20, FormSettings, RewardRule, IRewardLogic} from "../src/FormDefinition.sol";
import {FixedReward} from "../src/Reward.sol";

contract ChainFormTest is Test {
    ChainForm private chainForm;
    FormSettings private formSettings;
    FormSettings private emptyFormSettings;

    // Setup before testing
    function setUp() public {
        chainForm = new ChainForm();
        FixedReward fixedReward = new FixedReward();
        chainForm.addRewardLogic(fixedReward);

        int256[] memory rewardSettings = new int256[](2);
        rewardSettings[0] = 10;
        rewardSettings[1] = 2;
        
        IERC20 token = IERC20(address(0x371C7575c175258a2b450717c7214fe4A264E468));
        RewardRule memory formRules = RewardRule(rewardSettings, token);
        formSettings = FormSettings(formRules, fixedReward);

        int256[] memory emptyRewardSettings = new int256[](0);
        IERC20 emptyToken = IERC20(address(0x0));
        RewardRule memory emptyFormRules = RewardRule(emptyRewardSettings, emptyToken);
        emptyFormSettings = FormSettings(emptyFormRules, IRewardLogic(address(0)));
    }

    // test create form
    function testCreateForm() public {
        string[] memory questions = new string[](2);
        questions[0] = "What is your name?";
        questions[1] = "How old are you?";

        vm.startPrank(address(0x1)); // impersonate user address 0x1
        chainForm.createForm("Survey", "A simple survey.", questions, emptyFormSettings);
        uint256[] memory forms = chainForm.getMyForms();
        assertEq(forms.length, 1);
        vm.stopPrank();
    }

    // test reward form reward.
    function testRewardLogic() public {
        string[] memory questions = new string[](1);
        questions[0] = "Do you like programming?";

        vm.startPrank(address(0x2));
        chainForm.createForm("Tech Survey", "Tech related survey.", questions, formSettings);
        uint256 formId = chainForm.getMyForms()[0];
        
        chainForm.submitForm(formId, "datahash", "cid");
        vm.stopPrank();
    }

    // Test submission form
    function testSubmitForm() public {
        string[] memory questions = new string[](1);
        questions[0] = "Do you like programming?";

        vm.startPrank(address(0x2));
        chainForm.createForm("Tech Survey", "Tech related survey.", questions, emptyFormSettings);
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
        chainForm.createForm("Dev Survey", "Developer survey.", questions, emptyFormSettings);
        uint256 formId = chainForm.getMyForms()[0];

        string memory dataHash = "datahash";
        string memory cid = "cid";
        chainForm.submitForm(formId, dataHash, cid);
        chainForm.submitForm(formId, dataHash, cid); // This commit should fail
        vm.stopPrank();
    }
}
