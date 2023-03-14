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

    constructor(
        string memory _contractName, 
        string memory _uri, 
        string[] memory _names, 
        uint[] memory _ids
    )ERC1155(_uri){
        names = _names;
        ids = _ids;
        createMapping();
        setURI(_uri);
        baseMetadataURI = _uri;
        tokenName = _contractName;
        transferOwnership(tx.origin);
    }

    function createMapping() 
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

