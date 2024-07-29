To get the deployed addresses of AAVE: https://docs.aave.com/developers/deployed-contracts/deployed-contracts

V3 ADDRESSES: https://docs.aave.com/developers/deployed-contracts/v3-mainnet

```shell
cast rpc anvil_impersonateAccount $PAISA_WALA
```

```shell
cast call $ASSET_ADDRESS "balanceOf(address)(uint256)" $ANVIL
```

```shell
cast send $ASSET_ADDRESS --from $PAISA_WALA "transfer(address,uint256)(bool)" $ANVIL 1000000000 --unlocked
```

```shell
forge script script/supplyScript.s.sol --rpc-url $RPC_URL
```

```shell
forge script script/deployInvest.s.sol --rpc-url $RPC_URL --broadcast --private-key $PVT_KEY
```

```shell
forge test --rpc-url $RPC_URL -vv
```

# things left to do

- **Accept Multiple Stablecoins**: Modify the contract to accept USDC, USDT, and DAI.
- **Token Conversion**: Implement functionality to swap the deposited stablecoins into a single underlying token (e.g., USDC) using Uniswap.
- **Deposit Functionality**: Ensure the converted USDC is deposited into Aave.
- **Withdraw Functionality**: Implement withdrawal logic that calculates the correct amount of tokens to return to the user based on their shares, including any profits realized.
- **Yield Calculation**: Calculate and realize any profits made during the withdrawal process.
