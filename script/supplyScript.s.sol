// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {AaveInteraction} from "../src/vaults/invest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultScript is Script {
    function setUp() public {}

    address PROVIDER_ADDRESS = vm.envAddress("PROVIDER_ADDRESS");
    address USDC = vm.envAddress("ASSET_ADDRESS");
    uint256 USER = vm.envUint("PVT_KEY");
    address USER_ADDRESS = vm.envAddress("ANVIL");

    IERC20 usdc;

    function run() external {
        vm.startBroadcast(USER);

        // Deploy the contract
        AaveInteraction aaveInteraction = new AaveInteraction(PROVIDER_ADDRESS);

        console.log("Starting testDeployAndSupply");

        // Deploy the contract
        console.log(
            "Deployed AaveInteraction contract at: %s",
            address(aaveInteraction)
        );

        // Ensure the user has some USDC
        uint256 amount = 1000000; // 1000 USDC
        usdc = IERC20(USDC);

        // Check if USDC address is valid
        console.log("USDC address:", USDC);
        console.log("Checking total supply of USDC...");

        // Check total supply of USDC
        uint256 totalSupply;
        try usdc.totalSupply() returns (uint256 supply) {
            totalSupply = supply;
            console.log("Total supply of USDC:", totalSupply);
        } catch {
            console.log("Error: Failed to get total supply of USDC.");
            return;
        }

        // Check user's USDC balance
        console.log("Checking user's USDC balance...");
        uint256 userBalance = usdc.balanceOf(USER_ADDRESS);
        console.log("User's USDC balance:", userBalance);

        // Ensure user has enough USDC
        require(userBalance >= amount, "User does not have enough USDC");

        // Approve and supply USDC
        console.log("Approving USDC...");
        usdc.approve(address(aaveInteraction), amount);
        console.log("Approved %s USDC for AaveInteraction contract", amount);

        uint256 allowance = usdc.allowance(
            USER_ADDRESS,
            address(aaveInteraction)
        );
        console.log("USDC allowance for AaveInteraction: %s", allowance);
        require(allowance >= amount, "Allowance is not enough");

        aaveInteraction.supply(USDC, amount);
        console.log("Supplied %s USDC to Aave", amount);

        // Add assertions to verify the result
        uint256 userSupply = aaveInteraction.getUserDeposit(USER_ADDRESS, USDC);
        console.log("USDC balance of the lending pool: %s", userSupply);

        vm.stopBroadcast();
        console.log("Vault deployed at:", address(aaveInteraction));
    }
}
