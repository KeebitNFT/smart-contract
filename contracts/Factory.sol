// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Token.sol";

contract Factory{

    Token[] public tokens;

    event TokenDeployed(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event TokenMinted(address owner, address tokenContract, uint amount); //emmited when ERC1155 token is minted

    function createNFT(
        string memory contractName, 
        string memory uri, 
        uint[] memory ids
    )
    public
    returns(address){
        // deploy contract
        Token t = new Token(contractName, uri, ids);
        tokens.push(t);
        emit TokenDeployed(msg.sender,address(t));

        //mint NFT
        _mintNFT(t, ids);
        return address(t);

    }

    function _mintNFT(
        Token token,
        uint[] memory ids
        ) 
    private {
        token.mintBatch(token.owner(), ids);
        emit TokenMinted(token.owner(), address(token), ids.length);
    }

}