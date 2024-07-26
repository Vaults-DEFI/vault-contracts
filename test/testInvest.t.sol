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
            0x2aA12f98795E7A65072950AfbA9d1E023D398241
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

        // Approve and supply TOKEN
        token.approve(address(aaveInteraction), amount);
        console.log("Approved %s TOKEN for AaveInteraction contract", amount);

        assertGe(
            token.allowance(USER, address(aaveInteraction)),
            amount,
            "Allowance should be equal to the approved amount"
        );

        // supply amount to aaveInteraction
        aaveInteraction.supply(TOKEN, amount);
        console.log("Supplied %s TOKEN to Aave", amount);

        // uint256 userBalance2 = token.balanceOf(USER);
        // console.log("User's TOKEN balance after supply: %s", userBalance2);

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

        assertGt(totalCollateralBase, 0, "No supply given");
        assertEq(
            atoken.balanceOf(address(aaveInteraction)),
            amount,
            "A token should be received"
        );

        // Stop impersonation
        vm.stopPrank();
        console.log("Stopped impersonating user: %s", USER);
    }

    function testSupplyAndWithdraw() public {
        console.log("== Starting testSupplyAndWithdraw ==");
        testSupply();
        // Impersonate the user
        vm.startPrank(USER);
        console.log("Impersonated user: %s", USER);

        console.log("== Starting testwithdraw ==");

        aaveInteraction.withdraw(TOKEN, amount, address(aaveInteraction));
        assertGe(
            token.balanceOf(address(aaveInteraction)),
            amount,
            "Should receive >= TOKEN at withdraw"
        );

        vm.stopPrank();
    }
}
