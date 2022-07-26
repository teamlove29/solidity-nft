// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { ERC721Checkpointable } from './ERC721Checkpointable.sol';
import { ERC721 } from './ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IWETH } from './IWETH.sol';

contract TeemNFT is ERC721Checkpointable{

    // An address who has permissions to mint Nouns
    address public minter;
    // The internal noun ID tracker
    uint256 private _currentNounId;

    bool public statusOpensea; 

    address public owner;

    address public devAddress;

    address public treasuryAddress;

      // The address of the WETH contract
    address public weth;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration = 86400;

    // The internal nft ID tracker
    uint256 private _currentNFTId;

    struct List {
        bool isForSale;
        uint nftIndex;
        address seller;
        uint256 minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

      struct Auction {
        // Status auction
        bool isAuction;
        // ID for the Noun (ERC721 token ID)
        uint256 nftIndex;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    mapping (uint => Auction) public auction;

    mapping (uint => List) public nftListForSale;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 nftIndex);
    event Transfer1(address indexed from, address indexed to, uint256 value);
    event NftTransfer(address indexed from, address indexed to, uint256 nftIndex);
    event NFTListed(uint indexed nftIndex, uint minValue, address indexed toAddress);
    event NFTOffered(uint indexed nftIndex, uint minValue, address indexed toAddress);
    event NftBidEntered(uint indexed nftIndex, uint value, address indexed fromAddress);
    event NftBidWithdrawn(uint indexed nftIndex, uint value, address indexed fromAddress);
    event NftBought(uint indexed nftIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event NftNoLongerForSale(uint indexed nftIndex);
    event AuctionCreated(uint256 indexed nounId, uint256 startTime, uint256 endTime);
    event AuctionSettled(uint256 indexed nounId, address winner, uint256 amount);

    constructor() ERC721("Teem Test NFT","TTNFT"){
        // _name = "Teem Test NFT";
        // _symbol = "TTNFT";
        statusOpensea = false;
        minter = address(0x9700C08dB89246CeE319370b88907c474499cC0C);
    }

    function setStatusOpensea()public{
        statusOpensea = !statusOpensea;
    }    

    function nftNoLongerForSale(uint nftIndex) public {
        require(nftListForSale[nftIndex].isForSale, "nft is not sell");
        require(ownerOf(nftIndex) == msg.sender,"error");
        require(nftIndex <= 444 ,"error");
        nftListForSale[nftIndex] = List(false, nftIndex, msg.sender, 0, address(0));
        emit NftNoLongerForSale(nftIndex);
    }

    function listNftForSale(uint nftIndex, uint minSalePriceInWei) public {
        require(!auction[nftIndex].isAuction, "Auction is open");
        require(ownerOf(nftIndex) == msg.sender,"error");
        require(nftIndex <= 444 ,"error");
        nftListForSale[nftIndex] = List(true, nftIndex, msg.sender, minSalePriceInWei, address(0));
        emit NFTListed(nftIndex, minSalePriceInWei, address(0));
    }

    function listNftForSaleToAddress(uint nftIndex, uint minSalePriceInWei, address toAddress) public {
        require(!auction[nftIndex].isAuction, "Auction is open");
        require(ownerOf(nftIndex) == msg.sender,"error");
        require(nftIndex <= 444 ,"error");
        nftListForSale[nftIndex] = List(true, nftIndex, msg.sender, minSalePriceInWei, toAddress);
        emit NFTListed(nftIndex, minSalePriceInWei, toAddress);
    }

    function buyNft(uint nftIndex) public payable {
        List memory list = nftListForSale[nftIndex];
        require(ownerOf(nftIndex) != msg.sender,"seller can't buy yourself");
        require(nftIndex <= 444 ,"error");
        require(list.isForSale,"not actually for sale");
        require(list.onlySellTo == address(0) || list.onlySellTo == msg.sender,"not supposed to be sold to this user");
        require(msg.value >= list.minValue,"Didn't send enough ETH");
        require(list.seller == ownerOf(nftIndex),"Seller no longer owner of nft");

        address seller = list.seller;
        _safeTransfer(seller, msg.sender, nftIndex,'');
        nftNoLongerForSale(nftIndex);

        // TODO should use safemath
        _safeTransferETHWithFallback(seller,(msg.value * 50 )/ 100); // ETH => Owner 50%
        _safeTransferETHWithFallback(treasuryAddress,(msg.value * 25 )/ 100); // ETH => Treasury 50%
        _safeTransferETHWithFallback(devAddress,(msg.value * 25 )/ 100); // ETH => Dev 50%

        emit NftBought(nftIndex, msg.value, seller, msg.sender);
    }

    // กรณีเสรอราคาแล้วถอนตังคืน
    //  function withdraw(uint nftIndex) public {
    //     require(pendingWithdrawals[msg.sender] > 0,"no eth from pending withdraw");
    //     uint amount = pendingWithdrawals[msg.sender];
    //     // // Remember to zero the pending refund before
    //     // // sending to prevent re-entrancy attacks
    //     nftOfferForBuy[nftIndex][msg.sender] = Offer(false, nftIndex, 0, address(0));
    //     pendingWithdrawals[msg.sender] = 0;
    //     _safeTransferETHWithFallback(msg.sender,amount);
    // }
    
    // เปิดประมูล
    function createAuction(uint256 _nftIndex) public {
        List memory list = nftListForSale[_nftIndex];
        require(!auction[_nftIndex].isAuction,"Auction is open"); // ต้องไม่เปิดประมูลอยู่
        require(ownerOf(_nftIndex) == msg.sender,"seller can't buy yourself"); // เจ้าของเปิดเอง
        require(_nftIndex <= 444 ,"error"); // ไม่เกิน 444 ตัว
        require(!list.isForSale,"NFT on sale now"); // ไม่ตั้งขายอยู่
        
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        auction[_nftIndex] = Auction({
            isAuction: true,
            nftIndex: _nftIndex,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false
        });

        emit AuctionCreated(_nftIndex, startTime, endTime);
    }


    // ประมูล
    function createBid(uint256 _nftIndex) external payable {
        Auction memory _auction = auction[_nftIndex];
        require(_auction.isAuction,"Auction is not open"); // เปิดประมูลอยู่
        require(!_auction.settled, "Auction has already been settled"); // ยังไม่ปิดประมูล
        require(_auction.nftIndex == _nftIndex, "NFT not up for auction"); 
        require(block.timestamp < _auction.endTime, "Auction expired"); // น้อยกว่าเวลาปิด
        require(msg.value > _auction.amount, "Lower than current price");  // มากกว่าราคาเดิม

        address payable lastBidder = _auction.bidder;

        // // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auction[_nftIndex].amount = msg.value;
        auction[_nftIndex].bidder = payable(msg.sender);

        emit NftBidEntered(_auction.nftIndex,  msg.value, msg.sender);
    }


    // ปิดประมูล
    function settleAuction(uint256 _nftIndex) public {
        Auction memory _auction = auction[_nftIndex];
        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        _auction.isAuction = false;
        _auction.settled = true;
       
        if (_auction.bidder != address(0)) {
           _safeTransfer(ownerOf(_nftIndex), _auction.bidder, _auction.nftIndex,'');
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(ownerOf(_nftIndex), _auction.amount);
        }
        emit AuctionSettled(_nftIndex, _auction.bidder, _auction.amount);
    }

    
    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }


    function mint() public returns (uint256) {
            if (_currentNounId <= 444) {
                _mintTo(msg.sender, _currentNFTId++);
            }
    }

    function _mintTo(address to, uint256 nftId) internal returns (uint256) {
            _mint(minter, to, nftId);
            return nftId;
    }

}
