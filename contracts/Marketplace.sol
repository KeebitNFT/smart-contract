// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract Marketplace is ReentrancyGuard{
    uint private itemCount;
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
        // set itemCount as key
        nfts[itemCount] = NFT(
            itemCount,
            _nftContract,
            _tokenId,
            _price,
            payable(msg.sender),
            payable(address(this)),
            false,
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

        itemSold++;
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
    external 
    payable 
    nonReentrant{
        require(_price > 0, "Price must be at least 1 wei");
        NFT storage nft = nfts[_itemId];
        _nftContract.safeTransferFrom(msg.sender, address(this), nft.tokenId, 1, "");
        itemSold--;
        nft.seller = payable(msg.sender);
        nft.owner = payable(address(this));
        nft.isSold = false;
        nft.price = _price;
        nft.isOfficial = false;

        emit NFTListed(
            itemCount,
            _nftContract, 
            _itemId, 
            _price, 
            msg.sender,
            address(this)
        );
    }

    // total = nft price + transaction fee
    function _getTotalPrice(uint _itemId) 
    internal
    view  
    returns(uint){
        return(nfts[_itemId].price*(100+feePercent));
    }

    // get all unsold NFTs listed on the marketplace
    function getListedNFTs() 
    external 
    view  
    returns (NFT[] memory){
        uint unsoldNFTCount = itemCount - itemSold;

        NFT[] memory unsoldNFTs = new NFT[](unsoldNFTCount);
        uint nftIndex = 0;
        for (uint i = 0; i < itemCount; i++){
            if( !nfts[i+1].isSold){
                unsoldNFTs[nftIndex] = nfts[i+1];
                nftIndex++;
            }
        }
        return(unsoldNFTs);
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
            if( nfts[i+1].seller == msg.sender && !nfts[i+1].isSold){
                myListedNFTCount++;
            }
        }

        NFT[] memory myListedNFTs = new NFT[](myListedNFTCount);
        uint nftIndex = 0;
        for (uint i = 0; i < itemCount; i++){
            if( nfts[i+1].seller == msg.sender && !nfts[i+1].isSold){
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
