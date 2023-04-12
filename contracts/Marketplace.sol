// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
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
        string name;
        string uri;
        uint tokenId;
        uint price;
        address seller;
        address owner;
        bool isOfficial;
        bool isOnList;
    }
    mapping(uint => MarketNFT) public nfts;

    event NFTListed(
        uint indexed itemId,
        address nftContract,
        string name,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTUnlisted(
        uint indexed itemId,
        address nftContract,
        string name,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );
    event NFTBought(
        uint indexed itemId,
        address nftContract,
        string name,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed owner
    );

    constructor(address factoryAddress, uint _feePercent) {
        factory = Factory(factoryAddress);
        owner = payable(msg.sender);
        feePercent = _feePercent;
    }

    // list nft or NFTs
    function listNFTs(
        address _nftContract,
        uint[] calldata _tokenIds,
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
        }
        return _nftContract;
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
            _nftContract.name(),
            _nftContract.uri(0),
            _tokenId,
            _price,
            msg.sender,
            address(this),
            _isOfficial,
            _isOnlist
        );
        emit NFTListed(
            itemCount,
            address(_nftContract),
            _nftContract.name(),
            _tokenId,
            _price,
            msg.sender,
            address(this)
        );
    }

    // Buy nft
    function buyNFT(uint _itemId) external payable nonReentrant {
        uint _totalPrice = _getTotalPrice(_itemId);
        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        require(nfts[_itemId].isOnList, "item is not for sale");
        require(
            msg.value >= _totalPrice,
            "not enough ether for this transaction"
        );

        // Pay seller and owner
        payable(nfts[_itemId].seller).transfer(nfts[_itemId].price);
        owner.transfer(_totalPrice - nfts[_itemId].price);

        // Transfer nft to buyer
        address buyer = msg.sender;
        Token(nfts[_itemId].nftContract).safeTransferFrom(
            address(this),
            buyer,
            nfts[_itemId].tokenId,
            1,
            ""
        );

        // Update nft info
        nfts[_itemId].owner = buyer;
        nfts[_itemId].isOnList = false;

        itemOnList--;

        emit NFTBought(
            _itemId,
            nfts[_itemId].nftContract,
            Token(nfts[_itemId].nftContract).name(),
            nfts[_itemId].tokenId,
            msg.value,
            nfts[_itemId].seller,
            nfts[_itemId].owner
        );
    }

    function unlistNFT(uint _itemId) external payable nonReentrant {
        require(nfts[_itemId].isOnList, "item is not listed");
        require(msg.sender == nfts[_itemId].seller, "msg.sender is not seller");
        Token(nfts[_itemId].nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            nfts[_itemId].tokenId,
            1,
            ""
        );

        itemOnList--;

        nfts[_itemId].owner = msg.sender;
        nfts[_itemId].isOnList = false;

        emit NFTUnlisted(
            _itemId,
            nfts[_itemId].nftContract,
            Token(nfts[_itemId].nftContract).name(),
            nfts[_itemId].tokenId,
            nfts[_itemId].price,
            nfts[_itemId].seller,
            nfts[_itemId].owner
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
        return listedNFTs;
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
        return myListedNFTs;
    }

    function updatePrice(uint _itemId, uint _newPrice) external {
        require(_newPrice > 0, "Price must be at least 1 wei");
        nfts[_itemId].price = _newPrice;
    }
}
