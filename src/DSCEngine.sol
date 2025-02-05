// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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
contract DSCEngine is ReentrancyGuard {
    ///////////////////////////////
    /////// ERRORS  ////////////
    ///////////////////////////////
    error DSCEngine__AmountMoreThanZero();
    error DSCEngine__MustBeSameLength();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();

    //////////////////////////////////
    /////// STATE VARIABLES  ////////////
    //////////////////////////////////
    mapping(address collateralToken => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;

    DecentralizedStableCoin private immutable i_DSC;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    ///////////////////////////////
    /////// MODIFIERS  ////////////
    ///////////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) revert DSCEngine__AmountMoreThanZero();
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) revert DSCEngine__TokenNotAllowed();
        _;
    }

    ///////////////////////////////
    /////// FUNCTIONS  ////////////
    ///////////////////////////////
    constructor(address[] memory tokenAddress, address[] memory priceFeedAddress, address dscAddress) {
        if (tokenAddress.length != priceFeedAddress.length) revert DSCEngine__MustBeSameLength();

        for (uint256 i = 0; i < tokenAddress.length; i++) {
            s_priceFeeds[tokenAddress[i]] = priceFeedAddress[i];
        }

        i_DSC = DecentralizedStableCoin(dscAddress);
    }

    /////////////////////
    //// External Functions
    /////////////////////

    // People should be able to deposit their collateral (wETH, wBTC) and mint DSC tokens
    function depositCollateralAndMistDsc() external {}

    /**
     * @notice following the CEI
     * @param collateralAddress the address of the token to deposit as collateral
     * @param collateralAmount the amount of the collateral to deposit
     */
    function depositCollateral(address collateralAddress, uint256 collateralAmount)
        external
        moreThanZero(collateralAmount)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][collateralAddress] += collateralAmount;
        emit CollateralDeposited(msg.sender, collateralAddress, collateralAmount);

        bool success = IERC20(collateralAddress).transferFrom(msg.sender, address(this), collateralAmount);
        if (!success) revert DSCEngine__TransferFailed();
    }

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
