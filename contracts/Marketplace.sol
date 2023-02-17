// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Marketplace is ReentrancyGuard{
    // using Counters for Counters.Counter;
    // Counters.Counter private nftCount;
    address payable public immutable feeAccount; // in case Keebit collect fee
    uint public immutable feePercent; // in case Keebit collect fee
    uint public itemCount;

    struct NFT{
        uint itemId;
        IERC721 nft;
        uint tokenId;
        uint price;
        address payable seller;
        bool isSold;
    }
    mapping(uint => NFT) public nfts;

    constructor(uint _feePercent){
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    function listNFT(IERC721 _nft, uint _tokenId, uint _price) external nonReentrant{
        require(_price > 0, "Price must be at least 1 wei");
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        nfts[itemCount] = NFT(
            itemCount,
            _nft,
            _tokenId,
            _price,
            payable(msg.sender),
            false
        );
    }
}
