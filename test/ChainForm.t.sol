// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {MyToken} from "../src/MyToken.sol";
import {ChainForm} from "../src/ChainForm.sol";
import {FormSettings, RewardRule, IRewardLogic, Form} from "../src/FormDefinition.sol";
import {FixedReward} from "../src/Reward.sol";
import {Registry} from "../src/Registry.sol";

contract ChainFormTest is Test {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    ChainForm private chainForm;
    FormSettings private formSettings;
    FormSettings private emptyFormSettings;
    IERC20 private token;
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address charlie = vm.addr(3);

    // Setup before testing
    function setUp() public {
        Registry registry = new Registry();
        chainForm = new ChainForm(registry);
        FixedReward fixedReward = new FixedReward();
        registry.addRewardContract(fixedReward);

        int256[] memory rewardSettings = new int256[](2);
        rewardSettings[0] = 10;
        rewardSettings[1] = 2;
        
        token = IERC20(address(new MyToken(10000 ether)));
        token.transfer(bob, 1000 ether);

        RewardRule memory formRules = RewardRule(rewardSettings, token);
        formSettings = FormSettings(formRules, fixedReward, 0);

        int256[] memory emptyRewardSettings = new int256[](0);
        IERC20 emptyToken = IERC20(address(0x0));
        RewardRule memory emptyFormRules = RewardRule(emptyRewardSettings, emptyToken);
        emptyFormSettings = FormSettings(emptyFormRules, IRewardLogic(address(0)), 0);
    }

    // test create form
    function testCreateForm() public {
        string[] memory questions = new string[](2);
        questions[0] = "What is your name?";
        questions[1] = "How old are you?";

        vm.startPrank(alice); // impersonate user address 0x1
        chainForm.createForm("Survey", "A simple survey.", questions, emptyFormSettings);
        uint256[] memory forms = chainForm.getMyForms();
        assertEq(forms.length, 1);
        vm.stopPrank();
    }

    // test reward form reward.
    function testRewardLogic() public {
        string[] memory questions = new string[](1);
        questions[0] = "Do you like programming?";

        vm.startPrank(bob);
        // approve
        token.safeIncreaseAllowance(address(chainForm), 1 ether);
        assertTrue(token.allowance(bob, address(chainForm)) >= 1 ether);
        
        chainForm.createForm("Tech Survey", "Tech related survey.", questions, formSettings);
        assertEq(token.balanceOf(bob), 1000 ether - 20);
        assertEq(token.balanceOf(address(chainForm)), 20);
        
        uint256 formId = chainForm.getMyForms()[0];
        vm.stopPrank();
        vm.startPrank(alice);
        chainForm.submitForm(formId, "datahash", "cid");

        uint256 amount = chainForm.getRewards(token);
        assertEq(amount, 10);
        
        chainForm.claim(token);
        assertEq(token.balanceOf(alice), 10);
        assertEq(chainForm.getRewards(token), 0);
        vm.stopPrank();
    }

    // Test submission form
    function testSubmitForm() public {
        string[] memory questions = new string[](1);
        questions[0] = "Do you like programming?";

        vm.startPrank(bob);
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

        vm.startPrank(charlie);
        chainForm.createForm("Dev Survey", "Developer survey.", questions, emptyFormSettings);
        uint256 formId = chainForm.getMyForms()[0];

        string memory dataHash = "datahash";
        string memory cid = "cid";
        chainForm.submitForm(formId, dataHash, cid);
        chainForm.submitForm(formId, dataHash, cid); // This commit should fail
        vm.stopPrank();
    }

    function testGetFormsByPage() public {
        string[] memory questions = new string[](1);
        questions[0] = "Do you like Solidity?";
        // Create 5 forms
        for(uint i = 0; i < 5; i++) {
            string memory title = string(abi.encodePacked("Form", i.toString()));
            chainForm.createForm(title, "Description", questions, emptyFormSettings);
        }

        // Get the first page with 2 forms per page
        Form[] memory forms = chainForm.getFormsByPage(1, 2);
        assertEq(forms.length, 2);

        assertEq(forms[0].name, "Form4");
        assertEq(forms[1].name, "Form3");

        // Get the second page with 2 forms per page
        forms = chainForm.getFormsByPage(2, 2);
        assertEq(forms.length, 2);
        assertEq(forms[0].name, "Form2");
        assertEq(forms[1].name, "Form1");

        // Get the third page with 2 forms per page
        forms = chainForm.getFormsByPage(3, 2);
        assertEq(forms.length, 1);
        assertEq(forms[0].name, "Form0");

        // Get the fourth page with 2 forms per page
        forms = chainForm.getFormsByPage(4, 2);
        assertEq(forms.length, 0);
    }
}
