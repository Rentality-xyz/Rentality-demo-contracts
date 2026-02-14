// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import {ERC4626} from '@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol';
import {ERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';


contract RentalityLiquidityPool is ERC4626, Ownable {

 address public constant NATIVE_TOKEN = address(0);

    address public investmentFacet;

    /**
     * @notice The total amount of assets under management by the vault, including rewards.
     */
    uint256 private _totalAssetsUnderManagement;

    bool public freeWithdrawalMode;

    /**
     * @notice Represents a user's request to withdraw assets from the vault.
     * @param owner The original owner of the burned shares.
     * @param receiver The address that will receive the assets.
     * @param assets The amount of underlying assets requested.
     * @param createdAt The timestamp when the request was created.
     * @param fulfilled Whether the owner has fulfilled the request.
     */
    struct WithdrawalRequest {
        address owner;
        address receiver;
        uint256 amount;
        uint256 createdAt;
        bool fulfilled;
    }

    /**
     * @notice The queue of withdrawal requests.
     */
    mapping(uint256 requestId => WithdrawalRequest requestData) public withdrawalRequests;

    /**
     * @notice The index of the next withdrawal request to be added to the queue.
     */
    uint256 public nextRequestIndex;

    /**
     * @notice The index of the next withdrawal request in the queue to be fulfilled.
     */
    uint256 public nextFulfillmentIndex;

    /**
     * @notice Mapping from a user's address to the amount of assets they can claim.
     */
    mapping(address userAddress => uint256 claimableBalance) public claimableAssets;

    constructor(
        address ownerAddress,
        address investmentFacetAddress,
        address tokenAddress,
        string memory name,
        string memory symbol
    ) ERC4626(IERC20(tokenAddress)) ERC20(name, symbol) Ownable() {
        investmentFacet = investmentFacetAddress;
        _transferOwnership(ownerAddress);
    }

        function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        require(!(asset() != NATIVE_TOKEN && msg.value != 0), "Do not send ETH to non-native vault");

        // 1. Update internal accounting
        _totalAssetsUnderManagement += assets;

        // 2. Receive assets
        if (asset() == NATIVE_TOKEN) {
            if (msg.value == 0) revert("Eth amount is zero");
            if (msg.value != assets) revert("Eth amount mismatch");
        } else {
            IERC20(asset()).transferFrom(caller, address(this), assets);
        }

        // 3. Mint shares
        _mint(receiver, shares);
    }

        function _withdraw(address caller, address receiver, address owner, uint256 amount, uint256 shares)
        internal
        override
    {
        // The `caller` is already approved by `owner` to spend `shares`
        // because this function is called from `redeem` or `withdraw`.

        // 1. Update internal accounting
        _totalAssetsUnderManagement -= amount;

        // 2. Burn the user's shares
        _burn(owner, shares);
        uint256 balance = asset() == NATIVE_TOKEN ? address(this).balance : IERC20(asset()).balanceOf(address(this));
        if (freeWithdrawalMode && balance >= amount) {
            if (asset() == NATIVE_TOKEN) {
                (bool success,) = msg.sender.call{value: amount}("");
                require(success, "Failed to send ETH");
            } else {
                IERC20(asset()).transfer(msg.sender, amount);
            }

        } else {
            // 3. Create and queue the withdrawal request
            uint256 requestId = nextRequestIndex;

            withdrawalRequests[requestId] = WithdrawalRequest({
                owner: owner, receiver: receiver, amount: amount, createdAt: block.timestamp, fulfilled: false
            });

            // 4. Increment the request index
            nextRequestIndex += 1;

        }
    }

        function setFreeWithdrawalMode(bool _freeWithdrawalMode) public {
        require(msg.sender == owner() || msg.sender == investmentFacet, "Only owner or investmentFacet");
        freeWithdrawalMode = _freeWithdrawalMode;
    }

    // --- Core ERC4626 Overrides ---

    /**
     * @notice The total amount of the underlying asset the vault is accountable for.
     * @dev Returns the total amount of the underlying asset that is managed by the vault,
     * including principal deposits and any rewards added.
     * @return The total value of assets under management.
     */
    function totalAssets() public view override returns (uint256) {
        return _totalAssetsUnderManagement;
    }

      function addRewards(uint256 rewardAmount) external {
        if (msg.sender != investmentFacet && msg.sender != owner()) {
            revert("Only investmentFacet or owner can add rewards");
        }
        _totalAssetsUnderManagement += rewardAmount;
    }

        function fulfillWithdrawals(uint256 count) external onlyOwner {
        uint256 fulfillUpto = nextFulfillmentIndex + count;
        if (fulfillUpto > nextRequestIndex) {
            revert("Not enough withdrawal requests to fulfill");
        }

        for (uint256 i = nextFulfillmentIndex; i < fulfillUpto; i++) {
            WithdrawalRequest storage request = withdrawalRequests[i];
            // Skip if for some reason it's already marked fulfilled
            if (!request.fulfilled) {
                request.fulfilled = true;
                claimableAssets[request.receiver] += request.amount;
            }
        }

        nextFulfillmentIndex = fulfillUpto;
    }

    function fulfillWithdrawalsUntilHasMoney() public {
        require(msg.sender == owner() || msg.sender == investmentFacet, "Only owner or router");

        uint256 balance = asset() == NATIVE_TOKEN ? address(this).balance : IERC20(asset()).balanceOf(address(this));

        uint256 i = nextFulfillmentIndex;
        while (i < nextRequestIndex) {
            WithdrawalRequest storage request = withdrawalRequests[i];
            // Skip if for some reason it's already marked fulfilled
            if (!request.fulfilled) {
                if (request.amount > balance) {
                    break;
                }
                request.fulfilled = true;
                claimableAssets[request.receiver] += request.amount;
                balance -= request.amount;
            }
            i++;
        }
        nextFulfillmentIndex = i;

    }

    /**
     * @notice Claims assets that have been fulfilled by the owner.
     * @dev Any user can call this to claim their available assets.
     */
    function claim() external {
        uint256 amountToClaim = claimableAssets[msg.sender];
        if (amountToClaim == 0) {
            revert('No claimable assets');
        }

        claimableAssets[msg.sender] = 0;

        if (asset() == NATIVE_TOKEN) {
            if (address(this).balance < amountToClaim) {
                revert("InsufficientBalanceForClaim");
            }
            (bool success,) = msg.sender.call{value: amountToClaim}("");
            require(success, "Failed to send ETH");
        } else {
            if (IERC20(asset()).balanceOf(address(this)) < amountToClaim) {
                 revert("InsufficientBalanceForClaim");
            }
            IERC20(asset()).transfer(msg.sender, amountToClaim);
        }

    }



}