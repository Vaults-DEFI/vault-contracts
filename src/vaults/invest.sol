// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/aave/IPool.sol";
import "../interfaces/aave/IPoolAddressesProvider.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/uniswap/ISwapRouter.sol";

contract AaveInteraction {
    IPoolAddressesProvider public addressesProvider;
    IPool public lendingPool;

    ISwapRouter public swapRouter;

    mapping(address => mapping(address => uint256)) private userDeposits;

    function swapExactInputSingle(
        uint256 amountIn,
        address _assetIn,
        address _assetOut
    ) external returns (uint256 amountOut) {
        // msg.sender must approve this contract

        IERC20(_assetIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(_assetIn).approve(address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _assetIn,
                tokenOut: _assetOut,
                fee: 100,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    constructor(address _addressesProvider, address _swapRouter) {
        addressesProvider = IPoolAddressesProvider(_addressesProvider);
        lendingPool = IPool(addressesProvider.getPool());
        swapRouter = ISwapRouter(_swapRouter);
    }

    function supply(address _asset, uint256 _amount) external {
        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        IERC20(_asset).approve(address(lendingPool), _amount);
        lendingPool.deposit(_asset, _amount, address(this), 0);
        userDeposits[msg.sender][_asset] += _amount;
    }

    function getStake()
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return lendingPool.getUserAccountData(address(this));
    }

    function getUserDeposit(
        address _user,
        address _asset
    ) external view returns (uint256) {
        return userDeposits[_user][_asset];
    }

    function withdraw(
        address _asset,
        uint256 _amount,
        address to
    ) external returns (uint256) {
        IERC20(getATokenAddress(_asset)).approve(address(lendingPool), _amount);
        return lendingPool.withdraw(_asset, _amount, to);
    }

    function getATokenAddress(address _asset) public view returns (address) {
        IPool.ReserveData memory reserveData = lendingPool.getReserveData(
            _asset
        );
        return reserveData.aTokenAddress;
    }
}
