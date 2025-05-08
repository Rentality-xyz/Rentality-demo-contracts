// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import "../../Schemas.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import { IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { DeliveryStorage } from "../libraries/DeliveryStorage.sol";
import { GeoServiceStorage } from "../libraries/GeoServiceStorage.sol";
import { TaxesStorage } from "../libraries/TaxesStorage.sol";
import { UserServiceStorage } from "../libraries/UserServiceStorage.sol";
import { CurrencyConverterStorage } from "../libraries/CurrencyConverterStorage.sol";
import { RefferalServiceStorage } from "../libraries/RefferalServiceStorage.sol";
import { CarTokenStorage } from "../libraries/CarTokenStorage.sol";
import { PaymentsStorage } from "../libraries/PaymentsStorage.sol";
import { RentalityRefferalLibDiamond } from "../libraries/getters/RentalityRefferalLibDiamond.sol";
import { RentalityEnginesService } from "../../engine/RentalityEnginesService.sol";
import { ARentalityUpgradableCurrencyType } from "../../payments/RentalityCurrencyType.sol";
import { IRentalityDiscount } from "../../payments/abstract/IRentalityDiscount.sol";
import { RentalityInvestment } from "../../investment/RentalityInvestment.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit {    

    // You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init(
        address verifier,
        address refferalLib,
        string memory name_,
        string memory symbol_,
        address enginesService,
        address _civicVerifier,
        uint _civicGatekeeperNetwork,
        address ethTokenService,
        address usdt,
        address usdtTokenService,
        address _baseDiscount, 
        address _investorService
        ) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;


      DeliveryStorage.DeliveryFaucetStorage storage deliveryStorage = DeliveryStorage.accessStorage();
      deliveryStorage.defaultPrices = Schemas.DeliveryPrices(300, 250, false);


      TaxesStorage.TaxesFaucetStorage storage s = TaxesStorage.accessStorage();
      s.defaultTax = 1;
      Schemas.TaxValue[] memory taxes = new Schemas.TaxValue[](2);
      taxes[0] = Schemas.TaxValue('salesTax', 70_000, Schemas.TaxesType.PPM);
      taxes[1] = Schemas.TaxValue('governmentTax', 200, Schemas.TaxesType.InUsdCentsPerDay);
      TaxesStorage.addTaxes(1, "Florida", taxes);


       GeoServiceStorage.setVerifier(verifier);



        RefferalServiceStorage.RefferalFaucetStorage storage refferalStorage = RefferalServiceStorage.accessStorage();
        refferalStorage.refferalLib = refferalLib;

        RefferalServiceStorage.addOneTimeProgram(Schemas.RefferalProgram.SetKYC, 100, 125, bytes4(''));
        RefferalServiceStorage.addOneTimeProgram(Schemas.RefferalProgram.PassCivic, 500, 625, bytes4(''));
        RefferalServiceStorage.addOneTimeProgram(Schemas.RefferalProgram.AddCar, 1000, 2000, bytes4(''));
        RefferalServiceStorage.addOneTimeProgram(Schemas.RefferalProgram.FinishTripAsGuest, 1000, 1250, bytes4(''));

        RefferalServiceStorage.addPermanentProgram(Schemas.RefferalProgram.AddCar, 500, bytes4(''));
        RefferalServiceStorage.addPermanentProgram(Schemas.RefferalProgram.FinishTripAsGuest, 50, RentalityRefferalLibDiamond.finishTrip.selector);
        RefferalServiceStorage.addPermanentProgram(Schemas.RefferalProgram.UnlistedCar, -500, RentalityRefferalLibDiamond.updateCar.selector);
        RefferalServiceStorage.addPermanentProgram(Schemas.RefferalProgram.Daily, 20, bytes4(''));
        RefferalServiceStorage.addPermanentProgram(Schemas.RefferalProgram.DailyListing, 10, bytes4(''));

        RefferalServiceStorage.manageRefHashesProgram(Schemas.RefferalProgram.SetKYC, 10);
        RefferalServiceStorage.manageRefHashesProgram(Schemas.RefferalProgram.PassCivic, 50);
        RefferalServiceStorage.manageRefHashesProgram(Schemas.RefferalProgram.AddCar, 250);
        RefferalServiceStorage.manageRefHashesProgram(Schemas.RefferalProgram.FinishTripAsGuest, 1000);

        RefferalServiceStorage.manageRefferalDiscount(Schemas.RefferalProgram.CreateTrip, Schemas.Tear.Tear2, 100, 2);
        RefferalServiceStorage.manageRefferalDiscount(Schemas.RefferalProgram.CreateTrip, Schemas.Tear.Tear3, 150, 3);
        RefferalServiceStorage.manageRefferalDiscount(Schemas.RefferalProgram.CreateTrip, Schemas.Tear.Tear4, 250, 5);

        RefferalServiceStorage.manageRefferalDiscount(Schemas.RefferalProgram.FinishTripAsGuest, Schemas.Tear.Tear2, 100, 10);
        RefferalServiceStorage.manageRefferalDiscount(Schemas.RefferalProgram.FinishTripAsGuest, Schemas.Tear.Tear3, 150, 15);
        RefferalServiceStorage.manageRefferalDiscount(Schemas.RefferalProgram.FinishTripAsGuest, Schemas.Tear.Tear4, 250, 25);

        RefferalServiceStorage.manageTearInfo(Schemas.Tear.Tear1, 0, 999);
        RefferalServiceStorage.manageTearInfo(Schemas.Tear.Tear2, 1000, 4999);
        RefferalServiceStorage.manageTearInfo(Schemas.Tear.Tear3, 5000, 9999);
        RefferalServiceStorage.manageTearInfo(Schemas.Tear.Tear4, 10000, type(uint).max);


        CarTokenStorage.CarTokenFaucetStorage storage carStorage = CarTokenStorage.accessStorage();
        carStorage.enginesService = RentalityEnginesService(enginesService);
        carStorage._name = name_;
        carStorage._symbol = symbol_;



        UserServiceStorage.UserFaucetStorage storage userStorage = UserServiceStorage.accessStorage();
        UserServiceStorage._grantRole(UserServiceStorage.DEFAULT_ADMIN_ROLE, msg.sender);
        UserServiceStorage._grantRole(UserServiceStorage.MANAGER_ROLE, msg.sender);
        UserServiceStorage._grantRole(UserServiceStorage.HOST_ROLE, msg.sender);
        UserServiceStorage._grantRole(UserServiceStorage.GUEST_ROLE, msg.sender);
        UserServiceStorage._grantRole(UserServiceStorage.RENTALITY_PLATFORM, msg.sender);
    
        userStorage.civicVerifier = _civicVerifier;
        userStorage.civicGatekeeperNetwork = _civicGatekeeperNetwork;
        userStorage.TCMessageHash = ECDSA.toEthSignedMessageHash(
        'I have read and I agree with Terms of service, Cancellation policy, Prohibited uses and Privacy policy of Rentality.'
        );
        userStorage.kycCommission = 200;


        CurrencyConverterStorage.CurrencyConverterFaucetStorage storage currencyStorage = CurrencyConverterStorage.accessStorage();
        currencyStorage.tokenAddressToPaymentMethod[address(0)] = ARentalityUpgradableCurrencyType(ethTokenService);
        currencyStorage.availableCurrencies.push(Schemas.Currency(address(0), "ETH"));

        currencyStorage.tokenAddressToPaymentMethod[usdt] = ARentalityUpgradableCurrencyType(usdtTokenService);
        currencyStorage.availableCurrencies.push(Schemas.Currency(usdt, "USDT"));


        PaymentsStorage.PaymentsFaucetStorage storage paymentsStorage = PaymentsStorage.accessStorage();

        paymentsStorage.platformFeeInPPM = 200_000;

        paymentsStorage.currentDiscount = _baseDiscount;
        paymentsStorage.discountAddressToDiscountContract[_baseDiscount] = IRentalityDiscount(_baseDiscount);

        paymentsStorage.investmentService = RentalityInvestment(_investorService);
}

        // add your own state variables 
        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
    }




