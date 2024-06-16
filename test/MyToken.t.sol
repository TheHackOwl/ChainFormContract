// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        token = new MyToken(10000 ether);
        vm.prank(address(this));
        token.transfer(alice, 800 ether);
        token.transfer(bob, 200 ether);
    }

    function testInitialBalance() public {
        assertEq(token.balanceOf(alice), 800 ether);
        assertEq(token.balanceOf(bob), 200 ether);
    }

    function testTransfer() public {
        vm.prank(bob);
        token.transfer(alice, 100 ether);
        assertEq(token.balanceOf(alice), 900 ether);
        assertEq(token.balanceOf(bob), 100 ether);
    }
}
