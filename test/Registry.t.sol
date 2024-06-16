// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";


contract RegistryTest is Test {
    Registry private registry;

    // Setup before testing
    function setUp() public {
        registry = new Registry();
    }

    // test update registry
    function testUpdateRegistry() public {
        registry.update(address(0x1));
        assertEq(registry.get(), address(0x1));
    }

    // test update fail with non-owner
    function testFailUpdateRegistry() public {
        vm.startPrank(address(0x2));
        registry.update(address(0x2));
        assertEq(registry.get(), address(0x2));
        vm.stopPrank();
    }
}
