// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage{
    uint public tokenCount;
    address marketplaceContract;

    constructor(address _marketplaceContract) ERC721("Keebit NFT", "Keebit"){
        marketplaceContract = _marketplaceContract;
    }

    function mint(string memory _tokenURI) external returns(uint){
        tokenCount++;
        _safeMint(msg.sender, tokenCount);
        _setTokenURI(tokenCount, _tokenURI);
        setApprovalForAll(marketplaceContract, true);
        return(tokenCount);
    }
}