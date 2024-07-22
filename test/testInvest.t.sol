// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";

import "../src/vaults/invest.sol";

contract AaveInteractionTest is Test {
    AaveInteraction aaveInteraction;
    IPoolAddressesProvider addressesProvider;
    IPool lendingPool;
    IERC20 usdc;
    IERC20 aUsdc;

    struct data {
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
    }

    // Mainnet fork configuration
    address ADDRESS_PROVIDER = vm.envAddress("PROVIDER_ADDRESS");
    address USDC = vm.envAddress("ASSET_ADDRESS");
    address aUSDC = vm.envAddress("A_ASSET_ADDRESS");
    address USER = vm.envAddress("PAISA_WALA");

    function setUp() public {
        console.log("Setting up the test...");

        addressesProvider = IPoolAddressesProvider(ADDRESS_PROVIDER);
        console.log("Addresses Provider Address: %s", ADDRESS_PROVIDER);

        address poolAddress = addressesProvider.getPool();
        console.log("Retrieved Pool Address: %s", poolAddress);
        lendingPool = IPool(poolAddress);
        console.log("Lending Pool Address: %s", address(lendingPool));

        usdc = IERC20(USDC);

        console.log("USDC Address: %s", USDC);

        console.log("Setup completed.");
    }

    function testDeployAndSupply() public {
        console.log("Starting testDeployAndSupply");

        // Impersonate the user
        vm.startPrank(USER);
        console.log("Impersonated user: %s", USER);

        // Deploy the contract
        aaveInteraction = new AaveInteraction(ADDRESS_PROVIDER);
        console.log(
            "Deployed AaveInteraction contract at: %s",
            address(aaveInteraction)
        );

        address aUsdcAddress = aaveInteraction.getATokenAddress(USDC);
        aUsdc = IERC20(aUsdcAddress);
        console.log("aUSDC Address: %s", aUsdcAddress);

        uint256 amount = 100000000;

        // Check user's USDC balance
        uint256 userBalance = usdc.balanceOf(USER);
        console.log("User's USDC balance beforw=e: %s", userBalance);
        require(userBalance >= amount, "User does not have enough USDC");

        // Approve and supply USDC
        usdc.approve(address(aaveInteraction), amount);
        console.log("Approved %s USDC for AaveInteraction contract", amount);

        uint256 allowance = usdc.allowance(USER, address(aaveInteraction));
        console.log("USDC allowance for AaveInteraction: %s", allowance);
        require(allowance >= amount, "Allowance is not enough");

        aaveInteraction.supply(USDC, amount);
        console.log("Supplied %s USDC to Aave", amount);

        uint256 userBalance2 = usdc.balanceOf(USER);
        console.log("User's USDC balance after supply: %s", userBalance2);

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

        // uint256 abalance = aUsdc.balanceOf(USER);
        // console.log("aToken balance: ", abalance);

        // uint256 aTokenBalance = aUsdc.balanceOf(USER);
        // console.log("aToken balance before withdrawal: %s", aTokenBalance);

        // aUsdc.approve(address(aaveInteraction), aTokenBalance);

        // uint256 allowanceAusdc = aUsdc.allowance(
        //     USER,
        //     address(aaveInteraction)
        // );
        // console.log("aUSDC allowance for AaveInteraction: %s", allowanceAusdc);

        aaveInteraction.withdraw(USDC, 100000000, address(aaveInteraction));
        // console.log("Withdrew %s USDC from Aave", aTokenBalance);

        uint256 userBalance3 = usdc.balanceOf(USER);
        console.log("User's USDC balance after withdraw: %s", userBalance3);
        // Stop impersonation

        vm.stopPrank();
        console.log("Stopped impersonating user: %s", USER);

        // Add assertions to verify the result

        // Example assertion (uncomment and modify as needed)
        // assertEq(poolBalance, amount);
    }
}
