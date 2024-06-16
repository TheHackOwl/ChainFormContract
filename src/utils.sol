// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

library RevertReasonParser {
    // Parse error information
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the return data is empty, it means there is no error message
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Remove the array prefix
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // Decode and return the error message
    }
}
