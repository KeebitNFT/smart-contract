// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard{
    address payable public immutable feeAccount; // in case Keebit collect fee
    uint public immutable feePercent; // in case Keebit collect fee
    uint public itemCount;

    constructor(uint _feePercent){
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }
}
