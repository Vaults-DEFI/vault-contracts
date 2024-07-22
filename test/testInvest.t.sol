// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";

import "../src/vaults/invest.sol";

contract AaveInteractionTest is Test {
    AaveInteraction aaveInteraction;
    IPoolAddressesProvider addressesProvider;
    IPool lendingPool;
    IERC20 usdc;

    // Mainnet fork configuration
    address ADDRESS_PROVIDER = vm.envAddress("PROVIDER_ADDRESS");
    address USDC = vm.envAddress("ASSET_ADDRESS");
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

        uint256 amount = 100000000;

        // Check user's USDC balance
        uint256 userBalance = usdc.balanceOf(USER);
        console.log("User's USDC balance: %s", userBalance);
        require(userBalance >= amount, "User does not have enough USDC");

        // Approve and supply USDC
        usdc.approve(address(aaveInteraction), amount);
        console.log("Approved %s USDC for AaveInteraction contract", amount);

        uint256 allowance = usdc.allowance(USER, address(aaveInteraction));
        console.log("USDC allowance for AaveInteraction: %s", allowance);
        require(allowance >= amount, "Allowance is not enough");

        aaveInteraction.supply(USDC, amount);
        console.log("Supplied %s USDC to Aave", amount);

        // Stop impersonation
        vm.stopPrank();
        console.log("Stopped impersonating user: %s", USER);

        // Add assertions to verify the result
        uint256 poolBalance = usdc.balanceOf(address(lendingPool));
        console.log("USDC balance of the lending pool: %s", poolBalance);

        // Example assertion (uncomment and modify as needed)
        // assertEq(poolBalance, amount);
    }
}
