// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";

import "../src/vaults/vault.sol";

contract VaultTest is Test {
    Vault vault;
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
        vault = Vault(0xAAF0F531b7947e8492f21862471d61d5305f7538);

        console.log("Deployed Vault contract at: %s", address(vault));

        // setting up underlying token
        token = IERC20(TOKEN);
        console.log("TOKEN Address: %s", TOKEN);

        // setting up supply/withdraw amount
        amount = 100000000;
        console.log("Setup completed.");
    }

    function testDeposit() public {
        vm.startPrank(USER);

        // deal amount of TOKENs to USER
        deal(TOKEN, USER, amount);
        console.log(token.balanceOf(USER));

        token.approve(address(vault), amount);
        assertEq(
            token.allowance(USER, address(vault)),
            amount,
            "not much allowance"
        );
        vault.deposit(amount, USER);
        assertEq(vault.balanceOf(USER), 99009900, "Not received enough funds");
        vm.stopPrank();
    }

    function testWithdraw() public {
        testDeposit();
        vm.startPrank(USER);

        vm.stopPrank();
    }
}
