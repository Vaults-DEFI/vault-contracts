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
    uint256 amount2;
    uint256 amount3;

    // Mainnet fork configuration
    address ADDRESS_PROVIDER = vm.envAddress("PROVIDER_ADDRESS");
    address TOKEN = vm.envAddress("ASSET_ADDRESS");
    address TOKEN2 = vm.envAddress("ASSET3_ADDRESS");
    address USER = vm.envAddress("PAISA_WALA");
    address USER2 = vm.envAddress("PAISA_WALA2");
    address USER3 = vm.envAddress("PAISA_WALA3");
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
        amount2 = 100000000;
        amount3 = 100000000;
        console.log("== Setup completed. ==");
    }

    // function testSwap() public {
    //     vm.startPrank(USER);
    //     console.log("Impersonated user: %s", USER);
    //     token.approve(address(vault), amount);
    //     assertGe(
    //         token.allowance(USER, address(vault)),
    //         amount,
    //         "Allowance should be equal to the approved amount"
    //     );

    //     vault.swapExactInputSingle(amount, TOKEN, TOKEN2, USER, 100);
    //     assertGt(token2.balanceOf(USER), 0, "SWAP FAILED");
    //     console.log("User BALANCE in TOKEN2: ", token2.balanceOf(USER));

    //     vm.stopPrank();
    // }

    function testDeposit() public {
        vm.startPrank(USER);

        // deal amount of TOKENs to USER
        deal(TOKEN, USER, amount);
        console.log("starting testDeposit.....");

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
        console.log("shares received at deposit", shares);
        // assertEq(vault.balanceOf(USER), 100000000, "Not received enough funds");
        // console.log("MAX WITHDRAW", vault.maxWithdraw(address(vault)));
        console.log("vault.balanceOf()", vault.balanceOf(USER));
        console.log(
            "total supply and total assets",
            vault.totalSupply(),
            vault.totalAssets()
        );
        console.log("idhar fees hai", token.balanceOf(address(vault)));
        vm.stopPrank();
        console.log("starting testDeposit done.....");
    }

    // function testDepositUser2() public {
    //     testDeposit();
    //     vm.startPrank(USER2);

    //     // deal amount of TOKENs to USER
    //     deal(TOKEN, USER2, amount);

    //     token.approve(address(vault), amount);
    //     console.log(
    //         "allowance for deposit",
    //         token.allowance(USER2, address(vault))
    //     );
    //     assertEq(
    //         token.allowance(USER2, address(vault)),
    //         amount,
    //         "not much allowance"
    //     );

    //     uint256 shares = vault.deposit(amount, USER2);
    //     console.log("shares", shares);
    //     // assertEq(vault.balanceOf(USER), 100000000, "Not received enough funds");
    //     console.log("MAX WITHDRAW", vault.maxWithdraw(address(vault)));
    //     console.log("vault token balance", vault.balanceOf(USER2));
    //     console.log(
    //         "total supply adn total assets",
    //         vault.totalSupply(),
    //         vault.totalAssets()
    //     );
    //     console.log("idhar fees hai", token.balanceOf(address(vault)));
    //     vm.stopPrank();
    // }

    // function testDepositByUser3() public {
    //     testDepositUser2();
    //     vm.startPrank(USER3);

    //     // deal amount of TOKENs to USER
    //     deal(TOKEN, USER3, amount);

    //     token.approve(address(vault), amount);
    //     console.log(
    //         "allowance for deposit",
    //         token.allowance(USER3, address(vault))
    //     );
    //     assertEq(
    //         token.allowance(USER3, address(vault)),
    //         amount,
    //         "not much allowance"
    //     );

    //     uint256 shares = vault.deposit(amount, USER3);
    //     console.log("shares", shares);
    //     // assertEq(vault.balanceOf(USER), 100000000, "Not received enough funds");
    //     console.log("MAX WITHDRAW", vault.maxWithdraw(address(vault)));
    //     console.log("vault token balance", vault.balanceOf(USER3));
    //     console.log(
    //         "total supply and total assets:",
    //         vault.totalSupply(),
    //         vault.totalAssets()
    //     );
    //     console.log("idhar fees hai", token.balanceOf(address(vault)));
    //     vm.stopPrank();
    // }

    // function testZapInDeposit() public {
    //     vm.startPrank(USER);
    //     deal(TOKEN2, USER, 100000000000000000000);
    //     console.log("balance of user in token2", token2.balanceOf(USER));
    //     token2.approve(address(vault), 100000000000000000000);
    //     console.log("allowance done");
    //     console.log("Allowance: ", token2.allowance(USER, address(vault)));

    //     vault.zapDeposit(address(token2), 100000000000000000000, USER, 100);
    //     console.log(
    //         "contract balance of aToken2 ",
    //         IERC20(vault.getATokenAddress(TOKEN)).balanceOf(address(vault))
    //     );

    //     vm.stopPrank();
    // }

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

    // function testRedeem() public {
    //     testDeposit();
    //     vm.startPrank(USER);
    //     console.log("gonna go withdraw==============================");
    //     vault.redeem(amount, USER, USER);
    //     console.log("withdraw done==============================");

    //     console.log(
    //         "atoken balance after withdraw",
    //         IERC20(vault.getATokenAddress(TOKEN)).balanceOf(address(vault))
    //     );

    //     console.log("vToken balance after withdraw", vault.balanceOf(USER));
    //     console.log("USDC balance after withdraw", token.balanceOf(USER));
    //     vm.stopPrank();
    // }

    function testWithdraw() public {
        testDeposit();
        vm.startPrank(USER);
        console.log("gonna go withdraw==============================");
        // uint256 assets = vault.balanceOf(USER);
        uint256 assets = IERC20(vault.getATokenAddress(TOKEN2)).balanceOf(
            address(vault)
        );

        console.log("total assets to withdraw--->", assets);
        vault.withdraw(assets, USER, USER);
        console.log("withdraw done==============================");
        console.log(
            "atoken balance after withdraw",
            IERC20(vault.getATokenAddress(TOKEN2)).balanceOf(address(vault))
        );
        console.log("vToken balance after withdraw", vault.balanceOf(USER));
        console.log("USDC balance after withdraw", token2.balanceOf(USER));
        vm.stopPrank();
    }

    // function testClassicWithdraw() public {
    //     testDeposit();
    //     vm.startPrank(USER);
    //     console.log("gonna go withdraw==============================");
    //     uint256 assets = IERC20(vault.getATokenAddress(TOKEN)).balanceOf(
    //         address(vault)
    //     );

    //     console.log("total assets to withdraw", assets);
    //     vault.withdraw(assets, USER, USER);
    //     console.log("withdraw done==============================");
    //     console.log(
    //         "atoken balance after withdraw",
    //         IERC20(vault.getATokenAddress(TOKEN2)).balanceOf(address(vault))
    //     );
    //     console.log("vToken balance after withdraw", vault.balanceOf(USER));
    //     console.log("USDC balance after withdraw", token2.balanceOf(USER));
    //     vm.stopPrank();
    // }

    // function testRedeem2() public {
    //     console.log("deposit done from 2");
    //     testReStakeToBetterPool();
    //     vm.startPrank(USER);
    //     console.log("gonna go withdraw==============================");
    //     vault.redeem(amount, USER, USER);
    //     console.log("withdraw done==============================");

    //     console.log("TOKEN2 balance after withdraw", token2.balanceOf(USER));
    //     vm.stopPrank();
    // }

    // function testWithdraw2() public {
    //     console.log("deposit done from 2");
    //     testReStakeToBetterPool();
    //     vm.startPrank(USER);
    //     console.log("gonna go withdraw==============================");
    //     vault.redeem(amount, USER, USER);
    //     console.log("withdraw done==============================");

    //     console.log("TOKEN2 balance after withdraw", token2.balanceOf(USER));
    //     vm.stopPrank();
    // }

    function testDRD() public {
        testReStakeToBetterPool();
        console.log("=====pool changed=====");
        // testDeposit();
        testWithdraw();
        console.log("=====DRD DONE=====");
    }
}
