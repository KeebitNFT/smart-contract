// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "hardhat/console.sol";
import "./Factory.sol";
import "./Token.sol";

contract Marketplace is ReentrancyGuard {
    uint public itemCount; // # item ever been listed
    uint public itemOnList; // # item currently listed
    address payable public immutable owner;
    uint public immutable feePercent; // transaction fee, no listing fee
    Factory public factory;

    struct MarketNFT {
        uint itemId;
        Token nftContract;
        string collectionName;
        uint tokenId;
        uint price;
        address payable seller;
        address payable owner;
        bool isOfficial;
        bool isOnList;
    }
    mapping(uint => MarketNFT) public nfts;

    event NFTListed(
        uint itemId,
        Token nftContract,
        string collectionName,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTUnlisted(
        uint itemId,
        Token nftContract,
        string collectionName,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTSold(
        uint itemId,
        Token nftContract,
        string collectionName,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );

    constructor(address _factory, uint _feePercent) {
        factory = Factory(_factory);
        owner = payable(msg.sender);
        feePercent = _feePercent;
    }

    // list nft or NFTs
    function listNFTs(
        address _nftContract,
        uint[] memory _tokenIds,
        uint _price
    ) external nonReentrant returns (address) {
        require(
            factory.isToken(_nftContract),
            "Only a valid token contract can be listed"
        );
        require(_tokenIds.length > 0, "No token id provided");
        require(_price > 0, "Price must be at least 1 wei");

        for (uint i = 0; i < _tokenIds.length; i++) {
            _list(Token(_nftContract), _tokenIds[i], _price);
            // console.log("token id: %s", _tokenIds[i]);
        }
        return address(_nftContract);
    }

    function _list(Token _nftContract, uint _tokenId, uint _price) private {
        _nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            1,
            ""
        );
        itemCount++;
        itemOnList++;
        // check if lister is vendor or peer
        bool _isOfficial = factory.isVendor(msg.sender);
        bool _isOnlist = true;
        nfts[itemCount] = MarketNFT(
            itemCount,
            _nftContract,
            _nftContract.collectionName(),
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
            _nftContract.collectionName(),
            _tokenId,
            _price,
            msg.sender,
            address(this)
        );
    }

    //buy nft
    function buyNFT(uint _itemId) external payable nonReentrant {
        uint _totalPrice = _getTotalPrice(_itemId);
        MarketNFT storage nft = nfts[_itemId];
        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        require(nft.isOnList, "item is not for sale");
        require(
            msg.value >= _totalPrice,
            "not enough ether for this transaction"
        );
        //pay seller and owner
        nft.seller.transfer(nft.price);
        owner.transfer(_totalPrice - nft.price);
        //transfer nft to buyer
        address payable buyer = payable(msg.sender);
        nft.nftContract.safeTransferFrom(
            address(this),
            buyer,
            nft.tokenId,
            1,
            ""
        );
        //update nft info
        nft.owner = buyer;
        nft.isOnList = false;

        itemOnList--;
        emit NFTSold(
            _itemId,
            nft.nftContract,
            nft.nftContract.collectionName(),
            nft.tokenId,
            msg.value,
            nft.seller,
            nft.owner
        );
    }

    function unlistNFT(
        Token _nftContract,
        uint _itemId
    ) external payable nonReentrant {
        MarketNFT storage nft = nfts[_itemId];
        require(nft.isOnList, "item is not listed");
        _nftContract.safeTransferFrom(
            address(this),
            msg.sender,
            nft.tokenId,
            1,
            ""
        );
        itemOnList--;

        nft.seller = payable(address(this));
        nft.owner = payable(msg.sender);
        nft.isOnList = false;

        emit NFTUnlisted(
            _itemId,
            _nftContract,
            _nftContract.collectionName(),
            nft.tokenId,
            nft.price,
            nft.seller,
            nft.owner
        );
    }

    // total = nft price + transaction fee
    function _getTotalPrice(uint _itemId) internal view returns (uint) {
        return (nfts[_itemId].price * (100 + feePercent));
    }

    // get all currently listed NFTs on the marketplace
    function getListedNFTs() external view returns (MarketNFT[] memory) {
        MarketNFT[] memory listedNFTs = new MarketNFT[](itemOnList);
        uint nftIndex = 0;
        for (uint i = 0; i < itemCount; i++) {
            if (nfts[i + 1].isOnList) {
                listedNFTs[nftIndex] = nfts[i + 1];
                nftIndex++;
            }
        }
        return (listedNFTs);
    }

    function getMyListedNFTs() external view returns (MarketNFT[] memory) {
        uint myListedNFTCount = 0;
        for (uint i = 0; i < itemCount; i++) {
            if (nfts[i + 1].seller == msg.sender && nfts[i + 1].isOnList) {
                myListedNFTCount++;
            }
        }

        MarketNFT[] memory myListedNFTs = new MarketNFT[](myListedNFTCount);
        uint nftIndex = 0;
        for (uint i = 0; i < itemCount; i++) {
            if (nfts[i + 1].seller == msg.sender && nfts[i + 1].isOnList) {
                myListedNFTs[nftIndex] = nfts[i + 1];
                nftIndex++;
            }
        }
        return (myListedNFTs);
    }

    function updatePrice(uint _itemId, uint _newPrice) external returns (uint) {
        require(_newPrice > 0, "Price must be at least 1 wei");
        nfts[_itemId].price = _newPrice;
        return (_newPrice);
    }
}
