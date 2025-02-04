// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Decentralized StableCoin
/// @author Johnpaul Nnaji, Patrick Collins
/// @notice Collateral: Exogenous (ETH & BTC)
/// @notice Minting: Algorithimic
/// @dev This is a contract meant to be governed by DSCEngine.
///      This contract is just the ERC20 implementation of our stablecoin system

contract DecentralizedStableCoin is ERC20Burnable, Ownable {

    error DecentralizedStableCoin__NotEnoughToken();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();

    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (balance <= 0) revert DecentralizedStableCoin__NotEnoughToken();
        if (balance < _amount) revert DecentralizedStableCoin__BurnAmountExceedsBalance();

        // basically, this means go to the user class (the overridden function) and use their brun implementation. 
        super.burn(_amount); 
    }
}
