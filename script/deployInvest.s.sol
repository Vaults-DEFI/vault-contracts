// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {AaveInteraction} from "../src/vaults/invest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultScript is Script {
    function setUp() public {}

    address ADDRESS_PROVIDER = vm.envAddress("PROVIDER_ADDRESS");

    function run() external {
        vm.startBroadcast();

        // Deploy the contract
        AaveInteraction aaveInteraction = new AaveInteraction(ADDRESS_PROVIDER);

        vm.stopBroadcast();
        console.log("Vault deployed at:", address(aaveInteraction));
    }
}
