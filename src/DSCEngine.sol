// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Decentralized StableCoin Engine
 * @author Johnpaul Nnaji, Patrick Collins
 * @notice This contract is the core of the DSC System. It handles all logic for mining
 *          and redeeming DSC, as well as depositing & withdrawing & withdrawing collateral.
 * @dev This system is designed to be as minimal as possible, having a token maintain a 1token = $1 peg.
 * This stablecoin has the properties:
 *  - EXogonous Collateral
 *  - Dollat pegged
 *  - Algorithmically stable
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by wETH and wBTC
 *
 * @notice Our DSC system should always be overcollateralized.
 *    At no point should the value of all collateral be less than the value of all DSC tokens.
 *
 */

contract DSCEngine {
    constructor() {}

    // People should be able to deposit their collateral (wETH, wBTC) and mint DSC tokens
    function depositCollateralAndMistDsc() external {}

    function depositCollateral() external {}

    // People should be able to redeem their DSC tokens for their collateral
    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    // People should be able to burn their DSC tokens
    // Reason being that if they are nervous they have so much DSC, and not enough collateral, they can burn their DSC for more collateral
    function burnDscForCollateral() external {}

    /**
     * @notice This function should be called if the system is undercollateralized.
     *  This function should liquidate the collateral of (some user) in the system to ensure that the system is overcollateralized.
     */
    function liquidate() external {}

    function getHealthFactor() external view returns (uint256) {}
}
