// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "hardhat/console.sol";
import "./Factory.sol";
import "./Token.sol";

contract Marketplace is ReentrancyGuard{
    uint private itemCount; // # item ever been listed
    uint private itemOnList; // # item currently listed
    address payable public immutable owner;
    uint public immutable feePercent; // transaction fee, no listing fee
    Factory public factory;

    struct NFT{
        uint itemId;
        Token nftContract;
        uint tokenId;
        uint price;
        address payable seller;
        address payable owner;
        bool isOfficial;
        bool isOnList;
    }
    mapping(uint => NFT) public nfts;

    event NFTListed(
        uint itemId,
        Token nftContract,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTUnlisted(
        uint itemId,
        Token nftContract,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTSold(
        uint itemId,
        Token nftContract,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
        );

    constructor(uint _feePercent){
        owner = payable(msg.sender);
        feePercent = _feePercent;
    }

    
    // list nft or NFTs
    function listNFT(Token _nftContract, uint[] memory _tokenIds, uint _price) 
    external
    nonReentrant
    returns(address){
        require(factory.isToken(_nftContract), "Only a valid token contract can be listed");
        require(factory.isVendor(msg.sender) || factory.isPeer(msg.sender), "Only valid accounts can list NFT");
        require(_tokenIds.length > 0, "No token id provided");
        require(_price > 0, "Price must be at least 1 wei");

        for(uint i=0; i<_tokenIds.length; i++){
            _list(_nftContract, _tokenIds[i], _price);
            // console.log("token id: %s", _tokenIds[i]);
        }
        return address(_nftContract);
    }

    function _list(Token _nftContract, uint _tokenId, uint _price) 
    private{

        _nftContract.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        itemCount++;
        itemOnList++;
        // check if lister is vendor or peer
        bool _isOfficial = factory.isVendor(msg.sender) ? true : false;
        bool _isOnlist = true;
        nfts[itemCount] = NFT(
            itemCount,
            _nftContract,
            _tokenId,
            _price,
            payable(msg.sender),
            payable(address(this)),
            _isOfficial,
            _isOnlist
        );
        emit NFTListed(
            itemCount,
            _nftContract, 
            _tokenId, 
            _price, 
            msg.sender,
            address(this)
        );
        
    }

    //buy nft
    function buyNFT(uint _itemId) 
    external 
    payable 
    nonReentrant{
        uint _totalPrice = _getTotalPrice(_itemId);
        NFT storage nft = nfts[_itemId];
        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        require(nft.isOnList, "item is not for sale");
        require(msg.value >= _totalPrice, "not enough ether for this transaction");
        //pay seller and owner
        nft.seller.transfer(nft.price);
        owner.transfer(_totalPrice - nft.price);
        //transfer nft to buyer
        address payable buyer = payable(msg.sender);
        nft.nftContract.safeTransferFrom(address(this), buyer, nft.tokenId, 1, "");
        //update nft info
        nft.owner = buyer;
        nft.isOnList = false;

        itemOnList--;
        emit NFTSold(
            _itemId,
            nft.nftContract, 
            nft.tokenId, 
            msg.value,
            nft.seller,
            nft.owner  
        );

    }

    function unlistNFT(Token _nftContract, uint _itemId)
    payable
    external
    nonReentrant{
        NFT storage nft = nfts[_itemId];
        require(nft.isOnList, "item is not listed");
        _nftContract.safeTransferFrom(address(this), msg.sender, nft.tokenId, 1, "");
        itemOnList--;

        nft.seller = payable(address(this));
        nft.owner = payable(msg.sender);
        nft.isOnList = false;

        emit NFTUnlisted(
        _itemId,
        _nftContract,
        nft.tokenId,
        nft.price,
        nft.seller,
        nft.owner
    );
    }

    // total = nft price + transaction fee
    function _getTotalPrice(uint _itemId) 
    internal
    view  
    returns(uint){
        return(nfts[_itemId].price*(100+feePercent));
    }

    // get all currently listed NFTs on the marketplace
    function getListedNFTs() 
    external 
    view  
    returns (NFT[] memory){

        NFT[] memory listedNFTs = new NFT[](itemOnList);
        uint nftIndex = 0;
        for (uint i = 0; i < itemCount; i++){
            if(nfts[i+1].isOnList){
                listedNFTs[nftIndex] = nfts[i+1];
                nftIndex++;
            }
        }
        return(listedNFTs);
    }

    // get all my NFTs
    // move to Factory
    // function getMyNFTs() 
    // external 
    // view 
    // returns (NFT[] memory){
    //     uint myNFTCount = 0;
    //     for (uint i = 0; i < itemCount; i++){
    //         if( nfts[i+1].owner == msg.sender){
    //             myNFTCount++;
    //         }
    //     }

    //     NFT[] memory myNFTs = new NFT[](myNFTCount);
    //     uint nftIndex = 0;
    //     for (uint i = 0; i < itemCount; i++){
    //         if( nfts[i+1].owner == msg.sender){
    //             myNFTs[nftIndex] = nfts[i+1];
    //             nftIndex++;
    //         }
    //     }
    //     return(myNFTs);
    // }

    // get all my listed NFTs
    function getMyListedNFTs() 
    external 
    view 
    returns(NFT[] memory){
        uint myListedNFTCount = 0;
        for (uint i = 0; i < itemCount; i++){
            if( nfts[i+1].seller == msg.sender && nfts[i+1].isOnList){
                myListedNFTCount++;
            }
        }

        NFT[] memory myListedNFTs = new NFT[](myListedNFTCount);
        uint nftIndex = 0;
        for (uint i = 0; i < itemCount; i++){
            if( nfts[i+1].seller == msg.sender && nfts[i+1].isOnList){
                myListedNFTs[nftIndex] = nfts[i+1];
                nftIndex++;
            }
        }
        return(myListedNFTs);
    }

    function updatePrice(uint _itemId, uint _newPrice)
    external
    returns (uint)
    {
        require(_newPrice > 0, "Price must be at least 1 wei");
        nfts[_itemId].price = _newPrice;
        return(_newPrice);
    }
}
