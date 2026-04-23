// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../base/insurance/InsuranceBase.sol';
import './InsuranceTypes.sol';

interface IInsuranceAccess {
    function isAdmin(address user) external view returns (bool);
    function isRentalityPlatform(address user) external view returns (bool);
}

interface IInsuranceCarQuery {
    function getOwner(uint256 carId) external view returns (address);
}

contract InsuranceMain is InsuranceBase, UUPSOwnable {
    IInsuranceAccess public userAccess;
    IInsuranceCarQuery public carQuery;

    uint256 public insuranceRuleId;
    mapping(uint256 => InsuranceRule) private insuranceIdToRule;
    mapping(address => uint256) private userToInsuranceRuleId;
    mapping(address => InsuranceAverage) private userToInsuranceAverage;
    mapping(uint256 => bool) private claimIdIsInsuranceClaim;
    uint256[] private insuranceClaims;
    mapping(uint256 => uint256) private tripIdToInsuranceValuePaid;

    error OnlyAdmin();
    error OnlyPlatform();
    error NotCarOwner(uint256 carId, address expectedOwner, address actualUser);
    error InvalidInsuranceType();
    error InsuranceRuleNotFound(uint256 insuranceId);
    error HostHasNoInsuranceRule(address host);
    error HostInsuranceAverageIsZero(address host);

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

    function initialize(address userAccessAddress, address carQueryAddress) public initializer {
        __Ownable_init();
        userAccess = IInsuranceAccess(userAccessAddress);
        carQuery = IInsuranceCarQuery(carQueryAddress);

        insuranceRuleId = 1;
        insuranceIdToRule[1] = InsuranceRule({partToInsurance: 40, insuranceId: 1});
    }

    function updateUserAccess(address userAccessAddress) external onlyOwner {
        userAccess = IInsuranceAccess(userAccessAddress);
    }

    function updateCarQuery(address carQueryAddress) external onlyOwner {
        carQuery = IInsuranceCarQuery(carQueryAddress);
    }

    function saveInsuranceRequired(uint256 carId, uint256 priceInUsdCents, bool required, address user) external onlyPlatform {
        address owner = carQuery.getOwner(carId);
        if (owner != user) {
            revert NotCarOwner(carId, owner, user);
        }

        _saveInsuranceRequirement(carId, InsuranceRequirement({required: required, priceInUsdCents: priceInUsdCents}));
    }

    function saveGuestInsurance(SaveInsuranceRequest memory insuranceInfo, address user) external onlyPlatform {
        if (insuranceInfo.insuranceType == InsuranceType.OneTime) {
            revert InvalidInsuranceType();
        }

        InsuranceInfo[] storage insurances = _userInsuranceInfo(user);
        if (insuranceInfo.insuranceType == InsuranceType.None) {
            if (insurances.length > 0) {
                insurances[insurances.length - 1].insuranceType = insuranceInfo.insuranceType;
            }
            return;
        }

        if (insurances.length > 0) {
            insurances[insurances.length - 1].insuranceType = InsuranceType.None;
        }

        insurances.push(
            InsuranceInfo({
                companyName: insuranceInfo.companyName,
                policyNumber: insuranceInfo.policyNumber,
                photo: insuranceInfo.photo,
                comment: insuranceInfo.comment,
                insuranceType: insuranceInfo.insuranceType,
                createdTime: block.timestamp,
                createdBy: user
            })
        );
    }

    function getGuestInsurances(address user) external view returns (InsuranceInfo[] memory) {
        return userToInsuranceInfo[user];
    }

    function saveTripInsuranceInfo(uint256 tripId, SaveInsuranceRequest memory insuranceInfo, address user) external onlyPlatform {
        if (insuranceInfo.insuranceType == InsuranceType.None) {
            revert InvalidInsuranceType();
        }

        InsuranceInfo[] storage insurances = _bookingInsuranceInfo(tripId);
        insurances.push(
            InsuranceInfo({
                companyName: insuranceInfo.companyName,
                policyNumber: insuranceInfo.policyNumber,
                photo: insuranceInfo.photo,
                comment: insuranceInfo.comment,
                insuranceType: insuranceInfo.insuranceType,
                createdTime: block.timestamp,
                createdBy: user
            })
        );
    }

    function getInsurancePriceByCar(uint256 carId) public view returns (uint256) {
        InsuranceRequirement memory info = getInsuranceRequirement(carId);
        return info.required ? info.priceInUsdCents : 0;
    }

    function saveGuestInsurancePayment(uint256 tripId, uint256 carId, uint256 totalSum, address user) external onlyPlatform {
        if (!objectIdToInsuranceRequirement[carId].required) {
            return;
        }

        InsuranceInfo[] memory insurances = userToInsuranceInfo[user];
        bool guestHasGeneralInsurance =
            insurances.length > 0 && insurances[insurances.length - 1].insuranceType == InsuranceType.General;

        if (guestHasGeneralInsurance) {
            InsuranceInfo[] storage tripInsurances = _bookingInsuranceInfo(tripId);
            tripInsurances.push(insurances[insurances.length - 1]);
        }

        _setInsurancePaidByBooking(tripId, totalSum);
    }

    function calculateInsuranceForTrip(
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime,
        address user
    ) public view returns (uint256) {
        uint256 price = getInsurancePriceByCar(carId);
        InsuranceInfo[] memory insurances = userToInsuranceInfo[user];
        if (price == 0 || (insurances.length > 0 && insurances[insurances.length - 1].insuranceType == InsuranceType.General)) {
            return 0;
        }

        uint64 duration = endDateTime - startDateTime;
        uint256 tripInDays = Math.ceilDiv(duration, 1 days);
        return tripInDays * price;
    }

    function getInsurancePriceByTrip(uint256 tripId) external view returns (uint256) {
        return getInsurancePaidByBooking(tripId);
    }

    function getTripInsurances(uint256 tripId) external view returns (InsuranceInfo[] memory) {
        return bookingIdToInsuranceInfo[tripId];
    }

    function isGuestHasInsurance(address guest) external view returns (bool) {
        return hasActiveGeneralInsurance(guest);
    }

    function findActualInsurance(InsuranceInfo[] memory insurances) external pure returns (uint256, uint256) {
        uint256 lastGeneralIndex = type(uint256).max;
        uint256 lastOneTimeIndex = type(uint256).max;
        uint256 latestGeneralTime = 0;
        uint256 latestOneTimeTime = 0;

        for (uint256 i = 0; i < insurances.length; i++) {
            if (insurances[i].insuranceType == InsuranceType.General && insurances[i].createdTime > latestGeneralTime) {
                latestGeneralTime = insurances[i].createdTime;
                lastGeneralIndex = i;
            }
            if (insurances[i].insuranceType == InsuranceType.OneTime && insurances[i].createdTime > latestOneTimeTime) {
                latestOneTimeTime = insurances[i].createdTime;
                lastOneTimeIndex = i;
            }
        }

        return (lastOneTimeIndex, lastGeneralIndex);
    }

    function payHostInsuranceClaim(uint256 amountToPay, HostInsurancePayoutContext memory context) external payable onlyPlatform {
        uint256 hostInsuranceId = userToInsuranceRuleId[context.host];
        if (hostInsuranceId == 0) {
            revert HostHasNoInsuranceRule(context.host);
        }

        InsuranceRule memory insuranceRule = insuranceIdToRule[hostInsuranceId];
        uint256 hostAverage = userToInsuranceAverage[context.host].totalPercents;
        if (hostAverage == 0) {
            revert HostInsuranceAverageIsZero(context.host);
        }

        uint256 valueToPay;
        if (hostAverage >= insuranceRule.partToInsurance) {
            valueToPay = amountToPay;
        } else {
            uint256 percentsToPay = 100 * hostAverage / insuranceRule.partToInsurance;
            valueToPay = amountToPay * percentsToPay / 100;
        }

        if (context.currencyType == address(0) && address(this).balance < valueToPay) {
            valueToPay = address(this).balance;
        } else if (context.currencyType != address(0) && IERC20(context.currencyType).balanceOf(address(this)) < valueToPay) {
            valueToPay = IERC20(context.currencyType).balanceOf(address(this));
        }

        bool success;
        if (context.currencyType == address(0)) {
            (success, ) = payable(context.host).call{value: valueToPay}("");
        } else {
            success = IERC20(context.currencyType).transfer(context.host, valueToPay);
        }

        require(success, 'Refund to host failed.');
    }

    function createInsuranceClaim(uint256 claimId, address sender) external onlyPlatform {
        if (claimIdIsInsuranceClaim[claimId]) {
            revert('Insurance: already exists');
        }
        if (userToInsuranceRuleId[sender] == 0) {
            revert HostHasNoInsuranceRule(sender);
        }
        if (userToInsuranceAverage[sender].totalPercents == 0) {
            revert HostInsuranceAverageIsZero(sender);
        }

        claimIdIsInsuranceClaim[claimId] = true;
        insuranceClaims.push(claimId);
    }

    function createNewInsuranceRule(InsuranceRule memory rule) external onlyAdmin {
        insuranceRuleId++;
        insuranceIdToRule[insuranceRuleId] = InsuranceRule({
            partToInsurance: rule.partToInsurance,
            insuranceId: insuranceRuleId
        });
    }

    function setHostInsurance(uint256 insuranceIdToUse, address user) external onlyPlatform {
        if (insuranceIdToRule[insuranceIdToUse].partToInsurance == 0 && insuranceIdToUse != 0) {
            revert InsuranceRuleNotFound(insuranceIdToUse);
        }
        userToInsuranceRuleId[user] = insuranceIdToUse;
    }

    function calculateCurrentHostInsuranceSumFrom(address user, uint256 amount) external view returns (uint256) {
        uint256 hostInsuranceRuleId = userToInsuranceRuleId[user];
        InsuranceRule memory rule = insuranceIdToRule[hostInsuranceRuleId];
        if (rule.partToInsurance == 0) {
            return 0;
        }
        return (amount * rule.partToInsurance) / 100;
    }

    receive() external payable {}

    function updateUserInsuranceAverage(address user, uint256 tripId, uint256 value) external payable {
        uint256 hostInsuranceRuleId = userToInsuranceRuleId[user];
        InsuranceAverage memory average = userToInsuranceAverage[user];
        InsuranceRule memory rule = insuranceIdToRule[hostInsuranceRuleId];

        uint256 newAverage = average.totalPercents * average.totalTripsCount + rule.partToInsurance;
        uint256 newValue = 0;
        if (newAverage != 0) {
            newValue = newAverage / (average.totalTripsCount + 1);
        }

        userToInsuranceAverage[user].totalPercents = newValue;
        userToInsuranceAverage[user].totalTripsCount++;
        tripIdToInsuranceValuePaid[tripId] = value;
    }

    function getAllInsuranceRules() external view returns (InsuranceRule[] memory insuranceRules) {
        insuranceRules = new InsuranceRule[](insuranceRuleId + 1);
        for (uint256 i = 0; i < insuranceRuleId; i++) {
            insuranceRules[i] = InsuranceRule({
                partToInsurance: insuranceIdToRule[i + 1].partToInsurance,
                insuranceId: i + 1
            });
        }
        insuranceRules[insuranceRuleId] = InsuranceRule({partToInsurance: 0, insuranceId: 0});
    }

    function getHostInsuranceRule(address host) external view returns (InsuranceRule memory) {
        uint256 currentInsuranceId = userToInsuranceRuleId[host];
        return InsuranceRule({
            insuranceId: currentInsuranceId,
            partToInsurance: insuranceIdToRule[currentInsuranceId].partToInsurance
        });
    }

    function isInsuranceClaim(uint256 claimId) external view returns (bool) {
        return claimIdIsInsuranceClaim[claimId];
    }

    function getInsuranceClaims() external view returns (uint256[] memory) {
        return insuranceClaims;
    }

    function getPaidToInsuranceByTripId(uint256 tripId) external view returns (uint256) {
        return tripIdToInsuranceValuePaid[tripId];
    }
}
