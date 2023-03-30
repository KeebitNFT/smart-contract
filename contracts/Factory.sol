// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";
import "hardhat/console.sol";

contract Factory {

    Token[] public tokens;
    mapping(Token => bool) public isToken;
    mapping(address => bool) public isVendor;
    mapping(address => bool) public isPeer;

    event TokenDeployed(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event TokenMinted(address owner, address tokenContract, uint amount); //emmited when ERC1155 token is minted

    // add restriction to keebit frontend
    function saveVendor(address _vendor) 
    external{
        isVendor[_vendor] = true;
    }

    /// add restriction to keebit frontend
    function savePeer(address _peer)
    external{
        isPeer[_peer] = true;
    }   

    function createNFT(
        string memory _contractName, 
        string memory _uri, 
        uint[] memory _ids
    )
    external
    returns(address){
        require(isVendor[msg.sender] , "Only a valid vendor can create NFT");
        // deploy contract
        Token tokenContract = new Token(_contractName, _uri, _ids);
        tokens.push(tokenContract);
        isToken[tokenContract] = true;
        emit TokenDeployed(msg.sender,address(tokenContract));

        console.log("============= owners ============="); 
        console.log("token contract owner: %s", tokenContract.owner());

        console.log("============= addresses ============="); 
        console.log("token contract address: %s", address(tokenContract));
        console.log("factory contract address: %s", address(this));

        console.log("============= callers =============");
        console.log("factory contract caller: %s", msg.sender);

        //mint NFT
        _mintNFT(tokenContract, _ids);

        return(address(tokenContract));
    }

    function _mintNFT(
        Token _token,
        uint[] memory _ids
        ) 
    private {
        _token.mintBatch(msg.sender, _ids);
        console.log("balance of %s for id %s = %s", msg.sender, _ids[0], _token.balanceOf(msg.sender, _ids[0]));
        emit TokenMinted(msg.sender, address(_token), _ids.length);
    }

    function getMyNFTs()
    external
    view
    returns(address[] memory){
        for(uint i=0;i<tokens.length;i++){
            tokens[i].balanceOf(msg.sender, 0);
            
        }
        return ;
    }

    


}
