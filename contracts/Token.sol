// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Token is ERC1155, Ownable{
    string[] public names; //string array of names
    uint[] public ids; //uint array of ids
    string public baseMetadataURI; //the token metadata URI
    string public tokenName; //the token mame
    uint public mintFee = 0 wei; //mintfee, 0 by default. only used in mint function, not batch.

    mapping(string => uint) public nameToId; //name to id mapping
    mapping(uint => string) public idToName; //id to name mapping

    // 1 contract = 1 collection
    // 1 collection can have multiple tokens, represented by names -> ids
    // 1 collection shares 1 base URI, each token in a collection has a unique URI: base URI + token id
    constructor(
        string memory contractName, 
        string memory uri, 
        string[] memory names, 
        uint[] memory ids
    )ERC1155(uri){
        names = names;
        ids = ids;
        _createMapping();
        setURI(uri);
        baseMetadataURI = uri;
        tokenName = contractName;
        transferOwnership(tx.origin);
    }

    function _createMapping() 
    private{
        for (uint id = 0; id < ids.length; id++) {
            nameToId[names[id]] = ids[id];
            idToName[ids[id]] = names[id];
        }
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
    function mint(
        address account,
        uint256 id,
        uint256 amount 
    )
    public
    payable 
    returns(uint256){
        require(msg.value == mintFee);
        //_mint(address account, uint256 id, uint256 amount, bytes data)
        _mint(account, id, amount, "");
        return id;
    }

    function mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    )
    public
    payable
    returns(uint256[] memory)
    {
        require(msg.value == mintFee*ids.length);
        // _mintBacth(address to, uint256[] ids, uint256[] amounts, bytes data)
        _mintBatch(account, ids, amounts,"");
        return ids;
    }
}

