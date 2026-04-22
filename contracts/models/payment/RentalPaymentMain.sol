// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/base/payment/PaymentBase.sol';
import '../common/Schemas.sol';
import './RentalPaymentTypes.sol';

interface IRentalPaymentAccess {
    function isAdmin(address user) external view returns (bool);
    function isRentalityPlatform(address user) external view returns (bool);
}

interface IRentalPaymentInvestmentPool {
    function deposit(uint256 totalIncome, uint256 depositToPool) external payable;
}

interface IRentalPaymentInvestmentService {
    function getPaymentsInfo(uint256 carId)
        external
        view
        returns (uint256 percents, IRentalPaymentInvestmentPool pool, address currency);
}

interface IRentalPaymentInsuranceService {
    function calculateCurrentHostInsuranceSumFrom(address user, uint256 amount) external view returns (uint256);
    function updateUserInsuranceAverage(address user, uint256 tripId, uint256 value) external payable;
}

interface IRentalPaymentSwaps {
    function swapExactInputSingle(
        address from,
        address to,
        uint128 amountIn,
        address sender,
        uint128 minimumAmountOut,
        uint24 fee
    ) external payable returns (uint256 amountOut);
}

interface IRentalPaymentProfileMain {
    function isCommissionPaidForUser(address user) external view returns (bool);
    function payCommission(address user) external;
}

contract RentalPaymentMain is PaymentBase, UUPSOwnable {
    IRentalPaymentAccess public userAccess;
    IRentalPaymentProfileMain public profileMain;
    IRentalPaymentInvestmentService public investmentService;
    IRentalPaymentInsuranceService public insuranceService;
    IRentalPaymentSwaps public rentalitySwaps;

    error OnlyAdmin();
    error OnlyPlatform();
    error CommissionAlreadyPaid(address user);
    error NotEnoughAllowance(address currencyType, address user, uint256 amount);
    error WrongCurrencyType(address expected, address actual);
    error RefundFailed(address user, uint256 amount);

    modifier onlyAdmin() {
        if (!userAccess.isAdmin(msg.sender)) {
            revert OnlyAdmin();
        }
        _;
    }

    modifier onlyPlatform() {
        if (!userAccess.isRentalityPlatform(msg.sender)) {
            revert OnlyPlatform();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address userAccessAddress,
        address profileMainAddress,
        address investmentServiceAddress,
        address insuranceServiceAddress,
        address swapsAddress
    ) public initializer {
        __Ownable_init();
        userAccess = IRentalPaymentAccess(userAccessAddress);
        profileMain = IRentalPaymentProfileMain(profileMainAddress);
        investmentService = IRentalPaymentInvestmentService(investmentServiceAddress);
        insuranceService = IRentalPaymentInsuranceService(insuranceServiceAddress);
        rentalitySwaps = IRentalPaymentSwaps(swapsAddress);
    }

    function withdrawFromTreasury(uint256 amount, address currencyType, address receiver)
        public
        override
        onlyAdmin
    {
        _withdrawFromTreasury(amount, currencyType, receiver);
    }

    function withdrawFromPlatform(uint256 amount, address currencyType) external onlyAdmin {
        _withdrawFromTreasury(amount, currencyType, owner());
    }

    function setSwapContracts(address swapsAddress) external onlyAdmin {
        rentalitySwaps = IRentalPaymentSwaps(swapsAddress);
    }

    function setInsuranceService(address insuranceServiceAddress) external onlyAdmin {
        insuranceService = IRentalPaymentInsuranceService(insuranceServiceAddress);
    }

    function updateUserAccess(address userAccessAddress) external onlyOwner {
        userAccess = IRentalPaymentAccess(userAccessAddress);
    }

    function updateProfileMain(address profileMainAddress) external onlyOwner {
        profileMain = IRentalPaymentProfileMain(profileMainAddress);
    }

    function updateInvestmentService(address investmentServiceAddress) external onlyOwner {
        investmentService = IRentalPaymentInvestmentService(investmentServiceAddress);
    }

    function payKycCommission(uint256 valueInCurrency, address currencyType, address user) external payable onlyPlatform {
        if (profileMain.isCommissionPaidForUser(user)) {
            revert CommissionAlreadyPaid(user);
        }

        if (currencyType == address(0)) {
            _checkNativeAmount(valueInCurrency);
        } else {
            _requireAllowance(currencyType, user, valueInCurrency);
            bool success = _pullCurrencyFrom(currencyType, user, valueInCurrency);
            require(success, 'Fail to pay');
        }

        profileMain.payCommission(user);
    }

    function payCreateTrip(
        address currencyType,
        uint256 valueSumInCurrency,
        address user,
        uint256 carId,
        address currencyFrom,
        uint256 amountIn,
        uint24 fee
    ) external payable onlyPlatform {
        (, IRentalPaymentInvestmentPool pool, address poolCurrency) = investmentService.getPaymentsInfo(carId);
        if (address(pool) != address(0) && poolCurrency != currencyType) {
            revert WrongCurrencyType(poolCurrency, currencyType);
        }

        if (currencyFrom != currencyType) {
            if (currencyFrom != address(0)) {
                bool pulled = _pullCurrencyFrom(currencyFrom, user, amountIn);
                require(pulled, 'Transfer failed.');
                IERC20(currencyFrom).approve(address(rentalitySwaps), amountIn);
            }

            rentalitySwaps.swapExactInputSingle{value: msg.value}(
                currencyFrom,
                currencyType,
                uint128(amountIn),
                address(this),
                uint128(valueSumInCurrency),
                fee
            );
            return;
        }

        if (currencyType == address(0)) {
            _checkNativeAmount(valueSumInCurrency);
            return;
        }

        _requireAllowance(currencyType, user, valueSumInCurrency);
        bool success = _pullCurrencyFrom(currencyType, user, valueSumInCurrency);
        require(success, 'Transfer failed.');
    }

    function payFinishTrip(
        Schemas.Trip memory trip,
        uint256 valueToHost,
        uint256 valueToGuest,
        uint256 totalIncome,
        uint256 tripCostValue
    ) external payable onlyPlatform {
        bool successHost;
        bool successGuest;
        (uint256 hostPercents, IRentalPaymentInvestmentPool pool, address currency) = investmentService.getPaymentsInfo(
            trip.carId
        );

        if (address(pool) != address(0)) {
            uint256 valueToPay = totalIncome - ((totalIncome * 20) / 100);
            uint256 depositToPool = valueToPay - ((valueToPay * hostPercents) / 100);
            valueToHost = valueToHost - depositToPool;

            if (currency == address(0)) {
                pool.deposit{value: depositToPool}(totalIncome, depositToPool);
            } else {
                bool successPool = IERC20(currency).transfer(address(pool), depositToPool);
                require(successPool, 'fail to deposit to pool');
                pool.deposit(totalIncome, depositToPool);
            }
        }

        uint256 toInsurance = 0;
        if (address(pool) == address(0)) {
            toInsurance = insuranceService.calculateCurrentHostInsuranceSumFrom(trip.host, tripCostValue);
        }

        if (trip.paymentInfo.currencyType == address(0)) {
            if (valueToHost > 0) {
                if (toInsurance > 0) {
                    valueToHost = valueToHost - toInsurance;
                    insuranceService.updateUserInsuranceAverage{value: toInsurance}(trip.host, trip.tripId, toInsurance);
                }
                (successHost, ) = payable(trip.host).call{value: valueToHost}("");
            } else {
                successHost = true;
            }

            if (valueToGuest > 0) {
                (successGuest, ) = payable(trip.guest).call{value: valueToGuest}("");
            } else {
                successGuest = true;
            }
        } else {
            if (toInsurance > 0) {
                valueToHost = valueToHost - toInsurance;
                insuranceService.updateUserInsuranceAverage(trip.host, trip.tripId, toInsurance);
                IERC20(trip.paymentInfo.currencyType).transfer(address(insuranceService), toInsurance);
            }

            successHost = IERC20(trip.paymentInfo.currencyType).transfer(trip.host, valueToHost);
            successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToGuest);
        }

        require(successHost && successGuest, 'Transfer failed.');
    }

    function payClaim(
        Schemas.Trip memory trip,
        uint256 valueToPay,
        uint256 feeInCurrency,
        uint256 commission,
        address user
    ) external payable onlyPlatform {
        bool successHost;
        address to = user == trip.host ? trip.guest : trip.host;

        if (trip.paymentInfo.currencyType == address(0)) {
            _checkNativeAmount(valueToPay);
            (successHost, ) = payable(to).call{value: valueToPay - feeInCurrency}("");

            if (msg.value > valueToPay) {
                uint256 excessValue = msg.value - valueToPay;
                (bool successRefund, ) = payable(user).call{value: excessValue}("");
                if (!successRefund) {
                    revert RefundFailed(user, excessValue);
                }
            }
        } else {
            _requireAllowance(trip.paymentInfo.currencyType, user, valueToPay);
            successHost = IERC20(trip.paymentInfo.currencyType).transferFrom(user, to, valueToPay - feeInCurrency);
            if (commission != 0) {
                bool successPlatform = IERC20(trip.paymentInfo.currencyType).transferFrom(user, to, feeInCurrency);
                require(successPlatform, 'Fail to transfer fee.');
            }
        }

        require(successHost, 'Transfer to host failed.');
    }

    function payRejectTrip(Schemas.Trip memory trip, uint256 valueToReturnInToken) external onlyPlatform {
        bool successGuest;
        if (trip.paymentInfo.currencyType == address(0)) {
            (successGuest, ) = payable(trip.guest).call{value: valueToReturnInToken}("");
        } else {
            successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToReturnInToken);
        }

        require(successGuest, 'Transfer to guest failed.');
    }

    function _requireAllowance(address currencyType, address user, uint256 amount) internal view {
        if (IERC20(currencyType).allowance(user, address(this)) < amount) {
            revert NotEnoughAllowance(currencyType, user, amount);
        }
    }
}


