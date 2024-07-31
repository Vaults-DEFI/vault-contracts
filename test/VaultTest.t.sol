// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";

import "../src/vaults/vault.sol";

contract VaultTest is Test {
    Vault vault;
    IERC20 token;
    IERC20 atoken;
    IERC20 token2;
    uint256 amount;

    // Mainnet fork configuration
    address ADDRESS_PROVIDER = vm.envAddress("PROVIDER_ADDRESS");
    address TOKEN = vm.envAddress("ASSET_ADDRESS");
    address TOKEN2 = vm.envAddress("ASSET3_ADDRESS");
    address USER = vm.envAddress("PAISA_WALA");
    address SWAP_ROUTER = vm.envAddress("SWAP_ROUTER");

    function setUp() public {
        console.log("==SET UP(testInvest.t.sol)==");

        // contract instance
        token = IERC20(TOKEN);
        vault = new Vault(token, 0, 0, 0, ADDRESS_PROVIDER, SWAP_ROUTER);

        console.log("Deployed Vault contract at: %s", address(vault));

        // setting up underlying token
        console.log("TOKEN Address: %s", TOKEN);

        // setting up token2 (take USDT for eg)
        token2 = IERC20(TOKEN2);

        // setting up supply/withdraw amount
        amount = 100000000;
        console.log("== Setup completed. ==");
    }

    function testSwap() public {
        vm.startPrank(USER);
        console.log("Impersonated user: %s", USER);
        token.approve(address(vault), amount);
        assertGe(
            token.allowance(USER, address(vault)),
            amount,
            "Allowance should be equal to the approved amount"
        );

        vault.swapExactInputSingle(amount, TOKEN, TOKEN2, USER, 100);
        assertGt(token2.balanceOf(USER), 0, "SWAP FAILED");
        console.log("User BALANCE in TOKEN2: ", token2.balanceOf(USER));

        vm.stopPrank();
    }

    function testDeposit() public {
        vm.startPrank(USER);

        // deal amount of TOKENs to USER
        deal(TOKEN, USER, amount);

        token.approve(address(vault), amount);
        console.log(
            "allowance for deposit",
            token.allowance(USER, address(vault))
        );
        assertEq(
            token.allowance(USER, address(vault)),
            amount,
            "not much allowance"
        );

        uint256 shares = vault.deposit(amount, USER);
        console.log("shares", shares);
        assertEq(vault.balanceOf(USER), 100000000, "Not received enough funds");
        console.log("MAX WITHDRAW", vault.maxWithdraw(address(vault)));
        console.log("vault token balance", vault.balanceOf(USER));
        vm.stopPrank();
    }

    function testZapInDeposit() public {
        vm.startPrank(USER);
        deal(TOKEN2, USER, 100000000000000000000);
        console.log("balance of user in token2", token2.balanceOf(USER));
        token2.approve(address(vault), 100000000000000000000);
        console.log("allowance done");
        console.log("Allowance: ", token2.allowance(USER, address(vault)));

        vault.zapDeposit(address(token2), 100000000000000000000, USER, 100);
        console.log(
            "contract balance of aToken2 ",
            IERC20(vault.getATokenAddress(TOKEN)).balanceOf(address(vault))
        );

        vm.stopPrank();
    }

    function testReStakeToBetterPool() public {
        // vm.startPrank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        testDeposit();
        vault.reStakeToBetterPool(TOKEN2, 100);
        console.log(
            "A2: ",
            IERC20(vault.getATokenAddress(TOKEN2)).balanceOf(address(vault))
        );
        // vm.stopPrank();
    }

    function testWithdraw() public {
        testDeposit();
        vm.startPrank(USER);
        console.log("gonna go withdraw==============================");
        vault.withdrawAToken(amount, USER);
        console.log("withdraw done==============================");

        console.log(
            "atoken balance after withdraw",
            IERC20(vault.getATokenAddress(TOKEN)).balanceOf(address(vault))
        );
        console.log("vToken balance after withdraw", vault.balanceOf(USER));
        console.log("USDC balance after withdraw", token.balanceOf(USER));
        vm.stopPrank();
    }

    function testWithdraw2() public {
        console.log("deposit done from 2");
        testReStakeToBetterPool();
        vm.startPrank(USER);
        console.log("gonna go withdraw==============================");
        vault.withdrawAToken(amount, USER);
        console.log("withdraw done==============================");

        console.log("TOKEN2 balance after withdraw", token2.balanceOf(USER));
        vm.stopPrank();
    }
}
