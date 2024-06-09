// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;

contract Form {
    string public name;
    string public description;
    string[] public questions;
    address public creator;
    uint256 public created_at;
    FormRecord[] public formRecords;
    mapping(address => uint256) public formRecordIndex;

    struct FormInfo {
        string name;
        string description;
        string[] questions;
        address creator;
        uint256 created_at;
    }

    struct FormRecord {
        string cid;
        address creator;
        string hash;
    }

    error FormQuestionRequired(uint256 questionIndex);

    constructor(string memory _name, string memory _description, string[] memory _questions) {
        require(bytes(_name).length > 0, "Name is required");
        require(_questions.length > 0, "Questions are required");

        for (uint256 i = 0; i < _questions.length; i++) {
            if (bytes(_questions[i]).length == 0) {
                revert FormQuestionRequired(i);
            }
        }

        name = _name;
        description = _description;
        questions = _questions;
        creator = msg.sender;
        created_at = block.timestamp;
    }

    function getFormInfo() public view returns (FormInfo memory) {
        return FormInfo(name, description, questions, creator, created_at);
    }

    function addFormRecord(string memory cid, string memory hash) public {
        require(formRecordIndex[msg.sender] != 0, "Form record already exists");
        require(bytes(cid).length > 0, "CID is required");
        require(bytes(hash).length > 0, "Hash is required");
        formRecordIndex[msg.sender] = formRecords.length;
        formRecords.push(FormRecord(cid, msg.sender, hash));
    }

    function getFormRecord(uint256 index) public view returns (FormRecord memory) {
        require(index >= 0 && index < formRecords.length, "Form record not found");
        return formRecords[index];
    }

    function getMyFormRecords(uint256 pageNumber, uint256 pageCount) public view returns (FormRecord[] memory myFormRecords, uint256 formRecordCount) {
        require(pageNumber > 0, "Page number should be greater than 0");
        require(pageCount > 0, "Page count should be greater than 0");

        uint256 start = (pageNumber - 1) * pageCount;
        uint256 end = start + pageCount;
        formRecordCount = formRecords.length;
        if (end > formRecordCount) {
            end = formRecordCount;
        }
        if (end - start <= 0) {
            myFormRecords = new FormRecord[](0);
            return (myFormRecords, formRecordCount);
        }
        myFormRecords = new FormRecord[](end - start);
        for (uint256 i = start; i < end; i++) {
            myFormRecords[i - start] = formRecords[i];
        }
    }
}
