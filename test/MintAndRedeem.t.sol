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
    uint256 shares;

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
        shares=100000000;
        console.log("== Setup completed. ==");
    }

   

    function testMint() public {
        vm.startPrank(USER);

        // deal amount of TOKENs to USER
        deal(TOKEN, USER, amount *5);
       
        token.approve(address(vault), amount *5);
     

        
      

        console.log(
            "allowance for deposit",
            token.allowance(USER, address(vault))
        );
        // assertEq(
        //     token.allowance(USER, address(vault)),
        //     amount,
        //     "not much allowance"
        // );

        uint256 assets = vault.mint(shares, USER);
        uint256 assets1 = vault.mint(shares, USER);
        uint256 assets2 = vault.mint(shares, USER);

        uint256 assets3 = vault.mint(shares, USER);
        

       

        console.log("assets minted", assets);
        console.log("Balance of Aave token in contract",IERC20(vault.getATokenAddress(TOKEN)).balanceOf(address(vault)));

        uint256 assets4 = vault.mint(shares, USER);
        console.log("asset minted",assets2);
        console.log("Balance of Aave token in contract after second time mint",IERC20(vault.getATokenAddress(TOKEN)).balanceOf(address(vault)));

        console.log("Balance of Aave token in contract",IERC20(vault.getATokenAddress(TOKEN)).balanceOf(address(vault)));
        console.log("vault token (vffitoken) balance of User", vault.balanceOf(USER)); //vffitoken
        console.log(
            "total supply of (vffitoken)",
            vault.totalSupply()
        );
        vm.stopPrank();

        
    }

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

}
