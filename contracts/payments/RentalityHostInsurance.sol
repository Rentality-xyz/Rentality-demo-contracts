// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../Schemas.sol';


contract RentalityHostInsurance is Initializable, UUPSAccess {
    uint private insuranceId;
    mapping (uint => Schemas.HostInsuranceRule) private insuranceIdToInsurance;
    mapping (address => uint) private userToInsuranceId;
    mapping (address => Schemas.HostInsuranceAvarage) private userToAvaragePercents;

    function createNewInsuranceRule(Schemas.HostInsuranceRule memory rule) public {
        require(userService.isAdmin(msg.sender), 'RentalityHostInsurance: only Admin.');
        insuranceId++;
        insuranceIdToInsurance[insuranceId] = rule;
    }
    function setHostInsurance(uint insuranceIdToUse, address user) public {
        require(userService.isRentalityPlatform(msg.sender), 'RentalityHostInsurance: only Rentality platform.');
        require(insuranceIdToInsurance[insuranceIdToUse].partToInsurance > 0, 'RentalityHostInsurance: Insurance rule not found.');
        userToInsuranceId[user] = insuranceIdToUse;
    }


    function calculateCurrentHostInsuranceSumFrom(address user, uint amount) public view returns (uint) {
        uint hostInsuranceRuleId = userToInsuranceId[user];
        Schemas.HostInsuranceRule memory rule = insuranceIdToInsurance[hostInsuranceRuleId];
        if (rule.partToInsurance == 0) {
            return 0;
        }
        return (amount * rule.partToInsurance) / 100;
    }

    function calculateAvaragePercents(address user, uint amount) public view returns (uint) {
        uint hostInsuranceRuleId = userToInsuranceId[user];
        Schemas.HostInsuranceRule memory rule = insuranceIdToInsurance[hostInsuranceRuleId];
        if (rule.partToInsurance == 0) {
            return 0;
        }
        return (amount * rule.partToInsurance) / 100;
    }
    function addToInsurancePool(address user, uint sum) public payable {
        require(userService.isRentalityPlatform(msg.sender), 'RentalityHostInsurance: only Rentality platform.');
        uint percents = calculateCurrentHostInsuranceSumFrom(user, sum);
        userToAvaragePercents[user].totalTripsCount++;
        userToAvaragePercents[user].totalPercents += percents;
    }

}