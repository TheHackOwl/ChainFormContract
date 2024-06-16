// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {A, B} from "../src/TestContract.sol";


contract TestContractTest is Test {
    A private a;
    B private b;

    // Setup before testing
    function setUp() public {
        a = new A();
        b = new B(address(a));
    }

    // test call setValue
    function testCallSetValue() public {
        b.callSetValue(10);
        assertEq(b.value(), uint256(10));
    }

    // test callSetBalance
    function testCallSetBalance() public {
        b.callSetBalance(1, 100);
        assertEq(b.balance(1), uint256(100));
    }
}