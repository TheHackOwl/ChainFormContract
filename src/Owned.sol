// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Owned {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}
