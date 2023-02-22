// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Marketplace is ReentrancyGuard{
    uint private nftCount;
    uint private nftSold;
    address payable public immutable marketOwner;
    uint public immutable feePercent; // transaction fee, no listing fee

    struct NFT{
        IERC721 nftContract;
        uint tokenId;
        uint price;
        address payable seller;
        address payable owner;
        bool isSold;
    }
    mapping(uint => NFT) public nfts;

    event NFTListed(
        IERC721 nftContract,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTSold(
        IERC721 nftContract,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
        );

    constructor(uint _feePercent){
        marketOwner = payable(msg.sender);
        feePercent = _feePercent;
    }
    // list nft on marketplace
    function listNFT(IERC721 _nftContract, uint _tokenId, uint _price) 
    external 
    nonReentrant{
        require(_price > 0, "Price must be at least 1 wei");
        _nftContract.transferFrom(msg.sender, address(this), _tokenId);
        nftCount++;
        nfts[_tokenId] = NFT(
            _nftContract,
            _tokenId,
            _price,
            payable(msg.sender),
            payable(address(this)),
            false
        );
        emit NFTListed(
            _nftContract, 
            _tokenId, 
            _price, 
            msg.sender,
            address(this)
        );
        
    }
    //buy nft
    function buyNFT(uint _tokenId) 
    external 
    payable 
    nonReentrant{
        uint _totalPrice = getTotalPrice(_tokenId);
        NFT storage nft = nfts[_tokenId];
        require(_tokenId > 0 && _tokenId <= nftCount, "item doesn't exist");
        require(msg.value >= _totalPrice, "not enough ether for this transaction");
        require(!nft.isSold, "item is already sold");
        //pay seller and marketOwner
        nft.seller.transfer(nft.price);
        marketOwner.transfer(_totalPrice - nft.price);
        //transfer nft to buyer
        address payable buyer = payable(msg.sender);
        nft.nftContract.transferFrom(address(this), buyer, nft.tokenId);
        //update nft info
        nft.owner = buyer;
        nft.isSold = true;

        nftSold++;
        emit NFTSold(
            nft.nftContract, 
            nft.tokenId, 
            msg.value,
            nft.seller,
            nft.owner  
        );

    }
    // resell nft purchased from marketplace
    function relistNFT(IERC721 _nftContract, uint _tokenId, uint _price) 
    external 
    payable 
    nonReentrant{
        require(_price > 0, "Price must be at least 1 wei");
        _nftContract.transferFrom(msg.sender, address(this), _tokenId);
    }
    function getTotalPrice(uint _tokenId) 
    view 
    public 
    returns(uint){
        return(nfts[_tokenId].price*(100+feePercent));
    }
}
