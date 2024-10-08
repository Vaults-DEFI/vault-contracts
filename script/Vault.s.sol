// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../src/vaults/vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultScript is Script {
    function setUp() public {}

    function run() external {
        address assetAddress = vm.envAddress("ASSET_ADDRESS");
        uint256 entryBasisPoints = vm.envUint("ENTRY_BASIS_POINTS");
        uint256 exitBasisPoints = vm.envUint("EXIT_BASIS_POINTS");
        uint32 stakeDuration = uint32(vm.envUint("STAKE_DURATION"));
        address swapRouter = vm.envAddress("SWAP_ROUTER");
        address ADDRESS_PROVIDER = vm.envAddress("PROVIDER_ADDRESS");

        vm.startBroadcast();

        IERC20 asset = IERC20(assetAddress);
        Vault vault = new Vault(
            asset,
            entryBasisPoints,
            exitBasisPoints,
            stakeDuration,
            ADDRESS_PROVIDER,
            swapRouter
        );

        vm.stopBroadcast();
        console.log("Vault deployed at:", address(vault));
    }
}
