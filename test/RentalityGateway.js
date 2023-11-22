const {expect} = require('chai');
const {ethers} = require('hardhat');
const {
    time,
    loadFixture,
} = require('@nomicfoundation/hardhat-network-helpers');
const {Contract} = require("hardhat/internal/hardhat-network/stack-traces/model");
const {getMockCarRequest} = require("./utils");

async function deployDefaultFixture() {
    const [owner, admin, manager, host, guest, anonymous] =
        await ethers.getSigners()

    const RentalityUtils = await ethers.getContractFactory('RentalityUtils')
    const utils = await RentalityUtils.deploy()
    const RentalityMockPriceFeed = await ethers.getContractFactory(
        'RentalityMockPriceFeed',
    )
    const RentalityUserService = await ethers.getContractFactory(
        'RentalityUserService',
    )
    const RentalityTripService = await ethers.getContractFactory(
        'RentalityTripService',
        {libraries: {RentalityUtils: utils.address}},
    )
    const RentalityCurrencyConverter = await ethers.getContractFactory(
        'RentalityCurrencyConverter',
    )
    const RentalityPaymentService = await ethers.getContractFactory(
        'RentalityPaymentService',
    )
    const RentalityCarToken =
        await ethers.getContractFactory('RentalityCarToken')

    const RentalityPlatform =
        await ethers.getContractFactory('RentalityPlatform',
            {
                libraries:
                    {
                        RentalityUtils: utils.address
                    }
            })
    let RentalityGateway = await ethers.getContractFactory(
        'RentalityGateway'
    );

    let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(
        8,
        200000000000,
    )
    await rentalityMockPriceFeed.deployed()

    const rentalityUserService = await RentalityUserService.deploy()
    await rentalityUserService.deployed()

    await rentalityUserService.connect(owner).grantAdminRole(admin.address)
    await rentalityUserService.connect(owner).grantManagerRole(manager.address)
    await rentalityUserService.connect(owner).grantHostRole(host.address)
    await rentalityUserService.connect(owner).grantGuestRole(guest.address)

    const rentalityCurrencyConverter = await RentalityCurrencyConverter.deploy(
        rentalityMockPriceFeed.address,
    )
    await rentalityCurrencyConverter.deployed()

    const rentalityCarToken = await RentalityCarToken.deploy()
    await rentalityCarToken.deployed()
    const rentalityPaymentService = await RentalityPaymentService.deploy()
    await rentalityPaymentService.deployed()

    const rentalityTripService = await RentalityTripService.deploy(
        rentalityCurrencyConverter.address,
        rentalityCarToken.address,
        rentalityPaymentService.address,
        rentalityUserService.address,
    )
    await rentalityTripService.deployed()

    const rentalityPlatform = await RentalityPlatform.deploy(
        rentalityCarToken.address,
        rentalityCurrencyConverter.address,
        rentalityTripService.address,
        rentalityUserService.address,
        rentalityPaymentService.address,
    )
    await rentalityPlatform.deployed()

    await rentalityUserService
        .connect(owner)
        .grantHostRole(rentalityPlatform.address)

    await rentalityUserService
        .connect(owner)
        .grantManagerRole(rentalityTripService.address)


    let rentalityGateway = await RentalityGateway.connect(owner).deploy(
        rentalityCarToken.address,
        rentalityCurrencyConverter.address,
        rentalityTripService.address,
        rentalityUserService.address,
        rentalityPlatform.address,
        rentalityPaymentService.address
    );
    await rentalityGateway.deployed();


    return {
        rentalityGateway,
        rentalityMockPriceFeed,
        rentalityUserService,
        rentalityTripService,
        rentalityCurrencyConverter,
        rentalityCarToken,
        rentalityPaymentService,
        rentalityPlatform,
        owner,
        admin,
        manager,
        host,
        guest,
        anonymous,
    }
}


describe('RentalityGateway', function () {

    let rentalityGateway,
        rentalityMockPriceFeed,
        rentalityUserService,
        rentalityTripService,
        rentalityCurrencyConverter,
        rentalityCarToken,
        rentalityPaymentService,
        rentalityPlatform,
        owner,
        admin,
        manager,
        host,
        guest,
        anonymous;

    beforeEach(async function () {
        ({
            rentalityGateway,
            rentalityMockPriceFeed,
            rentalityUserService,
            rentalityTripService,
            rentalityCurrencyConverter,
            rentalityCarToken,
            rentalityPaymentService,
            rentalityPlatform,
            owner,
            admin,
            manager,
            host,
            guest,
            anonymous,
        } = await loadFixture(deployDefaultFixture));
    });

    it('should has right owner', async function () {

        expect(await rentalityGateway.owner()).to.equal(owner.address)
    });

    it('should allow only admin to update car service address', async function () {
        await expect(
            rentalityGateway.connect(guest).updateCarService(rentalityCarToken.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(host).updateCarService(rentalityCarToken.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(anonymous).updateCarService(rentalityCarToken.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(admin)
                .updateCarService(rentalityCarToken.address)).not.be.reverted

    });
    it('should allow only admin to update rentality platform address', async function () {
        await expect(
            rentalityGateway.connect(guest).updateRentalityPlatform(rentalityPlatform.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(host).updateRentalityPlatform(rentalityPlatform.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(anonymous).updateRentalityPlatform(rentalityPlatform.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(admin)
                .updateRentalityPlatform(rentalityPlatform.address)).not.be.reverted
    });

    it('should allow only admin to update currency converter service address', async function () {
        await expect(
            rentalityGateway.connect(guest).updateCurrencyConverterService(rentalityCurrencyConverter.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(host).updateCurrencyConverterService(rentalityCurrencyConverter.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(anonymous).updateCurrencyConverterService(rentalityCurrencyConverter.address)).to.be.reverted


        await expect(
            rentalityGateway.connect(admin)
                .updateCurrencyConverterService(rentalityCurrencyConverter.address)).not.be.reverted
    });

    it('should allow only admin to update trip service address', async function () {
        await expect(
            rentalityGateway.connect(admin)
                .updateTripService(rentalityTripService.address)).not.be.reverted

        await expect(
            rentalityGateway.connect(host)
                .updateTripService(rentalityTripService.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(guest)
                .updateTripService(rentalityTripService.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(anonymous)
                .updateTripService(rentalityTripService.address)).to.be.reverted
    });

    it('should allow only admin to update user service address', async function () {
        await expect(
            rentalityGateway.connect(anonymous)
                .updateUserService(rentalityUserService.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(host)
                .updateUserService(rentalityUserService.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(guest)
                .updateUserService(rentalityUserService.address)).to.be.reverted

        await expect(
            rentalityGateway.connect(admin)
                .updateUserService(rentalityUserService.address)).not.be.reverted

    });

    it('should allow only admin to set platform fee in PPM', async function () {
        // TODO! owner && admin | owner
        await expect(
            rentalityGateway.connect(admin)
                .setPlatformFeeInPPM(10)).not.to.be.reverted

        await expect(
            rentalityGateway.connect(host).setPlatformFeeInPPM(10)).to.be.reverted

        await expect(
            rentalityGateway.connect(guest).setPlatformFeeInPPM(10)).to.be.reverted

        await expect(
            rentalityGateway.connect(anonymous).setPlatformFeeInPPM(10)).to.be.reverted

    });

    it('should update platform Fee in PMM', async function () {

        let platformFeeInPMM = 10101;

        await expect(
            rentalityGateway.connect(owner)
                .setPlatformFeeInPPM(platformFeeInPMM)).not.to.be.reverted


        expect(await rentalityGateway.getPlatformFeeInPPM()
        ).to.equal(platformFeeInPMM);

    });

    it('should allow only host to update car info', async function () {

        let addCarRequest = getMockCarRequest(0);
        await expect(rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted;

        await expect(rentalityGateway.connect(host).updateCarInfo(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)).not.to.be.reverted

        await expect(rentalityGateway.connect(guest).updateCarInfo(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)).to.be.revertedWith("User is not a host")

        await expect(rentalityGateway.connect(anonymous).updateCarInfo(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)).to.be.revertedWith("User is not a host")


    });

    it('should allow only host to update car token URI', async function () {
        let addCarRequest = getMockCarRequest(0);
        await expect(rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted;

        await expect(rentalityGateway.connect(host).updateCarTokenUri(1, " ")).not.to.be.reverted

        await expect(rentalityGateway.connect(guest).updateCarTokenUri(1, " ")).to.be.revertedWith("User is not a host")

        await expect(rentalityGateway.connect(anonymous).updateCarTokenUri(1, " ")).to.be.revertedWith("User is not a host")
    });

    it('should allow only host to burn car', async function () {

        let addCarRequest = getMockCarRequest(0);
        await expect(rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted;

        await expect(rentalityGateway.connect(host).burnCar(1)).not.to.be.reverted

        await expect(rentalityGateway.connect(guest).burnCar(1)).to.be.revertedWith("User is not a host")

        await expect(rentalityGateway.connect(anonymous).burnCar(1)).to.be.revertedWith("User is not a host")

    });

    it('should have available cars', async function () {
        let addCarRequest = getMockCarRequest(0);
        await expect(rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted;


        let available_cars = await rentalityGateway.connect(guest).getAvailableCars();

        expect(available_cars.length).to.be.equal(1)

    });

    it('should have cars owned by user', async function () {
        let addCarRequest = getMockCarRequest(0);
        await expect(rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted;


        let available_cars = await rentalityGateway.connect(host).getMyCars();

        expect(available_cars.length).to.be.equal(1)


        let cars_not_created = await rentalityGateway.connect(guest).getMyCars();

        expect(cars_not_created.length).to.be.equal(0)

    });

    it('should have cars owned by user', async function () {
        let addCarRequest = getMockCarRequest(0);
        await expect(rentalityCarToken.connect(host).addCar(addCarRequest)).not.be.reverted;


        let available_cars = await rentalityGateway.connect(host).getMyCars();

        expect(available_cars.length).to.be.equal(1)


        let cars_not_created = await rentalityGateway.connect(guest).getMyCars();

        expect(cars_not_created.length).to.be.equal(0)

    });

    it('Host and Guest should be able to get trip contacts', async function () {
        await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
            .not.to.be.reverted
        const myCars = await rentalityCarToken
            .connect(host)
            .getCarsOwnedByUser(host.address)
        expect(myCars.length).to.equal(1)

        const availableCars = await rentalityCarToken
            .connect(guest)
            .getAvailableCarsForUser(guest.address)
        expect(availableCars.length).to.equal(1)

        const rentPriceInUsdCents = 1000
        const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
            await rentalityCurrencyConverter.getEthFromUsdLatest(
                rentPriceInUsdCents,
            )

        await expect(
            rentalityPlatform.connect(guest).createTripRequest(
                {
                    carId: 1,
                    host: host.address,
                    startDateTime: 1,
                    endDateTime: 1,
                    startLocation: '',
                    endLocation: '',
                    totalDayPriceInUsdCents: rentPriceInUsdCents,
                    taxPriceInUsdCents: 0,
                    depositInUsdCents: 0,
                    fuelPricePerGalInUsdCents: 400,
                    ethToCurrencyRate: ethToCurrencyRate,
                    ethToCurrencyDecimals: ethToCurrencyDecimals,
                },
                {value: rentPriceInEth},
            ),
        ).not.to.be.reverted

        let guestNumber = "+380";
        let hostNumber = "+3801";
        await expect(rentalityUserService.connect(guest).setKYCInfo(
            "name",
            "surname",
            guestNumber,
            "photo",
            "number",
            1
        ))
            .not.be.reverted

        await expect(rentalityUserService.connect(host).setKYCInfo(
            "name",
            "surname",
            hostNumber,
            "photo",
            "number",
            1
        ))
            .not.be.reverted
        // TODO! imposible to call
        //ніхто не може викликати функцію
        //
        // gataway
        //
        // function getTripContactInfo
        //         onlyHostOrGuest
        //
        //   RentalityUserService.KYCInfo memory guestInfo = userService.getKYCInfo(
        //             trip.guest
        //         );
        //         RentalityUserService.KYCInfo memory hostInfo = userService.getKYCInfo(
        //             trip.host
        //         );
        //
        //
        // function getKYCInfo
        //
        // require(isManager(msg.sender) , 'Only the manager can get other users KYC info');

        expect(await rentalityGateway.connect(guest).getTripContactInfo(1)).to.be.equal((guestNumber, hostNumber));
        expect(await rentalityGateway.connect(host).getTripContactInfo(1)).to.be.equal((guestNumber, hostNumber));
    })

    it('Should host be able to create KYC', async function () {

        let name = "name";
        let surname = "surname";
        let number = "+380";
        let photo = "photo";
        let licenseNumber = "licenseNumber";
        let expirationDate = 10;

        await
            expect(
                rentalityUserService.connect(host).setKYCInfo(
                    name,
                    surname,
                    number,
                    photo,
                    licenseNumber,
                    expirationDate
                )).not.be.reverted

        const kycInfo = await rentalityUserService
            .connect(host)
            .getMyKYCInfo()

        expect(kycInfo.name).to.equal(name)
        expect(kycInfo.surname).to.equal(surname)
        expect(kycInfo.mobilePhoneNumber).to.equal(number)
        expect(kycInfo.profilePhoto).to.equal(photo)
        expect(kycInfo.licenseNumber).to.equal(licenseNumber)
        expect(kycInfo.expirationDate).to.equal(expirationDate)


    })
    it('Should guest be able to create KYC', async function () {
        let name = "name";
        let surname = "surname";
        let number = "+380";
        let photo = "photo";
        let licenseNumber = "licenseNumber";
        let expirationDate = 10;

        await
            expect(
                rentalityUserService.connect(guest).setKYCInfo(
                    name,
                    surname,
                    number,
                    photo,
                    licenseNumber,
                    expirationDate
                )).not.be.reverted

        const kycInfo = await rentalityUserService
            .connect(guest)
            .getMyKYCInfo()

        expect(kycInfo.name).to.equal(name)
        expect(kycInfo.surname).to.equal(surname)
        expect(kycInfo.mobilePhoneNumber).to.equal(number)
        expect(kycInfo.profilePhoto).to.equal(photo)
        expect(kycInfo.licenseNumber).to.equal(licenseNumber)
        expect(kycInfo.expirationDate).to.equal(expirationDate)
    });

    it('Should not anonymous be able to create KYC', async function () {

        // TODO! anonymous can save his data?

        let name = "name";
        let surname = "surname";
        let number = "+380";
        let photo = "photo";
        let licenseNumber = "licenseNumber";
        let expirationDate = 10;

        await
            expect(
                rentalityUserService.connect(anonymous).setKYCInfo(
                    name,
                    surname,
                    number,
                    photo,
                    licenseNumber,
                    expirationDate
                )).to.be.reverted


    })

    it('Should have chat history by guest', async function () {

        let addCarRequest = getMockCarRequest(0);
        await expect(rentalityCarToken.connect(host).addCar(addCarRequest))

        await expect(rentalityCarToken.connect(host).addCar(addCarRequest))
            .not.to.be.reverted
        const myCars = await rentalityCarToken
            .connect(host)
            .getCarsOwnedByUser(host.address)
        expect(myCars.length).to.equal(1)
        const availableCars = await rentalityCarToken
            .connect(guest)
            .getAvailableCarsForUser(guest.address)
        expect(availableCars.length).to.equal(1)

        const rentPriceInUsdCents = 1000
        const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
            await rentalityCurrencyConverter.getEthFromUsdLatest(
                rentPriceInUsdCents,
            )

        await expect(
            rentalityPlatform.connect(guest).createTripRequest(
                {
                    carId: 1,
                    host: host.address,
                    startDateTime: 123,
                    endDateTime: 321,
                    startLocation: '',
                    endLocation: '',
                    totalDayPriceInUsdCents: rentPriceInUsdCents,
                    taxPriceInUsdCents: 0,
                    depositInUsdCents: 0,
                    fuelPricePerGalInUsdCents: 400,
                    ethToCurrencyRate: ethToCurrencyRate,
                    ethToCurrencyDecimals: ethToCurrencyDecimals,
                },
                {value: rentPriceInEth},
            ),
        ).not.to.be.reverted

        // TODO! can't get kyc of host
        let chatInfo = await rentalityGateway.connect(guest).getChatInfoForGuest();
        expect(chatInfo.length).to.be.equal(0);

        expect(chatInfo.tripId).to.be.equal(1);
        expect(chatInfo.guestAddress).to.be.equal(guest.address);
        expect(chatInfo.guestPhotoUrl).to.be.equal(photo + 'guest');
        expect(chatInfo.hostAddress).to.be.equal(host.address);
        expect(chatInfo.tripStatus).to.be.equal(1);
        expect(chatInfo.carBrand).to.be.equal(addCarRequest.brand);
        expect(chatInfo.carModel).to.be.equal(addCarRequest.model);
        expect(chatInfo.carYearOfProduction).to.be.equal(addCarRequest.yearOfProduction);

    })
    it('Should have chat history by host', async function () {

        let addCarRequest = getMockCarRequest(0);
        await expect(rentalityCarToken.connect(host).addCar(addCarRequest))
            .not.to.be.reverted
        const myCars = await rentalityCarToken
            .connect(host)
            .getCarsOwnedByUser(host.address)
        expect(myCars.length).to.equal(1)
        const availableCars = await rentalityCarToken
            .connect(guest)
            .getAvailableCarsForUser(guest.address)
        expect(availableCars.length).to.equal(1)

        const rentPriceInUsdCents = 1000
        const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
            await rentalityCurrencyConverter.getEthFromUsdLatest(
                rentPriceInUsdCents,
            )
        let name = "name";
        let surname = "surname";
        let number = "+380";
        let photo = "photo";
        let licenseNumber = "licenseNumber";
        let expirationDate = 10;

        await
            expect(
                rentalityUserService.connect(host).setKYCInfo(
                    name + 'host',
                    surname + 'host',
                    number + 'host',
                    photo + 'host',
                    licenseNumber + 'host',
                    expirationDate
                )).not.be.reverted

        await
            expect(
                rentalityUserService.connect(guest).setKYCInfo(
                    name + 'guest',
                    surname + 'guest',
                    number + 'guest',
                    photo + 'guest',
                    licenseNumber + 'guest',
                    expirationDate
                )).not.be.reverted

        await expect(
            rentalityPlatform.connect(guest).createTripRequest(
                {
                    carId: 1,
                    host: host.address,
                    startDateTime: 123,
                    endDateTime: 321,
                    startLocation: '',
                    endLocation: '',
                    totalDayPriceInUsdCents: rentPriceInUsdCents,
                    taxPriceInUsdCents: 0,
                    depositInUsdCents: 0,
                    fuelPricePerGalInUsdCents: 400,
                    ethToCurrencyRate: ethToCurrencyRate,
                    ethToCurrencyDecimals: ethToCurrencyDecimals,
                },
                {value: rentPriceInEth},
            ),
        ).not.to.be.reverted

        // TODO! can't get kyc of guest
        let chatInfo = await rentalityGateway.connect(host).getChatInfoForHost();
        expect(chatInfo.length).to.be.above(0);

        expect(chatInfo.tripId).to.be.equal(1);
        expect(chatInfo.guestAddress).to.be.equal(guest.address);
        expect(chatInfo.guestPhotoUrl).to.be.equal(photo + 'guest');
        expect(chatInfo.hostAddress).to.be.equal(host.address);
        expect(chatInfo.tripStatus).to.be.equal(1);
        expect(chatInfo.carBrand).to.be.equal(addCarRequest.brand);
        expect(chatInfo.carModel).to.be.equal(addCarRequest.model);
        expect(chatInfo.carYearOfProduction).to.be.equal(addCarRequest.yearOfProduction);

    })

});


