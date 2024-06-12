// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {Owned} from "./Owned.sol";

contract Registry is Owned {
    address private current;
    address[] private previous;

    constructor() Owned(){

    }

    function update(address _contract) public onlyOwner {
        current = _contract;
        previous.push(current);
    }

    function get() public view returns (address) {
        return current;
    }
}
