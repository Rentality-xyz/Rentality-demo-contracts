// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../Schemas.sol';
import './abstract/IERC20.sol';

contract RentalityHostInsurance is Initializable, UUPSAccess {
    uint private insuranceId;
    mapping (uint => Schemas.HostInsuranceRule) private insuranceIdToInsurance;
    mapping (address => uint) private userToInsuranceId;
    mapping (address => Schemas.HostInsuranceAvarage) private userToAvaragePercents;
    mapping (uint => bool) private claimIdIsInsuranceClaim;
    uint [] private insuranceClaims;

    function payClaim(uint amountToPay, Schemas.Trip memory trip) public {
    require(userService.isRentalityPlatform(msg.sender), 'RentalityHostInsurance: only Rentality platform.');
    require(userService.isAdmin(tx.origin), "HostInsurance: only admin");

    uint hostInsuranceId = userToInsuranceId[trip.host];
    require(hostInsuranceId != 0, "Host don't use insurance");

    Schemas.HostInsuranceRule memory insuranceRule = insuranceIdToInsurance[hostInsuranceId];
    uint hostAvarage = userToAvaragePercents[trip.host].totalPercents;

    uint valueToPay;
    if (hostAvarage >= insuranceRule.partToInsurance) {
    valueToPay = amountToPay;
    }
 
    else {
    uint percentsToPay = 100 * hostAvarage / insuranceRule.partToInsurance;
    valueToPay = amountToPay * percentsToPay / 100;
    }
    
    if(trip.paymentInfo.currencyType == address(0) && address(this).balance < valueToPay){
    valueToPay = address(this).balance;
    }
    else if(
    (trip.paymentInfo.currencyType != address(0) && IERC20(trip.paymentInfo.currencyType).balanceOf(address(this)) < valueToPay )) {
    valueToPay = IERC20(trip.paymentInfo.currencyType).balanceOf(address(this));
    }
    bool successHost;

    if (trip.paymentInfo.currencyType == address(0)) {
    
      (successHost, ) = payable(trip.host).call{value: valueToPay}('');

    } else {
      // Handle payment in ERC20 tokens
      successHost = IERC20(trip.paymentInfo.currencyType).transfer(trip.host, valueToPay);
    }
       require(successHost, 'Refund to guest failed.');

    }

    function createInsuranceClaim(uint claimId, address sender) public {
    require(userService.isRentalityPlatform(msg.sender), 'RentalityHostInsurance: only Rentality platform.');
    require(!claimIdIsInsuranceClaim[claimId], "HostInsurance: already exists");
    require(userToInsuranceId[sender] != 0,"HostInsurance: host don't have insurance rule");
    require(userToAvaragePercents[sender].totalPercents > 0, "HostInsurance: host has 0 avarage percents");
    claimIdIsInsuranceClaim[claimId] = true;
    insuranceClaims.push(claimId);
    }

    function createNewInsuranceRule(Schemas.HostInsuranceRule memory rule) public {
        require(userService.isAdmin(msg.sender), 'RentalityHostInsurance: only Admin.');
        insuranceId++;
        insuranceIdToInsurance[insuranceId] = rule;
    }
    function setHostInsurance(uint insuranceIdToUse, address user) public {
        require(userService.isRentalityPlatform(msg.sender), 'RentalityHostInsurance: only Rentality platform.');
        require(insuranceIdToInsurance[insuranceIdToUse].partToInsurance > 0 || insuranceIdToUse == 0, 'RentalityHostInsurance: Insurance rule not found.');
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
    
    receive() external payable {}


    function updateUserAvarage(address user) public payable {
        uint hostInsuranceRuleId = userToInsuranceId[user];
        Schemas.HostInsuranceAvarage memory avarage = userToAvaragePercents[user];

        Schemas.HostInsuranceRule memory rule = insuranceIdToInsurance[hostInsuranceRuleId];
        uint newAvarage = avarage.totalPercents * avarage.totalTripsCount + rule.partToInsurance;
        uint newValue = 0;
        if (newAvarage != 0) {
            newValue = newAvarage / (avarage.totalTripsCount + 1);
        }
        userToAvaragePercents[user].totalPercents = newValue;
        userToAvaragePercents[user].totalTripsCount++;

    }
    function addToInsurancePool(address user) public payable {
        require(userService.isRentalityPlatform(msg.sender), 'RentalityHostInsurance: only Rentality platform.');
        updateUserAvarage(user);
    }

    function getAllInsuranceRules() public view returns(Schemas.HostInsuranceRule[] memory insuranceRules) {
    insuranceRules = new Schemas.HostInsuranceRule[](insuranceId);
    for (uint i = 0; i < insuranceId; i++) {
        insuranceRules[i] = insuranceIdToInsurance[i + 1];
    }
    }
    function getHostInsuranceRule(address host) public view returns(Schemas.HostInsuranceRule memory insuranceRules) {
    return insuranceIdToInsurance[userToInsuranceId[host]];
    }
    function isHostInsuranceClaim(uint claimId) public view returns(bool) {
        return claimIdIsInsuranceClaim[claimId];
    }
    function getInsuranceClaims() public view returns(uint[] memory) {
        return insuranceClaims;
    }

    function initialize(
    address _userService
  ) public virtual initializer {
    userService = IRentalityAccessControl(_userService);
    insuranceId = 1;
    insuranceIdToInsurance[1] = Schemas.HostInsuranceRule(40, insuranceId);
  }


}