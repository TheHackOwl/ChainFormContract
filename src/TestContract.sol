// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

// 合约 A 包含状态变量和一个可能会被 B 通过 delegatecall 调用的方法
contract A {
    uint256 public value;
    mapping(uint256 => uint256) public balance;

    function setValue(uint256 _value) public {
        value = _value;
    }

    function setBalance(uint256 _key, uint256 _value) public {
        balance[_key] = _value;
    }
}

// 合约 B 调用 A 的 setValue 函数，但操作的是 B 的存储
contract B {
    uint256 public value;
    mapping(uint256 => uint256) public balance;
    address public aAddress;

    constructor(address _aAddress) {
        aAddress = _aAddress;
    }

    function callSetValue(uint256 _value) public {
        (bool success, ) = aAddress.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        require(success, "delegatecall failed");
    }

    function callSetBalance(uint256 _key, uint256 _value) public {
        (bool success, ) = aAddress.delegatecall(
            abi.encodeWithSignature("setBalance(uint256,uint256)", _key, _value)
        );
        require(success, "delegatecall failed");
    }
}
