const {
  time,
  loadFixture,
} = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('RentalityUserService', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
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
      { libraries: { RentalityUtils: utils.address } },
    )
    const RentalityCurrencyConverter = await ethers.getContractFactory(
      'RentalityCurrencyConverter',
    )
    const RentalityPaymentService = await ethers.getContractFactory(
      'RentalityPaymentService',
    )
    const RentalityGeoService = await ethers.getContractFactory(
      'RentalityGeoMock');



    const RentalityCarToken =
      await ethers.getContractFactory('RentalityCarToken')
    const RentalityPlatform =
      await ethers.getContractFactory('RentalityPlatform',{
        libraries:
            {
              RentalityUtils: utils.address
            }
      })

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

    const rentalityGeoService = await RentalityGeoService.deploy();
    await rentalityGeoService.deployed();

    const rentalityCarToken = await RentalityCarToken.deploy(rentalityGeoService.address)

    await rentalityCarToken.deployed()

    const rentalityPaymentService = await RentalityPaymentService.deploy()

    const rentalityTripService = await RentalityTripService.deploy(
      rentalityCurrencyConverter.address,
      rentalityPaymentService.address,
      rentalityUserService.address,
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
      .grantManagerRole(rentalityPlatform.address)
    await rentalityUserService
      .connect(owner)
      .grantManagerRole(rentalityTripService.address)

    return {
      rentalityMockPriceFeed,
      rentalityUserService,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityCarToken,
      rentalityPlatform,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    }
  }

  async function deployFixtureWithUsers() {
    const [owner, admin, manager, host, guest, anonymous] =
      await ethers.getSigners()
    const RentalityUserService = await ethers.getContractFactory(
      'RentalityUserService',
    )

    const rentalityUserService = await RentalityUserService.deploy()
    await rentalityUserService.deployed()

    await rentalityUserService.connect(owner).grantAdminRole(admin.address)
    await rentalityUserService.connect(owner).grantManagerRole(manager.address)
    await rentalityUserService.connect(owner).grantHostRole(host.address)
    await rentalityUserService.connect(owner).grantGuestRole(guest.address)

    return {
      rentalityUserService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
    }
  }

  function getMockCarRequest(seed) {
    const seedStr = seed?.toString() ?? ''
    const seedInt = Number(seed) ?? 0

    const TOKEN_URI = 'TOKEN_URI' + seedStr
    const VIN_NUMBER = 'VIN_NUMBER' + seedStr
    const BRAND = 'BRAND' + seedStr
    const MODEL = 'MODEL' + seedStr
    const YEAR = '200' + seedStr
    const PRICE_PER_DAY = seedInt * 100 + 2
    const DEPOSIT = seedInt * 100 + 3
    const TANK_VOLUME = seedInt * 100 + 4
    const FUEL_PRICE = seedInt * 100 + 5
    const DISTANCE_INCLUDED = seedInt * 100 + 6
    const location = 'kyiv ukraine'
    const apiKey = 'AIzaSyBZ9Ii2pMKHcJrMFvWSPxG8NPSIsdS0nLs'


    return {
      tokenUri: TOKEN_URI,
      carVinNumber: VIN_NUMBER,
      brand: BRAND,
      model: MODEL,
      yearOfProduction: YEAR,
      pricePerDayInUsdCents: PRICE_PER_DAY,
      securityDepositPerTripInUsdCents: DEPOSIT,
      tankVolumeInGal: TANK_VOLUME,
      fuelPricePerGalInUsdCents: FUEL_PRICE,
      milesIncludedPerDay: DISTANCE_INCLUDED,
      locationAddress: location,
      geoApiKey: apiKey,
    }
  }

  describe('Deployment', function () {
    it('Owner should have all roles', async function () {
      const { rentalityUserService, owner } =
        await loadFixture(deployDefaultFixture)

      expect(await rentalityUserService.isAdmin(owner.address)).to.equal(true)
      expect(await rentalityUserService.isManager(owner.address)).to.equal(true)
      expect(await rentalityUserService.isHost(owner.address)).to.equal(true)
      expect(await rentalityUserService.isGuest(owner.address)).to.equal(true)
    })

    it('deployFixtureWithUsers: users should have correct roles', async function () {
      const { rentalityUserService, admin, manager, host, guest } =
        await loadFixture(deployFixtureWithUsers)

      expect(await rentalityUserService.isAdmin(admin.address)).to.equal(true)
      expect(await rentalityUserService.isManager(manager.address)).to.equal(
        true,
      )
      expect(await rentalityUserService.isHost(host.address)).to.equal(true)
      expect(await rentalityUserService.isGuest(guest.address)).to.equal(true)
    })
  })

  describe('Role management', function () {
    it('Admin should have Manager role', async function () {
      const { rentalityUserService, admin } = await loadFixture(
        deployFixtureWithUsers,
      )

      expect(await rentalityUserService.isAdmin(admin.address)).to.equal(true)
      expect(await rentalityUserService.isManager(admin.address)).to.equal(true)
      expect(await rentalityUserService.isHost(admin.address)).to.equal(false)
      expect(await rentalityUserService.isGuest(admin.address)).to.equal(false)
    })

    it("Anonymous shouldn't get any role", async function () {
      const { rentalityUserService, anonymous } = await loadFixture(
        deployFixtureWithUsers,
      )

      expect(await rentalityUserService.isAdmin(anonymous.address)).to.equal(
        false,
      )
      expect(await rentalityUserService.isManager(anonymous.address)).to.equal(
        false,
      )
      expect(await rentalityUserService.isHost(anonymous.address)).to.equal(
        false,
      )
      expect(await rentalityUserService.isGuest(anonymous.address)).to.equal(
        false,
      )
    })

    it('Only Admin can grandAdminRole', async function () {
      const { rentalityUserService, admin, manager, host, guest, anonymous } =
        await loadFixture(deployFixtureWithUsers)

      await expect(
        rentalityUserService.connect(admin).grantAdminRole(admin.address),
      ).not.to.be.reverted
      await expect(
        rentalityUserService.connect(manager).grantAdminRole(admin.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(host).grantAdminRole(admin.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(guest).grantAdminRole(admin.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(anonymous).grantAdminRole(admin.address),
      ).to.be.reverted
    })

    it('Only Admin can revokeAdminRole', async function () {
      const {
        rentalityUserService,
        owner,
        admin,
        manager,
        host,
        guest,
        anonymous,
      } = await loadFixture(deployFixtureWithUsers)

      await expect(
        rentalityUserService.connect(anonymous).revokeAdminRole(owner.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(guest).revokeAdminRole(owner.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(host).revokeAdminRole(owner.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(manager).revokeAdminRole(owner.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(admin).revokeAdminRole(owner.address),
      ).not.to.be.reverted
    })

    it('Only Admin can grantManagerRole', async function () {
      const { rentalityUserService, admin, manager, host, guest, anonymous } =
        await loadFixture(deployFixtureWithUsers)

      await expect(
        rentalityUserService.connect(admin).grantManagerRole(manager.address),
      ).not.to.be.reverted
      await expect(
        rentalityUserService.connect(manager).grantManagerRole(manager.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(host).grantManagerRole(manager.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(guest).grantManagerRole(manager.address),
      ).to.be.reverted
      await expect(
        rentalityUserService
          .connect(anonymous)
          .grantManagerRole(manager.address),
      ).to.be.reverted
    })

    it('Only Admin can revokeManagerRole', async function () {
      const { rentalityUserService, admin, manager, host, guest, anonymous } =
        await loadFixture(deployFixtureWithUsers)

      await expect(
        rentalityUserService
          .connect(anonymous)
          .revokeManagerRole(manager.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(guest).revokeManagerRole(manager.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(host).revokeManagerRole(manager.address),
      ).to.be.reverted
      await expect(
        rentalityUserService
          .connect(manager)
          .revokeManagerRole(manager.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(admin).revokeManagerRole(manager.address),
      ).not.to.be.reverted
    })

    it('Only Admin and Manager can grantHostRole', async function () {
      const { rentalityUserService, admin, manager, host, guest, anonymous } =
        await loadFixture(deployFixtureWithUsers)

      await expect(
        rentalityUserService.connect(admin).grantHostRole(host.address),
      ).not.to.be.reverted
      await expect(
        rentalityUserService.connect(manager).grantHostRole(host.address),
      ).not.to.be.reverted
      await expect(
        rentalityUserService.connect(host).grantHostRole(host.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(guest).grantHostRole(host.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(anonymous).grantHostRole(host.address),
      ).to.be.reverted
    })

    it('Only Admin and Manager can revokeHostRole', async function () {
      const { rentalityUserService, admin, manager, host, guest, anonymous } =
        await loadFixture(deployFixtureWithUsers)

      await expect(
        rentalityUserService.connect(anonymous).revokeHostRole(host.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(guest).revokeHostRole(host.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(host).revokeHostRole(host.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(manager).revokeHostRole(host.address),
      ).not.to.be.reverted
      await expect(
        rentalityUserService.connect(admin).revokeHostRole(host.address),
      ).not.to.be.reverted
    })

    it('Only Admin and Manager can grantGuestRole', async function () {
      const { rentalityUserService, admin, manager, host, guest, anonymous } =
        await loadFixture(deployFixtureWithUsers)

      await expect(
        rentalityUserService.connect(admin).grantGuestRole(guest.address),
      ).not.to.be.reverted
      await expect(
        rentalityUserService.connect(manager).grantGuestRole(guest.address),
      ).not.to.be.reverted
      await expect(
        rentalityUserService.connect(host).grantGuestRole(guest.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(guest).grantGuestRole(guest.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(anonymous).grantGuestRole(guest.address),
      ).to.be.reverted
    })

    it('Only Admin and Manager can revokeGuestRole', async function () {
      const { rentalityUserService, admin, manager, host, guest, anonymous } =
        await loadFixture(deployFixtureWithUsers)

      await expect(
        rentalityUserService.connect(anonymous).revokeGuestRole(guest.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(guest).revokeGuestRole(guest.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(host).revokeGuestRole(guest.address),
      ).to.be.reverted
      await expect(
        rentalityUserService.connect(manager).revokeGuestRole(guest.address),
      ).not.to.be.reverted
      await expect(
        rentalityUserService.connect(admin).revokeGuestRole(guest.address),
      ).not.to.be.reverted
    })
  })

  describe('KYC management', function () {
    it("By default user doesn't have valid KYC", async function () {
      const { rentalityUserService, anonymous } = await loadFixture(
        deployFixtureWithUsers,
      )

      expect(
        await rentalityUserService.hasValidKYC(anonymous.address),
      ).to.equal(false)
    })

    it('After adding valid KYCInfo user has valid KYC', async function () {
      const { rentalityUserService, anonymous } = await loadFixture(
        deployFixtureWithUsers,
      )
      const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
      const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

      await rentalityUserService
        .connect(anonymous)
        .setKYCInfo(
          'name',
          'surname',
          'phoneNumber',
          'profilePicture',
          'licenseNumber',
          expirationDate,
        )

      expect(
        await rentalityUserService.hasValidKYC(anonymous.address),
      ).to.equal(true)
    })

    it("After adding invalid KYCInfo user doesn't have valid KYC", async function () {
      const { rentalityUserService, anonymous } = await loadFixture(
        deployFixtureWithUsers,
      )
      const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
      const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

      await rentalityUserService
        .connect(anonymous)
        .setKYCInfo(
          'name',
          'surname',
          'phoneNumber',
          'profilePicture',
          'licenseNumber',
          expirationDate,
        )
      await time.increaseTo(expirationDate + 1)

      expect(
        await rentalityUserService.hasValidKYC(anonymous.address),
      ).to.equal(false)
    })

    it('After adding valid KYCInfo, user can get their own KYCInfo', async function () {
      const { rentalityUserService, guest } = await loadFixture(
        deployFixtureWithUsers,
      )
      const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
      const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

      await rentalityUserService
        .connect(guest)
        .setKYCInfo(
          'name',
          'surname',
          'phoneNumber',
          'profilePicture',
          'licenseNumber',
          expirationDate,
        )

      const kycInfo = await rentalityUserService.connect(guest).getMyKYCInfo()

      expect(kycInfo.name).to.equal('name')
      expect(kycInfo.surname).to.equal('surname')
      expect(kycInfo.mobilePhoneNumber).to.equal('phoneNumber')
      expect(kycInfo.profilePhoto).to.equal('profilePicture')
      expect(kycInfo.licenseNumber).to.equal('licenseNumber')
      expect(kycInfo.expirationDate).to.equal(expirationDate)
    })

    it('User cannot get other users KYCInfo', async function () {
      const { rentalityUserService, guest, host } = await loadFixture(
        deployFixtureWithUsers,
      )
      const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
      const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

      await rentalityUserService
        .connect(guest)
        .setKYCInfo(
          'name',
          'surname',
          'phoneNumber',
          'profilePicture',
          'licenseNumber',
          expirationDate,
        )

      await expect(rentalityUserService.connect(host).getKYCInfo(guest.address))
        .to.be.reverted
    })

    it('Manager can get other users KYCInfo', async function () {
      const { rentalityUserService, guest, manager } = await loadFixture(
        deployFixtureWithUsers,
      )
      const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
      const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

      await rentalityUserService
        .connect(guest)
        .setKYCInfo(
          'name',
          'surname',
          'phoneNumber',
          'profilePicture',
          'licenseNumber',
          expirationDate,
        )

      const isManager = await rentalityUserService.isManager(manager.address)
      expect(isManager).to.equal(true)

      const kycInfo = await rentalityUserService
        .connect(manager)
        .getKYCInfo(guest.address)

      expect(kycInfo.name).to.equal('name')
      expect(kycInfo.surname).to.equal('surname')
      expect(kycInfo.mobilePhoneNumber).to.equal('phoneNumber')
      expect(kycInfo.profilePhoto).to.equal('profilePicture')
      expect(kycInfo.licenseNumber).to.equal('licenseNumber')
      expect(kycInfo.expirationDate).to.equal(expirationDate)
    })

    it('After a trip is requested, the host or guest can get the contact numbers of the host and guest', async function () {
      const {
        rentalityPlatform,
        rentalityCurrencyConverter,
        host,
        rentalityCarToken,
        guest,
        manager,
        rentalityTripService,
        rentalityUserService,
      } = await loadFixture(deployDefaultFixture)

      await expect(rentalityCarToken.connect(host).addCar(getMockCarRequest(0)))
        .not.to.be.reverted
      const availableCars = await rentalityCarToken
        .connect(guest)
        .getAvailableCarsForUser(guest.address)
      expect(availableCars.length).to.equal(1)

      const rentPriceInUsdCents = 1600
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverter.getEthFromUsdLatest(
          rentPriceInUsdCents,
        )

      const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
      const expirationDate = (await time.latest()) + ONE_YEAR_IN_SECS

      await rentalityUserService
        .connect(guest)
        .setKYCInfo(
          'name',
          'surname',
          'phoneNumberGuest',
          'profilePicture',
          'licenseNumber',
          expirationDate,
        )

      await rentalityUserService
        .connect(host)
        .setKYCInfo(
          'name',
          'surname',
          'phoneNumberHost',
          'profilePicture',
          'licenseNumber',
          expirationDate,
        )

      await expect(
        await rentalityPlatform.connect(guest).createTripRequest(
          {
            carId: 1,
            host: host.address,
            startDateTime: 123,
            endDateTime: 321,
            startLocation: '',
            endLocation: '',
            totalDayPriceInUsdCents: 1000,
            taxPriceInUsdCents: 200,
            depositInUsdCents: 400,
            fuelPricePerGalInUsdCents: 400,
            ethToCurrencyRate: ethToCurrencyRate,
            ethToCurrencyDecimals: ethToCurrencyDecimals,
          },
          { value: rentPriceInEth },
        ),
      ).not.to.be.reverted
      expect(
        (await rentalityTripService.connect(host).getTrip(1)).status,
      ).to.equal(0)

      let [guestPhoneNumber, hostPhoneNumber] = await rentalityPlatform
        .connect(guest)
        .getTripContactInfo(1)

      expect(guestPhoneNumber).to.equal('phoneNumberGuest')
      expect(hostPhoneNumber).to.equal('phoneNumberHost')[
        (guestPhoneNumber, hostPhoneNumber)
      ] = await rentalityPlatform.connect(host).getTripContactInfo(1)

      expect(guestPhoneNumber).to.equal('phoneNumberGuest')
      expect(hostPhoneNumber).to.equal('phoneNumberHost')
    })
  })
})
