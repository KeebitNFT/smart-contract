// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract Marketplace is ReentrancyGuard{
    uint private itemCount; // # item ever been listed
    uint private itemOnList; // # item currently listed (have not beem unlisted)
    uint private itemSold;
    address payable public immutable marketOwner;
    uint public immutable feePercent; // transaction fee, no listing fee

    struct NFT{
        uint itemId;
        IERC1155 nftContract;
        uint tokenId;
        uint price;
        address payable seller;
        address payable owner;
        bool isSold;
        bool isOfficial;
        bool isOnList;
    }
    mapping(uint => NFT) public nfts;

    event NFTListed(
        uint itemId,
        IERC1155 nftContract,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTUnlisted(
        uint itemId,
        IERC1155 nftContract,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTSold(
        uint itemId,
        IERC1155 nftContract,
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
    function listNFT(IERC1155 _nftContract, uint _tokenId, uint _price) 
    external 
    nonReentrant{
        require(_price > 0, "Price must be at least 1 wei");
        _nftContract.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        itemCount++;
        itemOnList++;
        // set itemCount as key
        nfts[itemCount] = NFT(
            itemCount,
            _nftContract,
            _tokenId,
            _price,
            payable(msg.sender),
            payable(address(this)),
            false,
            true,
            true
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
        require(msg.value >= _totalPrice, "not enough ether for this transaction");
        require(!nft.isSold, "item is already sold");
        //pay seller and marketOwner
        nft.seller.transfer(nft.price);
        marketOwner.transfer(_totalPrice - nft.price);
        //transfer nft to buyer
        address payable buyer = payable(msg.sender);
        nft.nftContract.safeTransferFrom(address(this), buyer, nft.tokenId, 1, "");
        //update nft info
        nft.owner = buyer;
        nft.isSold = true;
        nft.isOnList = false;

        itemSold++;
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

    // resell nft purchased from marketplace
    function relistNFT(IERC1155 _nftContract, uint _itemId, uint _price) 
    payable
    external  
    nonReentrant{
        require(_price > 0, "Price must be at least 1 wei");
        NFT storage nft = nfts[_itemId];
        _nftContract.safeTransferFrom(msg.sender, address(this), nft.tokenId, 1, "");
        itemSold--;
        itemOnList++;

        nft.seller = payable(msg.sender);
        nft.owner = payable(address(this));
        nft.isSold = false;
        nft.price = _price;
        nft.isOfficial = false;
        nft.isOnList = true;

        emit NFTListed(
            _itemId,
            _nftContract, 
            nft.itemId, 
            _price, 
            nft.seller,
            nft.owner
        );
    }

    function unlistNFT(IERC1155 _nftContract, uint _itemId)
    payable
    external
    nonReentrant{
        NFT storage nft = nfts[_itemId];
        require(nft.isOnList, "item is not listed");
        require(!nft.isSold, "item is sold");
        _nftContract.safeTransferFrom(address(this), msg.sender, nft.tokenId, 1, "");
        itemOnList--;

        nft.seller = payable(address(this));
        nft.owner = payable(msg.sender);
        nft.isSold = false;
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
            if( !nfts[i+1].isSold && nfts[i+1].isOnList){
                listedNFTs[nftIndex] = nfts[i+1];
                nftIndex++;
            }
        }
        return(listedNFTs);
    }

    // get all my NFTs
    function getMyNFTs() 
    external 
    view 
    returns (NFT[] memory){
        uint myNFTCount = 0;
        for (uint i = 0; i < itemCount; i++){
            if( nfts[i+1].owner == msg.sender){
                myNFTCount++;
            }
        }

        NFT[] memory myNFTs = new NFT[](myNFTCount);
        uint nftIndex = 0;
        for (uint i = 0; i < itemCount; i++){
            if( nfts[i+1].owner == msg.sender){
                myNFTs[nftIndex] = nfts[i+1];
                nftIndex++;
            }
        }
        return(myNFTs);
    }

    // get all my listed NFTs
    function getMyListedNFTs() 
    external 
    view 
    returns(NFT[] memory){
        uint myListedNFTCount = 0;
        for (uint i = 0; i < itemCount; i++){
            if( nfts[i+1].seller == msg.sender && !nfts[i+1].isSold && nfts[i+1].isOnList){
                myListedNFTCount++;
            }
        }

        NFT[] memory myListedNFTs = new NFT[](myListedNFTCount);
        uint nftIndex = 0;
        for (uint i = 0; i < itemCount; i++){
            if( nfts[i+1].seller == msg.sender && !nfts[i+1].isSold && nfts[i+1].isOnList){
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
