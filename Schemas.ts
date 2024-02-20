export type CarInfo = {
     carId: bigint;
     carVinNumber: string;
     carVinNumberHash: Uint8Array;
     createdBy: string;
     brand: string;
     model: string;
     yearOfProduction: number;
     pricePerDayInUsdCents: bigint;
     securityDepositPerTripInUsdCents: bigint;
     engineType: number;
     engineParams: bigint[];
     milesIncludedPerDay: bigint;
     timeBufferBetweenTripsInSec: number;
     currentlyListed: boolean;
     geoVerified: boolean;
     timeZoneId: string;
}

export type CreateCarRequest = {
     tokenUri: string;
     carVinNumber: string;
     brand: string;
     model: string;
     yearOfProduction: number;
     pricePerDayInUsdCents: bigint;
     securityDepositPerTripInUsdCents: bigint;
     engineParams: bigint[];
     engineType: number;
     milesIncludedPerDay: bigint;
     timeBufferBetweenTripsInSec: number;
     locationAddress: string;
     locationLatitude: string;
     locationLongitude: string;
     geoApiKey: string;
}

export type UpdateCarInfoRequest = {
     carId: bigint;
     pricePerDayInUsdCents: bigint;
     securityDepositPerTripInUsdCents: bigint;
     engineParams: bigint[];
     milesIncludedPerDay: bigint;
     timeBufferBetweenTripsInSec: number;
     currentlyListed: boolean;
}

export type SearchCarParams = {
     country: string;
     state: string;
     city: string;
     brand: string;
     model: string;
     yearOfProductionFrom: number;
     yearOfProductionTo: number;
     pricePerDayInUsdCentsFrom: bigint;
     pricePerDayInUsdCentsTo: bigint;
}

export type CreateTripRequest = {
     carId: bigint;
     host: string;
     startDateTime: bigint;
     endDateTime: bigint;
     startLocation: string;
     endLocation: string;
     totalDayPriceInUsdCents: bigint;
     taxPriceInUsdCents: bigint;
     depositInUsdCents: bigint;
     ethToCurrencyRate: bigint;
     ethToCurrencyDecimals: number;
}

export type TransactionInfo = {
     rentalityFee: bigint;
     depositRefund: bigint;
     tripEarnings: bigint;
     dateTime: bigint;
     statusBeforeCancellation: TripStatus;
}

export type Trip = {
     tripId: bigint;
     carId: bigint;
     status: TripStatus;
     guest: string;
     host: string;
     guestName: string;
     hostName: string;
     pricePerDayInUsdCents: bigint;
     startDateTime: bigint;
     endDateTime: bigint;
     startLocation: string;
     endLocation: string;
     milesIncludedPerDay: bigint;
     fuelPrices: bigint[];
     paymentInfo: PaymentInfo;
     createdDateTime: bigint;
     approvedDateTime: bigint;
     rejectedDateTime: bigint;
     rejectedBy: string;
     checkedInByHostDateTime: bigint;
     startParamLevels: bigint[];
     checkedInByGuestDateTime: bigint;
     tripStartedBy: string;
     checkedOutByGuestDateTime: bigint;
     tripFinishedBy: string;
     endParamLevels: bigint[];
     checkedOutByHostDateTime: bigint;
     transactionInfo: TransactionInfo;
}

export type ChatInfo = {
     tripId: bigint;
     guestAddress: string;
     guestName: string;
     guestPhotoUrl: string;
     hostAddress: string;
     hostName: string;
     hostPhotoUrl: string;
     tripStatus: bigint;
     carBrand: string;
     carModel: string;
     carYearOfProduction: number;
     carMetadataUrl: string;
     startDateTime: bigint;
     endDateTime: bigint;
}

export type ChatKeyPair = {
     privateKey: string;
     publicKey: string;
}

export type AddressPublicKey = {
     userAddress: string;
     publicKey: string;
}

export type FullClaimInfo = {
     claim: Claim;
     host: string;
     guest: string;
     guestPhoneNumber: string;
     hostPhoneNumber: string;
     carInfo: CarInfo;
}

export type Claim = {
     tripId: bigint;
     claimId: bigint;
     deadlineDateInSec: bigint;
     claimType: ClaimType;
     status: ClaimStatus;
     description: string;
     amountInUsdCents: bigint;
     payDateInSec: bigint;
     rejectedBy: string;
     rejectedDateInSec: bigint;
}

export type CreateClaimRequest = {
     tripId: bigint;
     claimType: ClaimType;
     description: string;
     amountInUsdCents: bigint;
}

export type ParsedGeolocationData = {
     status: string;
     validCoordinates: boolean;
     locationLat: string;
     locationLng: string;
     northeastLat: string;
     northeastLng: string;
     southwestLat: string;
     southwestLng: string;
     city: string;
     state: string;
     country: string;
     timeZoneId: string;
}

export type PaymentInfo = {
     tripId: bigint;
     from: string;
     to: string;
     totalDayPriceInUsdCents: bigint;
     taxPriceInUsdCents: bigint;
     depositInUsdCents: bigint;
     resolveAmountInUsdCents: bigint;
     currencyType: CurrencyType;
     ethToCurrencyRate: bigint;
     ethToCurrencyDecimals: number;
     resolveFuelAmountInUsdCents: bigint;
     resolveMilesAmountInUsdCents: bigint;
}

export type KYCInfo = {
     name: string;
     surname: string;
     mobilePhoneNumber: string;
     profilePhoto: string;
     licenseNumber: string;
     expirationDate: bigint;
     createDate: bigint;
     isKYCPassed: boolean;
     isTCPassed: boolean;
}

export type AutomationData = {
     tripId: bigint;
     whenToCallInSec: bigint;
     aType: AutomationType;
}

export type SearchCar = {
     carId: bigint;
     brand: string;
     model: string;
     yearOfProduction: number;
     pricePerDayInUsdCents: bigint;
     securityDepositPerTripInUsdCents: bigint;
     engineType: number;
     milesIncludedPerDay: bigint;
     host: string;
     hostName: string;
     hostPhotoUrl: string;
     city: string;
     country: string;
     state: string;
     locationLatitude: string;
     locationLongitude: string;
     timeZoneId: string;
}

export type CarDetails = {
     carId: bigint;
     hostName: string;
     hostPhotoUrl: string;
     host: string;
     brand: string;
     model: string;
     yearOfProduction: number;
     pricePerDayInUsdCents: bigint;
     securityDepositPerTripInUsdCents: bigint;
     milesIncludedPerDay: bigint;
     engineType: number;
     engineParams: bigint[];
     geoVerified: boolean;
     currentlyListed: boolean;
     timeZoneId: string;
     city: string;
     country: string;
     state: string;
     locationLatitude: string;
     locationLongitude: string;
}

export enum TripStatus {
     Created,
     Approved,
     CheckedInByHost,
     CheckedInByGuest,
     CheckedOutByGuest,
     CheckedOutByHost,
     Finished,
     Canceled,
}

export enum ClaimType {
     Tolls,
     Tickets,
     LateReturn,
     Cleanliness,
     Smoking,
     ExteriorDamage,
     InteriorDamage,
     Other,
}

export enum ClaimStatus {
     NotPaid,
     Paid,
     Cancel,
     Overdue,
}

export enum CurrencyType {
     ETH,
}

export enum AutomationType {
     Rejection,
     StartTrip,
     FinishTrip,
}

