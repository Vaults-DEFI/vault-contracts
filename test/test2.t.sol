// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../src/vaults/invest.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract AaveInteractionTest is Test {
//     AaveInteraction public aaveInteraction;
//     IERC20 public dai;

//     address public user = address(0x123);
//     address public daiAddress = address(0x456); // Replace with actual DAI contract address
//     address public aaveProviderAddress = address(0x789); // Replace with actual Aave PoolAddressesProvider address

//     function setUp() public {
//         // Assume the initial state and deployment
//         aaveInteraction = new AaveInteraction(aaveProviderAddress);
//         dai = IERC20(daiAddress);

//         // Assume user has 1000 DAI and approve AaveInteraction contract
//         vm.deal(user, 1000 ether);
//         deal(daiAddress, user, 1000 ether);
//         vm.prank(user);
//         dai.approve(address(aaveInteraction), 1000 ether);
//     }

//     function testSupply() public {
//         uint256 amount = 100 ether;

//         vm.startPrank(user);
//         aaveInteraction.supply(daiAddress, amount);
//         vm.stopPrank();

//         uint256 deposit = aaveInteraction.getUserDeposit(user, daiAddress);
//         assertEq(deposit, amount, "Deposit amount should match");
//     }

//     function testWithdraw() public {
//         uint256 supplyAmount = 100 ether;
//         uint256 withdrawAmount = 50 ether;

//         vm.startPrank(user);
//         aaveInteraction.supply(daiAddress, supplyAmount);
//         aaveInteraction.withdraw(daiAddress, withdrawAmount, user);
//         vm.stopPrank();

//         uint256 remainingDeposit = aaveInteraction.getUserDeposit(
//             user,
//             daiAddress
//         );
//         assertEq(
//             remainingDeposit,
//             supplyAmount - withdrawAmount,
//             "Remaining deposit should match"
//         );
//     }

//     function testGetStake() public {
//         // This test assumes that there are interactions with Aave lending pool.
//         // Additional setup or mocking might be needed to fully test getStake()
//         vm.startPrank(user);
//         aaveInteraction.supply(daiAddress, 100 ether);
//         vm.stopPrank();

//         (
//             uint256 totalCollateralBase,
//             uint256 totalDebtBase,
//             uint256 availableBorrowsBase,
//             uint256 currentLiquidationThreshold,
//             uint256 ltv,
//             uint256 healthFactor
//         ) = aaveInteraction.getStake();

//         // Here you can add asserts based on expected values
//     }
// }
