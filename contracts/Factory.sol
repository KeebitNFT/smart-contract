// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Token.sol";

contract Factory{

    Token[] public tokens;

    mapping(uint256 => address) public indexToContract; 
    mapping(uint256 => address) public indexToOwner;

    event TokenCreated(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event TokenMinted(address owner, address tokenContract, uint amount); //emmited when ERC1155 token is minted

    function deploy(
        string memory contractName, 
        string memory uri, 
        string[] memory names, 
        uint[] memory ids
    )
    public
    returns(address){
        Token t = new Token(contractName, uri, names, ids);
        tokens.push(t);
        indexToContract[tokens.length - 1] = address(t);
        indexToOwner[tokens.length - 1] = tx.origin;
        emit TokenCreated(msg.sender,address(t));
        return address(t);

    }
    // to fix:
    // replace index with address, access mint in Token contract through address
    function mintSingle(
        uint index, 
        string memory name, 
        uint256 amount
        ) 
    public {
        uint id = getIdByName(index, name);
        tokens[index].mint(indexToOwner[index], id, amount);
        emit TokenMinted(tokens[index].owner(), address(tokens[index]), amount);
    }

    function getIdByName(uint index, string memory name)
    public
    view
    returns (uint){
        return tokens[index].nameToId(name);
    }
}