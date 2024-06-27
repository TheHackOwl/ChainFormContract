// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Registry} from "../src/Registry.sol";
import {ChainForm} from "../src/ChainForm.sol";

contract ChainFormScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        Registry registry = Registry(address(registryAddress));
        ChainForm chainForm = new ChainForm(registry);
        registry.update(address(chainForm));

        vm.stopBroadcast();
    }
}