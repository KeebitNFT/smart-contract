// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Token is ERC1155, Ownable{
    uint[] public ids; //uint array of ids
    string public baseMetadataURI; //the token metadata URI
    string public tokenName; //the token mame
    uint public mintFee = 0 wei; //mintfee, 0 by default. only used in mint function, not batch.

    // 1 contract = 1 collection
    // 1 collection can have multiple tokens, represented by ids
    // 1 collection shares 1 base URI, each token in a collection has a unique URI: base URI + token id
    constructor(
        string memory contractName, 
        string memory uri, 
        uint[] memory ids
    )ERC1155(uri){
        ids = ids;
        setURI(uri);
        baseMetadataURI = uri;
        tokenName = contractName;
        transferOwnership(tx.origin);
    }

    function setURI(string memory uri) 
    public 
    onlyOwner{
        _setURI(uri);
    }

    function setMintFee(uint fee) 
    public 
    onlyOwner{
        mintFee = fee;
    }
    // amount = 1
    // function mint(
    //     address account,
    //     uint256 id,
    //     uint256 amount 
    // )
    // public
    // payable 
    // returns(uint256){
    //     require(msg.value == mintFee);
    //     //_mint(address account, uint256 id, uint256 amount, bytes data)
    //     _mint(account, id, amount, "");
    //     return id;
    // }

    function mintBatch(
        address account,
        uint256[] memory ids
    )
    public
    payable
    returns(uint256[] memory)
    {
        require(msg.value == mintFee*ids.length);
        // amount of all token id = 1
        uint256[] memory amounts = new uint256[](ids.length);
        for(uint i=0; i<ids.length; i++){
            amounts[i] = 1;
        }
        _mintBatch(account, ids, amounts,"");
        return ids;
    }
}

