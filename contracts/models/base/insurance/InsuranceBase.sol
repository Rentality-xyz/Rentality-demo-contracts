// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './IInsurance.sol';

abstract contract InsuranceBase is IInsurance {
    mapping(uint256 => InsuranceRequirement) internal objectIdToInsuranceRequirement;
    mapping(address => InsuranceInfo[]) internal userToInsuranceInfo;
    mapping(uint256 => uint256) internal bookingIdToInsurancePaid;
    mapping(uint256 => InsuranceInfo[]) internal bookingIdToInsuranceInfo;

    function getInsuranceRequirement(uint256 objectId)
        public
        view
        virtual
        returns (InsuranceRequirement memory)
    {
        return objectIdToInsuranceRequirement[objectId];
    }

    function getInsurancePaidByBooking(uint256 bookingId) public view virtual returns (uint256) {
        return bookingIdToInsurancePaid[bookingId];
    }

    function hasActiveGeneralInsurance(address user) public view virtual returns (bool) {
        InsuranceInfo[] memory infos = userToInsuranceInfo[user];
        return infos.length > 0 && infos[infos.length - 1].insuranceType == InsuranceType.General;
    }

    function _saveInsuranceRequirement(uint256 objectId, InsuranceRequirement memory requirement) internal {
        objectIdToInsuranceRequirement[objectId] = requirement;
    }

    function _userInsuranceInfo(address user) internal view returns (InsuranceInfo[] storage) {
        return userToInsuranceInfo[user];
    }

    function _bookingInsuranceInfo(uint256 bookingId) internal view returns (InsuranceInfo[] storage) {
        return bookingIdToInsuranceInfo[bookingId];
    }

    function _setInsurancePaidByBooking(uint256 bookingId, uint256 amount) internal {
        bookingIdToInsurancePaid[bookingId] = amount;
    }
}
