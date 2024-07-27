// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC4626Fees.sol";
import "../interfaces/aave/IPool.sol";
import "../interfaces/aave/IPoolAddressesProvider.sol";
import "../interfaces/uniswap/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is ERC4626Fees {
    IPoolAddressesProvider public addressesProvider;
    IPool public lendingPool;
    uint32 public stakeDuration;
    IERC20 public underlyingAsset;
    uint16 public referralCode;
    ISwapRouter public swapRouter;
    address public currectStake;

    constructor(
        IERC20 _asset,
        uint256 _entryBasisPoints,
        uint256 _exitBasisPoints,
        uint32 _duration,
        address _addressesProvider
    )
        ERC4626Fees(_entryBasisPoints, _exitBasisPoints)
        ERC4626(_asset)
        ERC20("Vault Token", "vFFI")
    {
        stakeDuration = _duration;
        addressesProvider = IPoolAddressesProvider(_addressesProvider);
        lendingPool = IPool(addressesProvider.getPool());
        underlyingAsset = IERC20(_asset);
    }

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

    function getATokenAddress(address _asset) public view returns (address) {
        IPool.ReserveData memory reserveData = lendingPool.getReserveData(
            _asset
        );
        return reserveData.aTokenAddress;
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

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        afterDeposit(assets);

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
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        // overridden
        require(
            getWithdrawEpoch() <= _blockTimestamp(),
            "Not eligible right now, funds can be redeem after locking period"
        );

        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        beforeWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        // overridden
        require(
            getWithdrawEpoch() <= _blockTimestamp(),
            "Not eligible right now, funds can be redeem after locking period"
        );

        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        beforeWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
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

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    // function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
    function afterDeposit(uint256 _amount) internal virtual {
        underlyingAsset.transferFrom(msg.sender, address(this), _amount);
        underlyingAsset.approve(address(lendingPool), _amount);
        lendingPool.deposit(
            address(underlyingAsset),
            _amount,
            address(this),
            referralCode
        );
    }

    function beforeWithdraw(
        uint256 _amount
    ) internal virtual returns (uint256) {
        IERC20(getATokenAddress(address(underlyingAsset))).approve(
            address(lendingPool),
            _amount
        );
        return
            lendingPool.withdraw(
                address(underlyingAsset),
                _amount,
                address(this)
            );
    }
}
