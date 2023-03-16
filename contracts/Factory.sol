// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Token.sol";
import "./Marketplace.sol";

contract Factory{

    Marketplace market;
    Token[] public tokens;

    event TokenDeployed(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event TokenMinted(address owner, address tokenContract, uint amount); //emmited when ERC1155 token is minted

    function createAndList(
        string memory _contractName, 
        string memory _uri, 
        uint[] memory _ids,
        uint _price
    )
    public
    returns(address){
        // deploy contract
        Token tokenContract = new Token(_contractName, _uri, _ids);
        tokens.push(tokenContract);
        emit TokenDeployed(msg.sender,address(tokenContract));

        //mint NFT
        _mintNFT(tokenContract, _ids);

        //list NFT
        for(uint i=0; i<_ids.length; i++){
            market.listNFT(tokenContract, _ids[i], _price);
        }
        return address(tokenContract);

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