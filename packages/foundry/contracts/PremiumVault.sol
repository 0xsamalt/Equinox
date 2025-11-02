// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { EquinoxProtocol } from "./Equinox.sol";

contract PremiumVault is ERC4626, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public equinoxProtocol;

    // events
    event PremiumDeposited(address indexed payer, uint256 assets, uint256 sharesMinted);
    event PayoutWithdrawn(address indexed protocolCaller, address indexed to, uint256 assets, uint256 sharesBurned);
    event EquinoxProtocolUpdated(address indexed oldAddr, address indexed newAddr);
    event EmergencyWithdraw(address indexed to, uint256 amount);

    // errors
    error PremiumVault__ZeroDeposit();
    error PremiumVault__DepositTooSmall();

    modifier onlyDeRiskProtocol() {
        require(msg.sender == equinoxProtocol, "PremiumVault: caller not DeRiskProtocol");
        _;
    }

    // Initializing underlying asset, name, symbol
    constructor(IERC20 _asset, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        ERC4626(_asset)
        Ownable(msg.sender)
    { }

    // Deposits premiums into teh vault
    // Mints shares to the itself
    // here amount is the amount of underlying asset(initialized in the constructor) being deposited
    function depositPremium(uint256 amount) external nonReentrant returns (uint256 shares) {
        if (amount == 0) {
            revert PremiumVault__ZeroDeposit();
        }

        // compute corresponding shares using ERC4626 logic
        shares = convertToShares(amount);

        // SOLVING ROUNDING ISSUE OF ERC-4626
        // if rounding issues produce 0 shares for a non-zero deposit, use deposit hooks
        if (shares == 0 && totalSupply() == 0) {
            // initial deposit edge-case: mint 1 share at least
            shares = 1;
        } else if (shares == 0) {
            // if convertToShares returned 0 due to rounding but amount > 0, compute via previewDeposit
            shares = previewDeposit(amount);
            if (shares > 0) {
                revert PremiumVault__DepositTooSmall();
            }
        }

        // mints shares to the vault itself
        _deposit(msg.sender, address(this), amount, shares);

        emit PremiumDeposited(msg.sender, amount, shares);
    }

    // function callable only by deRiskProtocol to withdraw assets for payout
    // to: is the address receving the payout
    // amount: is the amount of underlying asset to be withdrawn
    function withdrawForPayout(address to, uint256 amount) external nonReentrant onlyDeRiskProtocol {
        require(to != address(0), "PremiumVault: invalid to");
        if (amount == 0) {
            revert PremiumVault__ZeroDeposit();
        }

        // compute shares required for desired assets using ERC4626 preview
        uint256 shares = previewWithdraw(amount);
        // If previewWithdraw returns 0 but assets > 0 (rare rounding), ensure at least 1 share
        if (shares == 0) {
            shares = 1;
        }

        // internal withdraw: caller = msg.sender (DeRiskProtocol), receiver = `to`, owner = owner()
        _withdraw(address(this), to, address(this), amount, shares);

        emit PayoutWithdrawn(msg.sender, to, amount, shares);
    }

    function setDeRiskProtocol(address _deRiskProtocol) external onlyOwner {
        require(_deRiskProtocol != address(0), "PremiumVault: zero address");
        address old = equinoxProtocol;
        equinoxProtocol = _deRiskProtocol;
        emit EquinoxProtocolUpdated(old, _deRiskProtocol);
    }

    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "PremiumVault: invalid recipient");
        require(amount > 0, "PremiumVault: zero amount");

        if (token == address(0)) {
            // In case ETH is somehow sent to contract
            (bool success,) = to.call{ value: amount }("");
            require(success, "PremiumVault: ETH transfer failed");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }

        emit EmergencyWithdraw(to, amount);
    }

    /* ========== VIEW HELPERS ========== */

    // Returns total assets in the vault
    function totalAssetsInVault() external view returns (uint256) {
        return totalAssets();
    }
}
