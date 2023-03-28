// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Token.sol";
import "./Marketplace.sol";
import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Factory is ERC1155Holder{

    Marketplace market;
    Token[] public tokens;
    address public owner;

    event TokenDeployed(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event TokenMinted(address owner, address tokenContract, uint amount); //emmited when ERC1155 token is minted

    constructor(address _marketplace){
        market = Marketplace(_marketplace);
        owner = msg.sender;
    }
    function createAndList(
        string memory _contractName, 
        string memory _uri, 
        uint[] memory _ids,
        uint _price
    )
    external
    returns(address){
        // deploy contract
        Token tokenContract = new Token(_contractName, _uri, _ids);
        tokens.push(tokenContract);
        emit TokenDeployed(msg.sender,address(tokenContract));

        console.log("============= owners ============="); 
        console.log("marketplace contract owner: %s",  market.owner());
        console.log("factory contract owner: %s", this.owner());
        console.log("token contract owner: %s", tokenContract.owner());

        console.log("============= addresses ============="); 
        console.log("token contract address: %s", address(tokenContract));
        console.log("factory contract address: %s", address(this));
        console.log("marketplace contract address: %s", address(market));

        console.log("============= callers =============");
        console.log("factory contract caller: %s", msg.sender);

        //mint NFT
        _mintNFT(tokenContract, _ids);

        //list NFT
        for(uint i=0; i<_ids.length; i++){
            console.log("============= enters listNFT loop =============");
            market.listNFT(tokenContract, tokenContract.owner(), _ids[i], _price);
            console.log("token id: %s", _ids[i]);
            console.log("============= ends listNFT loop =============");
        }
        return address(tokenContract); 

    }

    function _mintNFT(
        Token _token,
        uint[] memory _ids
        ) 
    private {
        _token.mintBatch(_token.owner(), _ids, address(market));
        // _token.setApprovalForAll(address(market), true);
        console.log("balance of %s for id %s = %s", _token.owner(), _ids[0], _token.balanceOf(_token.owner(), _ids[0]));
        emit TokenMinted(_token.owner(), address(_token), _ids.length);
    }

    


}
