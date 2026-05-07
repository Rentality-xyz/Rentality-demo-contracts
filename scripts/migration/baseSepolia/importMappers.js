const { ethers } = require('hardhat');

const ZERO_ADDRESS = ethers.ZeroAddress;
const ZERO_BYTES32 = '0x0000000000000000000000000000000000000000000000000000000000000000';

const ROLE_INDEX = {
  isGuest: 0,
  isHost: 1,
  isManager: 2,
  isAdmin: 3,
  isAdminViewRole: 5,
  isInvestorManager: 6,
  isOracleManager: 7,
};

function valueAt(value, index, fallback = undefined) {
  return Array.isArray(value) && value[index] !== undefined ? value[index] : fallback;
}

function boolValue(value) {
  return value === true || value === 'true';
}

function bytesValue(value, fallback = '0x') {
  return typeof value === 'string' && value.startsWith('0x') ? value : fallback;
}

function addressValue(value, fallback = ZERO_ADDRESS) {
  return typeof value === 'string' && /^0x[a-fA-F0-9]{40}$/.test(value) ? ethers.getAddress(value) : fallback;
}

function bytes32Value(value) {
  return typeof value === 'string' && /^0x[a-fA-F0-9]{64}$/.test(value) ? value : ZERO_BYTES32;
}

function bytes4Value(value) {
  if (typeof value === 'string' && /^0x[a-fA-F0-9]{8}$/.test(value)) {
    return value;
  }
  if (typeof value === 'string' && /^0x0{64}$/.test(value)) {
    return '0x00000000';
  }
  return '0x00000000';
}

function mapProfile(profile, platformUserSet = new Set()) {
  const kyc = profile.kycInfo || valueAt(profile.myFullKYCInfo, 0, []);
  const additional = valueAt(profile.myFullKYCInfo, 1, ['', '']);
  const displayName = [valueAt(kyc, 0, ''), valueAt(kyc, 1, '')].filter(Boolean).join(' ');

  return {
    user: addressValue(profile.user),
    account: [
      addressValue(profile.user),
      valueAt(kyc, 6, 0),
      [displayName, valueAt(kyc, 3, '')],
    ],
    contact: [
      valueAt(kyc, 2, ''),
      valueAt(additional, 1, ''),
      boolValue(valueAt(profile.myFullKYCInfo, 2, false)),
      boolValue(valueAt(profile.myFullKYCInfo, 3, false)),
      valueAt(profile.myFullKYCInfo, 4, ''),
    ],
    consent: [boolValue(valueAt(kyc, 7, false)), bytesValue(valueAt(kyc, 8, '0x'))],
    kyc: [
      valueAt(kyc, 0, ''),
      valueAt(kyc, 1, ''),
      valueAt(kyc, 2, ''),
      valueAt(kyc, 3, ''),
      valueAt(kyc, 4, ''),
      valueAt(kyc, 5, 0),
      valueAt(kyc, 6, 0),
      boolValue(valueAt(kyc, 7, false)),
      bytesValue(valueAt(kyc, 8, '0x')),
    ],
    additional: [valueAt(additional, 0, ''), valueAt(additional, 1, '')],
    currency: ZERO_ADDRESS,
    currencyInitialized: false,
    includeInPlatformList: platformUserSet.has(ethers.getAddress(profile.user).toLowerCase()),
  };
}

function mapProfileRoles(profile) {
  const roles = profile.roles || {};
  return Object.entries(ROLE_INDEX)
    .filter(([key]) => roles[key] === true)
    .map(([, role]) => role);
}

function mapCar(car) {
  const carInfo = car.carInfo;
  const carId = Number(car.carId);
  const brand = valueAt(carInfo, 4, '');
  const model = valueAt(carInfo, 5, '');
  const tokenURI = car.tokenURI || '';
  const owner = addressValue(car.owner || valueAt(carInfo, 3));

  return {
    asset: [
      carId,
      owner,
      [brand, model].filter(Boolean).join(' '),
      tokenURI,
      car.listingMoment || 0,
    ],
    car: [
      valueAt(carInfo, 1, ''),
      bytes32Value(valueAt(carInfo, 2)),
      brand,
      model,
      valueAt(carInfo, 6, 0),
      valueAt(carInfo, 7, 0),
      valueAt(carInfo, 8, 0),
      valueAt(carInfo, 9, 0),
      valueAt(carInfo, 10, []),
      valueAt(carInfo, 11, 0),
      valueAt(carInfo, 12, 0),
      boolValue(valueAt(carInfo, 13, false)),
      boolValue(valueAt(carInfo, 14, false)),
      valueAt(carInfo, 15, ''),
      boolValue(valueAt(carInfo, 16, false)),
      bytes32Value(valueAt(carInfo, 17)),
    ],
    listingMoment: car.listingMoment || 0,
    tokenURI,
  };
}

function mapTrip(tripRecord) {
  const trip = tripRecord.trip;

  return {
    trip: [
      [
        valueAt(trip, 0, 0),
        valueAt(trip, 1, 0),
        addressValue(valueAt(trip, 3)),
        addressValue(valueAt(trip, 4)),
        valueAt(trip, 8, 0),
        valueAt(trip, 9, 0),
        valueAt(trip, 14, 0),
      ],
      valueAt(trip, 2, 0),
      valueAt(trip, 5, ''),
      valueAt(trip, 6, ''),
      valueAt(trip, 7, 0),
      valueAt(trip, 10, 0),
      valueAt(trip, 11, 0),
      valueAt(trip, 12, 0),
      valueAt(trip, 13, []),
      valueAt(trip, 15, 0),
      valueAt(trip, 16, 0),
      valueAt(trip, 17, ''),
      valueAt(trip, 18, ''),
      addressValue(valueAt(trip, 19)),
      valueAt(trip, 20, 0),
      valueAt(trip, 21, []),
      valueAt(trip, 22, 0),
      addressValue(valueAt(trip, 23)),
      valueAt(trip, 24, 0),
      addressValue(valueAt(trip, 25)),
      valueAt(trip, 26, []),
      valueAt(trip, 27, 0),
      valueAt(trip, 28, []),
      valueAt(trip, 29, 0),
      bytes32Value(valueAt(trip, 30)),
      bytes32Value(valueAt(trip, 31)),
    ],
    completedByAdminFlag: boolValue(tripRecord.completedByAdmin),
    ethSumInTripCreation: tripRecord.ethSumInTripCreation || 0,
  };
}

function mapTaxValue(value) {
  return [valueAt(value, 0, ''), valueAt(value, 1, 0), valueAt(value, 2, 0)];
}

function mapInsuranceInfo(record) {
  return [
    valueAt(record, 0, ''),
    valueAt(record, 1, ''),
    valueAt(record, 2, ''),
    valueAt(record, 3, ''),
    valueAt(record, 4, 0),
    valueAt(record, 5, 0),
    addressValue(valueAt(record, 6)),
  ];
}

function mapInvestmentCarRequest(legacyRequest) {
  const brand = valueAt(legacyRequest, 2, '');
  const model = valueAt(legacyRequest, 3, '');
  const name = [brand, model].filter(Boolean).join(' ');

  return [
    [
      [name, valueAt(legacyRequest, 0, '')],
      valueAt(legacyRequest, 1, ''),
      brand,
      model,
      valueAt(legacyRequest, 4, 0),
      valueAt(legacyRequest, 5, 0),
      valueAt(legacyRequest, 6, 0),
      valueAt(legacyRequest, 7, []),
      valueAt(legacyRequest, 8, 0),
      valueAt(legacyRequest, 9, 0),
      valueAt(legacyRequest, 10, 0),
      valueAt(legacyRequest, 12, [['', '', '', '', '', '', ''], '0x']),
      boolValue(valueAt(legacyRequest, 13, false)),
    ],
    boolValue(valueAt(legacyRequest, 14, false)),
    valueAt(legacyRequest, 15, 0),
  ];
}

function mapInvestment(dto, vinToCarId, carPaymentInfoByCarId) {
  const legacyInvestment = valueAt(dto, 0, []);
  const carRequest = valueAt(legacyInvestment, 0, []);
  const vin = valueAt(carRequest, 1, '');
  const carId = vinToCarId.get(vin) || 0;
  const payoutRoute = carPaymentInfoByCarId.get(Number(carId)) || [];
  const investment = [
    mapInvestmentCarRequest(carRequest),
    valueAt(legacyInvestment, 1, 0),
    boolValue(valueAt(legacyInvestment, 2, false)),
    valueAt(legacyInvestment, 3, 0),
  ];

  return {
    investmentId: valueAt(dto, 2, 0),
    investment,
    fundedAmount: valueAt(dto, 20, 0),
    creator: addressValue(valueAt(dto, 4)),
    currency: addressValue(valueAt(dto, 14)),
    listed: boolValue(valueAt(dto, 21, false)),
    carId,
    pool: addressValue(valueAt(payoutRoute, 1)),
    nft: addressValue(valueAt(dto, 1)),
  };
}

function mapReferralUsers(records) {
  return records.map((record) => {
    const myReferralInfo = valueAt(record.myReferralInfo, 0, []);
    return {
      user: addressValue(record.user),
      points: record.points || 0,
      referralHash: bytes4Value(record.referralHashV2),
      savedHash: bytes4Value(valueAt(myReferralInfo, 1, '0x00000000')),
      lastDailyClaim: 0,
      readyToClaim: valueAt(record.readyToClaim, 0, []),
      readyToClaimFromHash: valueAt(record.readyToClaimFromReferralHash, 0, []),
      history: valueAt(record.pointsHistory, 0, []),
    };
  });
}

function mapReferralConfig(snapshot) {
  const programPoints = valueAt(snapshot.referralPointsInfo, 0, []);
  const hashPoints = new Map(valueAt(snapshot.referralPointsInfo, 1, []).map((item) => [String(valueAt(item, 0, 0)), valueAt(item, 1, 0)]));
  const discounts = valueAt(snapshot.referralPointsInfo, 2, []).map((item) => ({
    program: valueAt(item, 0, 0),
    tier: valueAt(item, 1, 0),
    discount: valueAt(item, 2, [0, 0]),
  }));

  const rulesByProgram = new Map();
  for (const item of programPoints) {
    const accrualType = Number(valueAt(item, 0, 0));
    const program = valueAt(item, 1, 0);
    const points = valueAt(item, 2, 0);
    const key = String(program);
    const current = rulesByProgram.get(key) || {
      program,
      oneTimeRule: ['0x00000000', 0, 0],
      permanentRule: ['0x00000000', 0, 0],
      hashPoints: hashPoints.get(key) || 0,
    };

    if (accrualType === 0) {
      current.oneTimeRule = ['0x00000000', points, 0];
    } else {
      current.permanentRule = ['0x00000000', points, 0];
    }
    rulesByProgram.set(key, current);
  }

  for (const [program, points] of hashPoints.entries()) {
    if (!rulesByProgram.has(program)) {
      rulesByProgram.set(program, {
        program,
        oneTimeRule: ['0x00000000', 0, 0],
        permanentRule: ['0x00000000', 0, 0],
        hashPoints: points,
      });
    }
  }

  return {
    rules: [...rulesByProgram.values()],
    discounts,
    tiers: (snapshot.allTiersInfo || []).map((item) => ({ points: valueAt(item, 0, [0, 0]), tier: valueAt(item, 1, 0) })),
    passed: [],
    tripDiscounts: [],
    carDaily: (snapshot.carDailyClaimed || []).map((item) => ({
      carId: item.carId,
      claimedAt: item.claimedTime || 0,
    })),
  };
}

module.exports = {
  mapProfile,
  mapProfileRoles,
  mapCar,
  mapTrip,
  mapTaxValue,
  mapInsuranceInfo,
  mapInvestment,
  mapReferralUsers,
  mapReferralConfig,
};
