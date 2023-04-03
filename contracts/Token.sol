// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract Token is ERC1155, Ownable{
    uint[] public ids; //uint array of ids
    string public collectionName; //the token name
    uint public mintFee = 0 wei; 

    // 1 contract = 1 collection
    // 1 collection can have multiple tokens, represented by ids
    // 1 collection shares 1 URI
    constructor(
        string memory _collectionName, 
        string memory _uri, 
        uint[] memory _ids
    )
    Ownable()
    ERC1155(_uri){
        ids = _ids;
        collectionName = _collectionName;
        // transferOwnership(msg.sender);
    }

    function setMintFee(uint _fee) 
    public 
    onlyOwner
    {
        mintFee = _fee;
        console.log(mintFee);
    }

    function mintBatch(
        address _account,
        uint256[] memory _ids
    )
    external
    payable
    onlyOwner
    returns(uint256[] memory)
    {
        console.log("mintBatch() caller: %s", msg.sender);
        console.log("mintBatch() owner: %s", _account);
        require(msg.value == mintFee);
        // amount of all token id = 1
        uint256[] memory amounts = new uint256[](_ids.length);
        for(uint i=0; i<_ids.length; i++){
            amounts[i] = 1;
        }
        _mintBatch(_account, _ids, amounts,"");
        return _ids;
    }

    function countNFT()
    external
    view
    returns (uint){
        return ids.length;
    }

}

