// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";

import "../src/vaults/invest.sol";

contract AaveInteractionTest is Test {
    AaveInteraction aaveInteraction;
    IERC20 token;
    IERC20 atoken;
    uint256 amount;

    // Mainnet fork configuration
    address ADDRESS_PROVIDER = vm.envAddress("PROVIDER_ADDRESS");
    address TOKEN = vm.envAddress("ASSET_ADDRESS");
    address USER = vm.envAddress("PAISA_WALA");

    function setUp() public {
        console.log("==SET UP(testInvest.t.sol)==");

        // contract instance
        aaveInteraction = AaveInteraction(
            0xa138575a030a2F4977D19Cc900781E7BE3fD2bc0
        );

        // Deploy the contract
        // aaveInteraction = new AaveInteraction(ADDRESS_PROVIDER);

        console.log(
            "Deployed AaveInteraction contract at: %s",
            address(aaveInteraction)
        );

        // setting up underlying token
        token = IERC20(TOKEN);
        console.log("TOKEN Address: %s", TOKEN);

        // fetching aToken for underlying token
        address aTOKEN = aaveInteraction.getATokenAddress(TOKEN);
        console.log("aTOKEN Address: %s", aTOKEN);

        // setting up aToken of underlying token
        atoken = IERC20(aTOKEN);

        // setting up supply/withdraw amount
        amount = 100000000;
        console.log("Setup completed.");
    }

    function testSupply() public {
        console.log("== Starting testSupply ==");
        // Impersonate the user
        vm.startPrank(USER);
        console.log("Impersonated user: %s", USER);

        // Check user's TOKEN balance
        assertGt(
            token.balanceOf(USER),
            0,
            "USER dont hold the underlying token"
        );
        // uint256 userBalance = token.balanceOf(USER);
        // console.log("User's TOKEN balance beforw=e: %s", userBalance);

        // Approve and supply TOKEN
        token.approve(address(aaveInteraction), amount);
        console.log("Approved %s TOKEN for AaveInteraction contract", amount);

        // uint256 allowance = token.allowance(USER, address(aaveInteraction));
        // console.log("TOKEN allowance for AaveInteraction: %s", allowance);

        assertGe(
            token.allowance(USER, address(aaveInteraction)),
            amount,
            "Allowance should be equal to the approved amount"
        );

        // supply amount to aaveInteraction
        aaveInteraction.supply(TOKEN, amount);
        console.log("Supplied %s TOKEN to Aave", amount);

        uint256 userBalance2 = token.balanceOf(USER);
        console.log("User's TOKEN balance after supply: %s", userBalance2);

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = aaveInteraction.getStake();

        console.log("Stake Data:");
        console.log("Total Collateral Base: %s", totalCollateralBase);
        console.log("Total Debt Base: %s", totalDebtBase);
        console.log("Available Borrows Base: %s", availableBorrowsBase);
        console.log(
            "Current Liquidation Threshold: %s",
            currentLiquidationThreshold
        );
        console.log("LTV: %s", ltv);
        console.log("Health Factor: %s", healthFactor);

        aaveInteraction.withdraw(TOKEN, 100000000, address(aaveInteraction));
        // console.log("Withdrew %s TOKEN from Aave", aTokenBalance);

        uint256 userBalance3 = token.balanceOf(USER);
        uint256 contractBalance = token.balanceOf(address(aaveInteraction));
        console.log("User's TOKEN balance after withdraw: %s", userBalance3);
        console.log("contract's Balance TOKEN  withdraw: %s", contractBalance);
        // Stop impersonation

        vm.stopPrank();
        console.log("Stopped impersonating user: %s", USER);

        // Add assertions to verify the result

        // Example assertion (uncomment and modify as needed)
        // assertEq(poolBalance, amount);
    }

    function testSupplyAndWithdraw() public {
        console.log("== Starting testSupplyAndWithdraw ==");
        // Impersonate the user
        vm.startPrank(USER);
        console.log("Impersonated user: %s", USER);

        // Check user's TOKEN balance
        uint256 userBalance = token.balanceOf(USER);
        console.log("User's TOKEN balance beforw=e: %s", userBalance);

        // Approve and supply TOKEN
        token.approve(address(aaveInteraction), amount);
        console.log("Approved %s TOKEN for AaveInteraction contract", amount);

        uint256 allowance = token.allowance(USER, address(aaveInteraction));
        console.log("TOKEN allowance for AaveInteraction: %s", allowance);
        require(allowance >= amount, "Allowance is not enough");

        aaveInteraction.supply(TOKEN, amount);
        console.log("Supplied %s TOKEN to Aave", amount);

        uint256 userBalance2 = token.balanceOf(USER);
        console.log("User's TOKEN balance after supply: %s", userBalance2);

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = aaveInteraction.getStake();

        console.log("Stake Data:");
        console.log("Total Collateral Base: %s", totalCollateralBase);
        console.log("Total Debt Base: %s", totalDebtBase);
        console.log("Available Borrows Base: %s", availableBorrowsBase);
        console.log(
            "Current Liquidation Threshold: %s",
            currentLiquidationThreshold
        );
        console.log("LTV: %s", ltv);
        console.log("Health Factor: %s", healthFactor);

        aaveInteraction.withdraw(TOKEN, 100000000, address(aaveInteraction));
        // console.log("Withdrew %s TOKEN from Aave", aTokenBalance);

        uint256 userBalance3 = token.balanceOf(USER);
        uint256 contractBalance = token.balanceOf(address(aaveInteraction));
        console.log("User's TOKEN balance after withdraw: %s", userBalance3);
        console.log("contract's Balance TOKEN  withdraw: %s", contractBalance);
        // Stop impersonation

        vm.stopPrank();
        console.log("Stopped impersonating user: %s", USER);

        // Add assertions to verify the result

        // Example assertion (uncomment and modify as needed)
        // assertEq(poolBalance, amount);
    }
}
