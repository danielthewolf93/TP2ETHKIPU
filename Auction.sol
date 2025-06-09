// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Auction - Solidity Auction Contract with 5% minimum bid increment, automatic extension, and refunds.
/// @author Sergio D. Blanco
contract Auction {
    struct Bid {
        uint256 amount;
        address bidder;
    }

    address private immutable owner;
    uint256 private immutable auctionStart;
    uint256 private auctionEnd;
    bool private auctionEnded;

    Bid private highestBid;
    Bid[] private allBids;

    mapping(address => uint256[]) private bidHistory;
    mapping(address => uint256) private pendingReturns;
    mapping(address => bool) private refunded;

    uint256 private constant COMMISSION_PERCENT = 2;
    uint256 private constant EXTENSION_TIME = 10 minutes;

    /// @notice Emitted when a new valid bid is submitted
    event NewOffer(address indexed bidder, uint256 amount);

    /// @notice Emitted when the auction ends
    event AuctionEnded(address indexed winner, uint256 amount);

    /// @notice Emitted when a refund is processed
    event DepositWithdrawn(address indexed user, uint256 amount);

    /// @param durationInSeconds Duration of the auction (e.g., 604800 for 1 week)
    constructor(uint256 durationInSeconds) {
        owner = msg.sender;
        auctionStart = block.timestamp;
        auctionEnd = block.timestamp + durationInSeconds;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this.");
        _;
    }

    modifier isActive() {
        require(block.timestamp < auctionEnd && !auctionEnded, "Auction is not active.");
        _;
    }

    modifier hasEnded() {
        require(block.timestamp >= auctionEnd || auctionEnded, "Auction is still running.");
        _;
    }

    /// @notice Places a new bid (must be >= 5% more than the current highest bid)
    function bid() external payable isActive {
        require(msg.value > 0, "Bid must be greater than 0.");

        uint256 minBid = highestBid.amount + (highestBid.amount * 5) / 100;
        if (highestBid.amount == 0) minBid = 1;

        require(msg.value >= minBid, "Bid must be at least 5% higher the current.");

        // Record bid
        bidHistory[msg.sender].push(msg.value);
        allBids.push(Bid(msg.value, msg.sender));

        // Track refundable amount to previous highest bidder
        if (highestBid.bidder != address(0)) {
            pendingReturns[highestBid.bidder] += highestBid.amount;
        }

        highestBid = Bid(msg.value, msg.sender);

        // Extend if bid occurs within last 10 minutes
        if (auctionEnd - block.timestamp <= EXTENSION_TIME) {
            auctionEnd += EXTENSION_TIME;
        }

        emit NewOffer(msg.sender, msg.value);
    }

    /// @notice Returns the current winner and bid amount
    function getWinner() external view hasEnded returns (address, uint256) {
        return (highestBid.bidder, highestBid.amount);
    }

    /// @notice Returns the complete list of all bids made
    function getAllBids() external view returns (Bid[] memory) {
        return allBids;
    }

    /// @notice Ends the auction and refunds all non-winning bidders (minus 2% commission)
    function endAuctionAndRefundAll() external onlyOwner hasEnded {
        require(!auctionEnded, "Auction already finalized.");
        auctionEnded = true;

        for (uint i = 0; i < allBids.length; i++) {
            address bidder = allBids[i].bidder;

            if (bidder == highestBid.bidder || refunded[bidder]) {
                continue;
            }

            uint256 amount = pendingReturns[bidder];
            if (amount > 0) {
                uint256 commission = (amount * COMMISSION_PERCENT) / 100;
                uint256 refundAmount = amount - commission;

                refunded[bidder] = true;
                pendingReturns[bidder] = 0;

                payable(bidder).transfer(refundAmount);
                payable(owner).transfer(commission);

                emit DepositWithdrawn(bidder, refundAmount);
            }
        }

        emit AuctionEnded(highestBid.bidder, highestBid.amount);
    }

    /// @notice Emergency function to recover funds from the contract if something fails
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(owner).transfer(balance);
    }
}
