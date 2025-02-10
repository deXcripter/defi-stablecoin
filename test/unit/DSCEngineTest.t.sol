// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "../../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DeployDSC deployDsc;
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig config;

    address ethUsdPriceFeed;
    address weth;

    address public USER1 = address(0x1);
    uint public constant AMOUNT_COLLATERAL = 10e18;
    uint public constant STARTING_ERC20_BALANCE = 10e18;

    function setUp() public {
        deployDsc = new DeployDSC();
        (dsc, dscEngine, config) = deployDsc.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNtwkConfig();

        ERC20Mock(weth).mint(USER1, STARTING_ERC20_BALANCE);
    }

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUSD = 30000e18;
        uint256 actualUSD = dscEngine.getUSDValue(weth, ethAmount);
        assertEq(actualUSD, expectedUSD);
    }

    function testDepositCollateral() public {
        vm.startPrank(USER1);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert();
        dscEngine.depositCollateral(weth, 0);        
    }
}
