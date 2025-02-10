// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from
    "../lib/chainlinnk/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    error DSCEngine__BreakHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();

    //////////////////////////////////
    /////// STATE VARIABLES  ////////////
    //////////////////////////////////

    uint256 private constant PRICE_FEED_USD_PRECISION = 1e10; // 10,000,000,000
    uint256 private constant PRECISION = 1e18; // 1,000,000,000,000,000,000
    uint256 private constant LIQUIDATION_TRESHOLD = 50; // 200% overcollaterized
    uint256 private constant MIN_HEALTH_FACTOR = 1; // 100% overcollaterized

    mapping(address collateralToken => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountOfDSC) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_DSC;

    ///////////////////////////////
    /////// EVENTS  ////////////
    ///////////////////////////////

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
            s_collateralTokens.push(tokenAddress[i]);
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

    /**
     * @param amount the amount of DSC tokens the user wants to mint.
     * @notice we allow the user specifies the amount of DSC token they want to mint.
     * E.g. (User 1 Deposits $200 ETH, but only decides to mint $20 DSC)
     */
    function mintDsc(uint256 amount) external moreThanZero(amount) nonReentrant {
        s_DSCMinted[msg.sender] += amount;

        // if adding the amount of DSC to the user's balance breaks the health factor, revert
        _isHealthFactorBroken(msg.sender);

        bool minted = i_DSC.mint(msg.sender, amount);
        if (!minted) revert DSCEngine__MintFailed();
    }

    // People should be able to burn their DSC tokens
    // Reason being that if they are nervous they have so much DSC, and not enough collateral, they can burn their DSC for more collateral
    function burnDscForCollateral() external {}

    /**
     * @notice This function should be called if the system is undercollateralized.
     *  This function should liquidate the collateral of (some user) in the system to ensure that the system is overcollateralized.
     */
    function liquidate() external {}

    function getHealthFactor() external view returns (uint256) {}

    ///////////////////////////////
    // PRIVATE & INTERNAL FUNCTIONS
    ///////////////////////////////

    function _getAccountInfomation(address user)
        private
        view
        returns (uint256 totalDScMinted, uint256 collateralValueInUSD)
    {
        totalDScMinted = s_DSCMinted[user];
        collateralValueInUSD = getAccountCollateralValue(user);
    }

    /**
     * Returns how close to liquidation a user is
     * If a user goes below 1, then they can get liquidated.
     * @notice for this to work, we have to get the following:
     *  1. The total DSC minted for a user
     *  2. The total collateral a user deposited.
     */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = _getAccountInfomation(user);
        uint256 collateralAdjustedForTreshold = (collateralValueInUSD * LIQUIDATION_TRESHOLD) / 100;

        return (collateralAdjustedForTreshold * PRECISION / totalDSCMinted);
    }

    function _isHealthFactorBroken(address user) internal view {
        // 1. Check if the user has enough collateral
        uint256 healthFactor = _healthFactor(user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreakHealthFactor(healthFactor);
        }
    }

    ///////////////////////////////
    // PUBLIC & EXTERNAL VIEW FUNCTIONS
    ///////////////////////////////
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUSD) {
        // Loop through each collateal token, get the amount they deposited, and
        // map it to the price to get the USD value
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUSD += getUSDValue(token, amount);
        }

        return totalCollateralValueInUSD;
    }

    function getUSDValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // 1ETH = $1000
        // the return price value from CL willl be 1000 * 1e8 and we need to add extra 10 decimals to match the amount
        uint256 priceTo18Decimals = uint256(price) * PRICE_FEED_USD_PRECISION;
        return ((priceTo18Decimals * amount) / PRECISION);
    }
}
