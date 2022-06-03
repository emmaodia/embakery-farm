// SPDX-License-Identifier: GPL-3

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BreadToken is ERC20 {

    uint256 public balance; 
    address public owner;
    
    constructor(uint256 _initialsupply) ERC20("Bread Token", "BREAD") {
        owner = msg.sender;
        _mint(owner, _initialsupply);
    }

    function viewSupply() public returns(uint256) {
        balance = owner.balance;
        return balance;
    }
}