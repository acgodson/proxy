// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestUSDC is ERC20, Ownable(msg.sender) {
    uint256 public constant DISPENSE_AMOUNT = 10_000 * 10 ** 18; // 10,000 tokens per demo contract

    constructor() ERC20("Simple Reward Token", "SRN") {
        // _mint(msg.sender, INITIAL_SUPPLY);
    }

    function dispense(address recipient) external onlyOwner {
        _mint(recipient, DISPENSE_AMOUNT);
    }

    // Optional: Add a function to check the total supply
    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }
}
