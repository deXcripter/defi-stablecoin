// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUSDPriceFeed; // this is the price feed for ethereum to USD
        address wbtcUSDPriceFeed; // this is the price feed for bitcoin to USD
        address weth; //  this is the ERC20 version of ethereum
        address wbtc; // this is the ERC20 version of bitcoin
        uint256 deployerKey;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000 * int256(10 ** DECIMALS); // $2000
    int256 public constant BTC_USD_PRICE = 40000 * int256(10 ** DECIMALS); // $40,000
    uint256 public constant ANVIL_DEPLOYER_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNtwkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNtwkConfig = getSepoliaEthConfig();
        } else {
            activeNtwkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUSDPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUSDPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81, // the (supposed) sepolia version of weth
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063, // the (supposed) sepolia version of wbtc
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNtwkConfig.wethUSDPriceFeed != address(0)) {
            return activeNtwkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock weth = new ERC20Mock(); // the (supposed) anvil version of weth
        // ERC20Mock weth = new ERC20Mock("Wrapped Ethereum", "WETH", DECIMALS); // the (supposed) anvil version of weth

        MockV3Aggregator btcUSDPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        ERC20Mock wbtc = new ERC20Mock(); // the (supposed) anvil version of wbtc
        // ERC20Mock wbtc = new ERC20Mock("Wrapped Bitcoin", "WBTC", DECIMALS); // the (supposed) anvil version of wbtc
        vm.stopBroadcast();

        return NetworkConfig({
            wethUSDPriceFeed: address(ethUSDPriceFeed),
            wbtcUSDPriceFeed: address(btcUSDPriceFeed),
            weth: address(weth),
            wbtc: address(wbtc),
            deployerKey: ANVIL_DEPLOYER_KEY
        });
    }
}
