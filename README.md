# TP2ETHKIPU
Solidity Auction Contract

# Auction - Solidity Smart Contract for Auctions

## Description

**Auction** is a smart contract written in Solidity that implements a secure and auditable auction system. 
It was developed as part of the TP2 assignment for ethKipu – Módulo 2,
and includes all required features such as : minimum bid increments, automatic extension of the auction period, refund handling, and a complete bid history.

The contract is deployed on the Sepolia test network and verified on Etherscan.

---

## Features

- ✅ Auction initialized with a customizable duration.
- ✅ Bids must be at least 5% higher than the current highest bid.
- ✅ If a new valid bid is placed within the last 10 minutes, the auction is automatically extended by 10 minutes.
- ✅ Full refund to all non-winning bidders after auction ends, minus a 2% commission.
- ✅ Full list of all bids made, with amount and bidder.
- ✅ Emergency withdrawal in case funds get stuck.
- ✅ Events emitted on all key actions for transparency.

---

## Functions

### `constructor(uint256 durationInSeconds)`
Initializes the auction with a duration in seconds (e.g., `604800` for 1 week).

### `bid() external payable`
Places a new bid. Must be 5% higher than the current highest bid. Emits `NewOffer`.

### `getWinner() external view returns (address, uint256)`
Returns the address and amount of the highest bidder. Only callable after the auction has ended.

### `getAllBids() external view returns (Bid[] memory)`
Returns a list of all bids placed during the auction.

### `endAuctionAndRefundAll() external onlyOwner`
Ends the auction and automatically refunds all losing bidders (min 2%). Emits `DepositWithdrawn` for each refund and `AuctionEnded`.

### `emergencyWithdraw() external onlyOwner`
Allows the owner to withdraw all funds in case of emergency.

---

## Events

- `event NewOffer(address indexed bidder, uint256 amount)`
- `event AuctionEnded(address indexed winner, uint256 amount)`
- `event DepositWithdrawn(address indexed user, uint256 amount)`

---

## Security Considerations

- The contract restricts critical actions to the `owner`.
- Emergency fallback logic is provided for fund recovery.

---

## Deployment Info

- **Network**: Sepolia Testnet  
- **Contract Address**: `0xeA1C4dE8A52c83D740441416689Fd2e5e73e065d`  
- **Link Contract verified**: `https://sepolia.etherscan.io/address/0xeA1C4dE8A52c83D740441416689Fd2e5e73e065d#code`
---
