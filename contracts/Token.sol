// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract Token is ERC1155, Ownable {
    uint[] public ids; //uint array of ids
    string public name; //the token name
    address public vendorAddress;

    // 1 contract = 1 collection
    // 1 collection can have multiple tokens, represented by ids
    // 1 collection shares 1 URI
    constructor(
        string memory _name,
        string memory _uri,
        uint[] memory _ids,
        address _vendorAddress
    ) Ownable() ERC1155(_uri) {
        ids = _ids;
        name = _name;
        vendorAddress = _vendorAddress;
    }

    function mintBatch(
        address _account,
        uint256[] memory _ids
    ) external payable onlyOwner returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            amounts[i] = 1;
        }
        _mintBatch(_account, _ids, amounts, "");
        return _ids;
    }

    function countNFT() external view returns (uint) {
        return ids.length;
    }
}
