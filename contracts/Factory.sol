// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Token.sol";

contract Factory{

    Token[] public tokens;

    event TokenDeployed(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event TokenMinted(address owner, address tokenContract, uint amount); //emmited when ERC1155 token is minted

    function createNFT(
        string memory _contractName, 
        string memory _uri, 
        uint[] memory _ids
    )
    public
    returns(address){
        // deploy contract
        Token t = new Token(_contractName, _uri, _ids);
        tokens.push(t);
        emit TokenDeployed(msg.sender,address(t));

        //mint NFT
        _mintNFT(t, _ids);
        return address(t);

    }

    function _mintNFT(
        Token _token,
        uint[] memory _ids
        ) 
    private {
        _token.mintBatch(_token.owner(), _ids);
        emit TokenMinted(_token.owner(), address(_token), _ids.length);
    }

}