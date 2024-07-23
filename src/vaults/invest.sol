// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/aave/IPool.sol";
import "../interfaces/aave/IPoolAddressesProvider.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveInteraction {
    IPoolAddressesProvider public addressesProvider;
    IPool public lendingPool;

    mapping(address => mapping(address => uint256)) private userDeposits;

    constructor(address _addressesProvider) {
        addressesProvider = IPoolAddressesProvider(_addressesProvider);
        lendingPool = IPool(addressesProvider.getPool());
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
        return lendingPool.getUserAccountData(msg.sender);
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
