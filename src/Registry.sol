// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

import {Owned} from "./Owned.sol";

contract Registry is Owned {
    address private current;

    constructor() Owned(){

    }

    event Updated(
        address indexed current
    );

    function update(address _contract) public onlyOwner {
        current = _contract;
        
        emit Updated(current);
    }

    function get() public view returns (address) {
        return current;
    }
}
