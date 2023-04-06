// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "hardhat/console.sol";
import "./Factory.sol";
import "./Token.sol";

contract Marketplace is ReentrancyGuard, ERC1155Holder {
    uint public itemCount; // # item ever been listed
    uint public itemOnList; // # item currently listed
    address payable public immutable owner;
    uint public immutable feePercent; // transaction fee, no listing fee
    Factory public factory;

    struct MarketNFT {
        uint itemId;
        address nftContract;
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
        address nftContract,
        string collectionName,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTUnlisted(
        uint itemId,
        address nftContract,
        string collectionName,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTBought(
        uint itemId,
        address nftContract,
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
            "Only NFTs of a valid token contract can be listed"
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
        bool _isOfficial = factory.isVendor(msg.sender);
        bool _isOnlist = true;
        nfts[itemCount] = MarketNFT(
            itemCount,
            address(_nftContract),
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
            address(_nftContract),
            _nftContract.collectionName(),
            _tokenId,
            _price,
            msg.sender,
            address(this)
        );
    }

    // Buy nft
    function buyNFT(uint _itemId) external payable nonReentrant {
        uint _totalPrice = _getTotalPrice(_itemId);
        MarketNFT memory nft = nfts[_itemId];
        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        require(nft.isOnList, "item is not for sale");
        require(
            msg.value >= _totalPrice,
            "not enough ether for this transaction"
        );

        // Pay seller and owner
        nft.seller.transfer(nft.price);
        owner.transfer(_totalPrice - nft.price);

        // Transfer nft to buyer
        address payable buyer = payable(msg.sender);
        Token(nft.nftContract).safeTransferFrom(
            address(this),
            buyer,
            nft.tokenId,
            1,
            ""
        );

        // Update nft info
        nft.owner = buyer;
        nft.isOnList = false;

        itemOnList--;

        emit NFTBought(
            _itemId,
            nft.nftContract,
            Token(nft.nftContract).collectionName(),
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
        MarketNFT memory nft = nfts[_itemId];
        require(nft.isOnList, "item is not listed");
        require(msg.sender == nft.seller);
        _nftContract.safeTransferFrom(
            address(this),
            msg.sender,
            nft.tokenId,
            1,
            ""
        );

        itemOnList--;

        nft.owner = payable(msg.sender);
        nft.isOnList = false;

        emit NFTUnlisted(
            _itemId,
            address(_nftContract),
            _nftContract.collectionName(),
            nft.tokenId,
            nft.price,
            nft.seller,
            nft.owner
        );
    }

    // total = nft price + transaction fee
    function _getTotalPrice(uint _itemId) internal view returns (uint) {
        return (nfts[_itemId].price * (100 + feePercent)) / 100;
    }

    // get all currently listed NFTs on the marketplace
    function getListedNFTs() external view returns (MarketNFT[] memory) {
        MarketNFT[] memory listedNFTs = new MarketNFT[](itemOnList);
        uint nftIndex = 0;
        for (uint i = 1; i <= itemCount; i++) {
            if (nfts[i].isOnList) {
                listedNFTs[nftIndex] = nfts[i];
                nftIndex++;
            }
        }
        return (listedNFTs);
    }

    function getMyListedNFTs() external view returns (MarketNFT[] memory) {
        uint myListedNFTCount = 0;
        for (uint i = 1; i <= itemCount; i++) {
            if (nfts[i].seller == msg.sender && nfts[i].isOnList) {
                myListedNFTCount++;
            }
        }

        MarketNFT[] memory myListedNFTs = new MarketNFT[](myListedNFTCount);
        uint nftIndex = 0;
        for (uint i = 1; i <= itemCount; i++) {
            if (nfts[i].seller == msg.sender && nfts[i].isOnList) {
                myListedNFTs[nftIndex] = nfts[i];
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
