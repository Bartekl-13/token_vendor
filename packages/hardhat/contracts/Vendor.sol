// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; // Do not change the Solidity version as it negatively impacts submission grading

/// @title Vendor Contract for Buying and Selling Tokens
/// @author [Your Name]
/// @notice This contract allows users to buy tokens with Ether and sell tokens for Ether.
/// @dev All implemented functions are working correctly.

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    YourToken public yourToken;

    event BuyTokens(
        address indexed buyer,
        uint256 amountOfEth,
        uint256 amountOfTokens
    );
    event SellTokens(
        address indexed sender,
        uint256 amountOfEth,
        uint256 amountOfTokens
    );

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    uint256 public constant tokensPerEth = 100;

    /// @notice Buy tokens with ETH.
    /// @dev The number of tokens purchased is calculated based on the provided ETH and the `tokensPerEth` rate.
    function buyTokens() public payable {
        uint256 numberOfTokens = msg.value * tokensPerEth;
        bool sent = yourToken.transfer(msg.sender, numberOfTokens);
        require(sent, "Transaction failed");

        emit BuyTokens(msg.sender, msg.value, numberOfTokens);
    }

    /// @notice Withdraw ETH from the contract (onlyOwner).
    function withdraw() public onlyOwner {
        uint256 vendorBalance = address(this).balance;
        address owner = msg.sender;
        (bool sent, ) = owner.call{value: vendorBalance}("");
        require(sent, "Failed to withdraw");
    }

    /// @notice Sell tokens for ETH.
    /// @param amount The amount of tokens to sell.
    function sellTokens(uint256 amount) public {
        require(amount > 0, "Must sell a token amount greater than 0");

        address sender = msg.sender;
        uint256 senderBalance = yourToken.balanceOf(sender);
        require(senderBalance >= amount, "Not enough balance");
        require(
            yourToken.allowance(sender, address(this)) >= amount,
            "Allowance is insufficient"
        );

        uint256 amountOfEth = amount / tokensPerEth;
        uint256 vendorEthBalance = address(this).balance;
        require(
            vendorEthBalance >= amountOfEth,
            "Vendor does not have enough ETH"
        );

        bool sent = yourToken.transferFrom(sender, address(this), amount);
        require(sent, "Failed to transfer tokens");

        (bool ethSent, ) = sender.call{value: amountOfEth}("");
        require(ethSent, "Failed to send back ETH");

        emit SellTokens(sender, amountOfEth, amount);
    }
}
