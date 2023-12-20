const { upgrades, ethers } = require('hardhat')
const { expect } = require('chai')

describe('Proxy', function() {
  async function deployUserService() {
    const [owner, admin] = await ethers.getSigners()
    const RentalityUserService = await ethers.getContractFactory('RentalityUserService')
    const userService = await upgrades.deployProxy(RentalityUserService)
    await userService.initialize()

    return { userService, owner, admin }
  }

  it('should be able to update contract and save state', async function() {
    let { userService, owner, admin } = await deployUserService()
    let proxyAddress = await userService.getAddress()

    await expect(await userService.isManager(owner.address)).to.be.true
    expect(await userService.setKYCInfo(
        'name',
        'surname',
        'phone',
        'photo',
       'number',
        11,
      )).to.not.reverted

    const UserServiceV2 = await ethers.getContractFactory('UserServiceV2Test')
    const userServiceV2 = await UserServiceV2.deploy()
    await userServiceV2.waitForDeployment()

    const v2address = await userServiceV2.getAddress()

    const data = userServiceV2.interface.encodeFunctionData('initialize', [])
    await userService.upgradeToAndCall(v2address, data)

    const v2 = await UserServiceV2.attach(proxyAddress)

    const kyc = await v2.getKYCInfo(owner.address);
    await expect(await v2.isManager(owner.address)).to.be.true
    expect(kyc.name).to.be.eq("name")
    await expect(await v2.getNewData()).to.be.eq(5)
  })
})
