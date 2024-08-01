// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC4626Fees.sol";
import "../interfaces/aave/IPool.sol";
import "../interfaces/aave/IPoolAddressesProvider.sol";
import "../interfaces/uniswap/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract Vault is ERC4626Fees {
    using Math for uint256;

    IPoolAddressesProvider public addressesProvider;
    IPool public lendingPool;
    uint32 public stakeDuration;
    IERC20 public underlyingAsset;
    uint16 public referralCode;
    address public currentStake;
    ISwapRouter public swapRouter;

    constructor(
        IERC20 _asset,
        uint256 _entryBasisPoints,
        uint256 _exitBasisPoints,
        uint32 _duration,
        address _addressesProvider,
        address _swapRouter
    )
        ERC4626Fees(_entryBasisPoints, _exitBasisPoints)
        ERC4626(_asset)
        ERC20("Vault Token", "vFFI")
    {
        stakeDuration = _duration;
        addressesProvider = IPoolAddressesProvider(_addressesProvider);
        lendingPool = IPool(addressesProvider.getPool());
        swapRouter = ISwapRouter(_swapRouter);
        underlyingAsset = IERC20(_asset);
        currentStake = address(_asset);
    }

    event zapDepositEvent(uint256);
    event liquidityWithdrawnEvent(uint256);
    event afterSwapEvent(uint256);
    event withdrawFromAaveEvent(uint256);
    event movedToAaveEvent(address, uint256);
    event mango(uint256);
    event apple(uint256);
    event sharesDetails(uint256, uint256);
    event beforeAaveDepositEvent(uint256);
    event afterAaveEvent(uint256);

    mapping(address lender => uint32 epoch) public stakeTimeEpochMapping;

    function getWithdrawEpoch() public view returns (uint32) {
        return stakeTimeEpochMapping[msg.sender] + stakeDuration;
    }

    function setDuration(uint32 _duration) public onlyOwner {
        stakeDuration = _duration;
    }

    // for gas efficiency
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    // function to get the aToken of the token passed
    function getATokenAddress(address _asset) public view returns (address) {
        IPool.ReserveData memory reserveData = lendingPool.getReserveData(
            _asset
        );
        return reserveData.aTokenAddress;
    }

    function zapDeposit(
        address token,
        uint256 assets,
        address receiver,
        uint24 _feeTier
    ) public returns (uint256) {
        uint256 amountOut;

        // transfer funds to the vault contract
        IERC20(token).transferFrom(msg.sender, address(this), assets);
        IERC20(token).approve(address(swapRouter), assets);
        if (token != address(underlyingAsset)) {
            amountOut = swapExactInputSingle(
                assets,
                token,
                currentStake,
                address(this),
                _feeTier
            );
            uint256 shares = previewDeposit(amountOut);
            _mint(receiver, shares);
            emit Deposit(receiver, receiver, amountOut, shares);
            afterDeposit(amountOut);
            emit zapDepositEvent(amountOut);
            return shares;
        } else {
            return deposit(assets, receiver);
        }
    }

    function reStakeToBetterPool(
        address _newTokenToInvest,
        uint24 _feeTier
    ) public onlyOwner {
        require(_newTokenToInvest != currentStake, "no point reStaking");
        IERC20(getATokenAddress(address(currentStake))).approve(
            address(lendingPool),
            type(uint256).max
        );
        uint256 withdrawAmount = lendingPool.withdraw(
            address(underlyingAsset),
            type(uint256).max,
            address(this)
        );
        emit liquidityWithdrawnEvent(withdrawAmount);
        IERC20(currentStake).approve(address(swapRouter), withdrawAmount);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: currentStake,
                tokenOut: _newTokenToInvest,
                fee: _feeTier,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: withdrawAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter.exactInputSingle(params);
        emit afterSwapEvent(amountOut);
        IERC20(_newTokenToInvest).approve(address(lendingPool), amountOut);
        lendingPool.deposit(
            _newTokenToInvest,
            amountOut,
            address(this),
            referralCode
        );
        currentStake = _newTokenToInvest;
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(
        uint256 assets
    ) public view virtual override returns (uint256) {
        uint256 fee = _feeOnTotal(assets, _entryFeeBasisPoints());

        return _convertToShares(assets - fee, Math.Rounding.Floor);
    }

    /// @dev Preview adding an entry fee on mint. See {IERC4626-previewMint}.
    function previewMint(
        uint256 shares
    ) public view virtual override returns (uint256) {
        uint256 assets = _convertToAssets(shares, Math.Rounding.Ceil);
        return assets + _feeOnRaw(assets, _entryFeeBasisPoints());
    }

    /// @dev Preview adding an exit fee on withdraw. See {IERC4626-previewWithdraw}.
    function previewWithdraw(
        uint256 assets
    ) public view virtual override returns (uint256) {
        uint256 fee = _feeOnTotal(assets, _entryFeeBasisPoints());

        return _convertToShares(assets + fee, Math.Rounding.Ceil);
    }

    /// @dev Preview taking an exit fee on redeem. See {IERC4626-previewRedeem}.
    function previewRedeem(
        uint256 shares
    ) public view virtual override returns (uint256) {
        uint256 assets = _convertToAssets(shares, Math.Rounding.Floor);
        return assets - _feeOnRaw(assets, _entryFeeBasisPoints());
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override returns (uint256) {
        require(assets > 0, "Assets can't be zero");
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        // uint256 shares = previewDeposit(assets);
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        emit beforeAaveDepositEvent(shares);
        uint256 fee = _feeOnRaw(assets, _exitFeeBasisPoints());
        afterDeposit(assets - fee);

        // overridden
        stakeTimeEpochMapping[msg.sender] = uint32(block.timestamp);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(
        uint256 shares,
        address receiver
    ) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);
        afterDeposit(assets);
        stakeTimeEpochMapping[msg.sender] = uint32(block.timestamp);
        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    /* function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        // overridden
        require(
            getWithdrawEpoch() <= _blockTimestamp(),
            "Not eligible right now, funds can be redeem after locking period"
        );
        beforeWithdraw(assets);

        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    } */

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     * function overridden to change the totalAssets()
     */
    function _convertToShares(
        uint256 assets,
        Math.Rounding rounding
    ) internal view virtual override returns (uint256) {
        return
            assets.mulDiv(
                totalSupply() + 10 ** _decimalsOffset(),
                IERC20(getATokenAddress(currentStake)).balanceOf(
                    address(this)
                ) + 1,
                rounding
            );
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     * function overridden to change the totalAssets()
     */
    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view virtual override returns (uint256) {
        return
            shares.mulDiv(
                IERC20(getATokenAddress(currentStake)).balanceOf(
                    address(this)
                ) + 1,
                totalSupply() + 10 ** _decimalsOffset(),
                rounding
            );
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(
            getWithdrawEpoch() <= _blockTimestamp(),
            "Not eligible right now, funds can be redeemed after locking period"
        );
        // uint256 maxAssets = maxWithdraw(owner);
        // if (assets > maxAssets) {
        //     revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        // }

        uint256 aTokenBalance = IERC20(getATokenAddress(currentStake))
            .balanceOf(address(this));
        uint256 totalSupplyShares = totalSupply();
        uint256 shares = _convertToShares(assets, Math.Rounding.Ceil);
        uint256 maxShares = maxRedeem(owner);
        emit sharesDetails(shares, maxShares);

        // emit mango();
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        emit mango(shares);

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        require(shares <= maxShares, "ERC4626: withdraw more than max");

        ///
        uint256 aTokensToWithdraw = (shares * aTokenBalance) /
            totalSupplyShares;

        // Burn shares and update internal accounting
        _burn(owner, shares);

        // Approve and withdraw the corresponding amount of the underlying asset from Aave
        IERC20(getATokenAddress(currentStake)).approve(
            address(lendingPool),
            aTokensToWithdraw
        );
        uint256 amountWithdrawn = lendingPool.withdraw(
            currentStake,
            aTokensToWithdraw,
            receiver
        );
        emit Withdraw(msg.sender, receiver, owner, amountWithdrawn, shares);

        return amountWithdrawn;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(
            getWithdrawEpoch() <= _blockTimestamp(),
            "Not eligible right now, funds can be redeemed after locking period"
        );
        uint256 maxShares = maxRedeem(owner);
        emit apple(maxShares);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        ///
        uint256 totalSupplyShares = totalSupply();
        uint256 aTokenBalance = IERC20(getATokenAddress(currentStake))
            .balanceOf(address(this));
        uint256 aTokensToWithdraw = (shares * aTokenBalance) /
            totalSupplyShares;

        // Burn shares and update internal accounting
        _burn(owner, shares);

        // Approve and withdraw the corresponding amount of the underlying asset from Aave
        IERC20(getATokenAddress(currentStake)).approve(
            address(lendingPool),
            aTokensToWithdraw
        );
        uint256 amountWithdrawn = lendingPool.withdraw(
            currentStake,
            aTokensToWithdraw,
            receiver
        );
        emit Withdraw(msg.sender, receiver, owner, amountWithdrawn, shares);

        return amountWithdrawn;
    }

    function changeEntryFee(uint256 _fee) public onlyOwner {
        entryFeeBasisPoints = _fee;
    }

    function changeExitFee(uint256 _fee) public onlyOwner {
        exitFeeBasisPoints = _fee;
    }

    function setReferralCode(uint16 _referralCode) public onlyOwner {
        referralCode = _referralCode;
    }

    // Just a swap function which makes a swap from uniswap
    function swapExactInputSingle(
        uint256 amountIn,
        address _assetIn,
        address _assetOut,
        address _recipient,
        uint24 _feeTier
    ) internal returns (uint256 amountOut) {
        // IERC20(_assetIn).transferFrom(msg.sender, address(this), amountIn);
        // IERC20(_assetIn).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _assetIn,
                tokenOut: _assetOut,
                fee: _feeTier,
                recipient: _recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    // function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
    function afterDeposit(uint256 _amount) internal virtual {
        // underlyingAsset.transferFrom(msg.sender, address(this), _amount);
        underlyingAsset.approve(address(lendingPool), _amount);
        lendingPool.deposit(currentStake, _amount, address(this), referralCode);
        emit movedToAaveEvent(currentStake, _amount);
    }

    function beforeWithdraw(
        uint256 _amount
    ) internal virtual returns (uint256) {
        IERC20(getATokenAddress(address(currentStake))).approve(
            address(lendingPool),
            _amount
        );

        uint256 withdrawAmount = lendingPool.withdraw(
            address(currentStake),
            _amount,
            address(this)
        );
        emit withdrawFromAaveEvent(withdrawAmount);
        return withdrawAmount;
    }
}
