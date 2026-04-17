// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../base/referral/ReferralBase.sol';
import './RentalReferralTypes.sol';

interface IRentalReferralAccess {
    function isRentalityPlatform(address user) external view returns (bool);
}

interface IRentalReferralCarQuery {
    function totalSupply() external view returns (uint256);
    function exists(uint256 id) external view returns (bool);
    function getOwner(uint256 id) external view returns (address);
    function getListingMoment(uint256 id) external view returns (uint256);
}

contract RentalReferralMain is ReferralBase, UUPSOwnable {
    IRentalReferralAccess public userAccess;
    IRentalReferralCarQuery public carQuery;
    address public referralLib;

    error OnlyPlatform();
    error OwnHash();
    error NotEnoughPoints();
    error FailedToCalculatePoints();

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

    function initialize(address userAccessAddress, address carQueryAddress, address referralLibAddress)
        public
        initializer
    {
        __Ownable_init();
        userAccess = IRentalReferralAccess(userAccessAddress);
        carQuery = IRentalReferralCarQuery(carQueryAddress);
        referralLib = referralLibAddress;
    }

    function updateUserAccess(address userAccessAddress) external onlyOwner {
        userAccess = IRentalReferralAccess(userAccessAddress);
    }

    function updateCarQuery(address carQueryAddress) external onlyOwner {
        carQuery = IRentalReferralCarQuery(carQueryAddress);
    }

    function updateReferralLib(address referralLibAddress) external onlyOwner {
        referralLib = referralLibAddress;
    }

    function getCarDailyClaimedTime(uint256 carId) external view returns (uint256) {
        return carIdToDailyClaimed[carId];
    }

    function getMyStartDiscount(address user) external view returns (uint256) {
        ReferralTier tier = getTierTypeByPoints(addressToPoints[user]);
        return selectorToDiscounts[ReferralProgram.CreateTrip][tier].percents;
    }

    function passReferralProgram(
        ReferralProgram selector,
        bytes memory callbackArgs,
        address user,
        address /*promoServiceAddress*/
    ) external onlyPlatform {
        bytes4 hash = userToSavedHash[user];
        (address owner, uint256 hashPoints) = _getHashProgramInfoIfExists(selector, hash, user);
        (int256 points, bool isOneTime) = _setPassedIfExists(selector, callbackArgs, owner != address(0), user);

        if (points > 0) {
            if (isOneTime && hashPoints > 0) {
                userToReadyToClaimFromHash[owner].push(
                    ReadyToClaimFromHash({
                        points: hashPoints,
                        refType: selector,
                        oneTime: true,
                        claimed: false,
                        user: user
                    })
                );
            }

            addressToReadyToClaim[user].push(
                ReadyToClaim({points: uint256(points), refType: selector, oneTime: isOneTime})
            );
        } else if (points < 0) {
            uint256 pointsToReduce = uint256(-points);
            if (addressToPoints[user] < pointsToReduce) {
                addressToPoints[user] = 0;
            } else {
                addressToPoints[user] -= pointsToReduce;
            }
            userProgramHistory[user].push(
                ReferralProgramHistory({
                    points: points,
                    date: block.timestamp,
                    method: selector,
                    oneTime: isOneTime
                })
            );
        }
    }

    function useDiscount(ReferralProgram selector, bool host, uint256 tripId, address user)
        external
        onlyPlatform
        returns (uint256)
    {
        uint256 userPoints = addressToPoints[user];
        ReferralTier tier = getTierTypeByPoints(userPoints);
        uint256 percents = 0;
        if (tier != ReferralTier.Tier1) {
            (uint256 possibleDiscount, uint256 pointsCost) = getDiscount(selector, tier);
            if (pointsCost == 0 || userPoints < pointsCost) {
                revert NotEnoughPoints();
            }
            addressToPoints[user] -= pointsCost;
            percents = possibleDiscount;
        }

        if (percents > 0) {
            TripDiscounts storage discounts = tripIdToDiscount[tripId];
            if (host) {
                discounts.host = percents;
            } else {
                discounts.guest = percents;
            }
        }

        return percents;
    }

    function claimPoints(address user) external onlyPlatform {
        ReadyToClaim[] memory toClaim = addressToReadyToClaim[user];
        uint256 daily = updateDaily(user);
        (uint256 dailyListingPoints, uint256[] memory cars) = calculateListedCarsPoints(
            int256(permanentSelectorToPoints[ReferralProgram.DailyListing].points),
            user
        );

        uint256 total = 0;
        if (dailyListingPoints > 0) {
            uint256 time = block.timestamp;
            for (uint256 i = 0; i < cars.length; i++) {
                carIdToDailyClaimed[cars[i]] = time;
            }
            userProgramHistory[user].push(
                ReferralProgramHistory({
                    points: int256(dailyListingPoints),
                    date: block.timestamp,
                    method: ReferralProgram.DailyListing,
                    oneTime: false
                })
            );
            total += dailyListingPoints;
        }

        if (toClaim.length > 0) {
            delete addressToReadyToClaim[user];
            for (uint256 i = 0; i < toClaim.length; i++) {
                total += toClaim[i].points;
                userProgramHistory[user].push(
                    ReferralProgramHistory({
                        points: int256(toClaim[i].points),
                        date: block.timestamp,
                        method: toClaim[i].refType,
                        oneTime: toClaim[i].oneTime
                    })
                );
            }
        }

        if (daily > 0) {
            userProgramHistory[user].push(
                ReferralProgramHistory({
                    points: int256(daily),
                    date: block.timestamp,
                    method: ReferralProgram.Daily,
                    oneTime: false
                })
            );
            total += daily;
        }

        addressToPoints[user] += total;
    }

    function claimReferralPoints(address user) external onlyPlatform {
        ReadyToClaimFromHash[] storage availableToClaim = userToReadyToClaimFromHash[user];
        uint256 total;
        for (uint256 i = 0; i < availableToClaim.length; i++) {
            if (!availableToClaim[i].claimed) {
                total += availableToClaim[i].points;
                availableToClaim[i].claimed = true;
            }
        }
        addressToPoints[user] += total;
    }

    function getMyReferralInfo(address user) external view returns (MyReferralInfoDTO memory) {
        return MyReferralInfoDTO({myHash: referralHashV2[user], savedHash: userToSavedHash[user]});
    }

    function getReferralPointsInfo() external view returns (AllReferralInfoDTO memory) {
        uint256 programPointsCount;
        uint256 hashPointsCount;
        uint256 discountsCount;

        for (uint256 i = 0; i <= uint256(type(ReferralProgram).max); i++) {
            ReferralProgram program = ReferralProgram(i);
            if (selectorToPoints[program].points != 0) programPointsCount += 1;
            if (permanentSelectorToPoints[program].points != 0) programPointsCount += 1;
            if (selectorHashToPoints[program] != 0) hashPointsCount += 1;
            if (selectorToDiscounts[program][ReferralTier.Tier2].percents != 0) discountsCount += 3;
        }

        ReferralProgramInfoDTO[] memory programPoints = new ReferralProgramInfoDTO[](programPointsCount);
        HashPointsDTO[] memory hashPoints = new HashPointsDTO[](hashPointsCount);
        ReferralDiscountsDTO[] memory discounts = new ReferralDiscountsDTO[](discountsCount);
        TierDTO[] memory tiers = getAllTierInfo();

        uint256 p;
        uint256 h;
        uint256 d;
        for (uint256 i = 0; i <= uint256(type(ReferralProgram).max); i++) {
            ReferralProgram program = ReferralProgram(i);
            int256 oneTimePoints = selectorToPoints[program].points;
            if (oneTimePoints != 0) {
                programPoints[p++] = ReferralProgramInfoDTO({
                    referralType: ReferralAccrualType.OneTime,
                    method: program,
                    points: oneTimePoints
                });
            }

            int256 permanentPoints = permanentSelectorToPoints[program].points;
            if (permanentPoints != 0) {
                programPoints[p++] = ReferralProgramInfoDTO({
                    referralType: ReferralAccrualType.Permanent,
                    method: program,
                    points: permanentPoints
                });
            }

            uint256 hashPts = selectorHashToPoints[program];
            if (hashPts != 0) {
                hashPoints[h++] = HashPointsDTO({method: program, points: hashPts});
            }

            if (selectorToDiscounts[program][ReferralTier.Tier2].percents != 0) {
                for (uint256 j = 1; j <= uint256(type(ReferralTier).max); j++) {
                    ReferralTier tier = ReferralTier(j);
                    discounts[d++] = ReferralDiscountsDTO({
                        method: program,
                        tier: tier,
                        discount: selectorToDiscounts[program][tier]
                    });
                }
            }
        }

        return AllReferralInfoDTO({
            programPoints: programPoints,
            hashPoints: hashPoints,
            discounts: discounts,
            tier: tiers
        });
    }

    function generateReferralHash(address user) external onlyPlatform {
        bytes4 hash = createReferralHash(user);
        hashToOwnerV2[hash] = user;
        referralHashV2[user] = hash;
    }

    function saveReferralHash(bytes4 hash, bool isGuest, address sender) external onlyPlatform {
        address user = hashToOwnerV2[hash];
        if (!isGuest && hash != bytes4(0) && user != address(0) && user != sender) {
            userToSavedHash[sender] = hash;
        }
    }

    function manageTierInfo(ReferralTier tier, uint256 from, uint256 to) external onlyPlatform {
        tierToPoints[tier] = TierPoints({from: from, to: to});
    }

    function manageReferralDiscount(
        ReferralProgram selector,
        ReferralTier tier,
        uint256 points,
        uint256 percents
    ) external onlyPlatform {
        selectorToDiscounts[selector][tier] = ReferralDiscount({pointsCosts: points, percents: percents});
    }

    function manageReferralHashProgram(ReferralProgram selector, uint256 points) external onlyPlatform {
        selectorHashToPoints[selector] = points;
    }

    function addPermanentProgram(ReferralProgram selector, int256 points, bytes4 callback) external onlyPlatform {
        ReferralPointsRule storage rule = permanentSelectorToPoints[selector];
        rule.callback = callback;
        rule.points = points;
    }

    function addOneTimeProgram(
        ReferralProgram selector,
        int256 points,
        int256 pointsWithReferralCode,
        bytes4 callback
    ) external onlyPlatform {
        ReferralPointsRule storage rule = selectorToPoints[selector];
        rule.callback = callback;
        rule.points = points;
        rule.pointsWithReferralCode = pointsWithReferralCode;
    }

    function getTierTypeByPoints(uint256 points) public view returns (ReferralTier) {
        for (uint256 i = 0; i <= uint256(type(ReferralTier).max); i++) {
            TierPoints memory tier = tierToPoints[ReferralTier(i)];
            if (tier.from <= points && tier.to >= points) {
                return ReferralTier(i);
            }
        }
        return ReferralTier.Tier1;
    }

    function getAllTierInfo() public view returns (TierDTO[] memory) {
        TierDTO[] memory tiers = new TierDTO[](uint256(type(ReferralTier).max) + 1);
        for (uint256 i = 0; i <= uint256(type(ReferralTier).max); i++) {
            ReferralTier tier = ReferralTier(i);
            tiers[i] = TierDTO({points: tierToPoints[tier], tier: tier});
        }
        return tiers;
    }

    function getDiscount(ReferralProgram selector, ReferralTier tier) public view returns (uint256, uint256) {
        ReferralDiscount memory discount = selectorToDiscounts[selector][tier];
        return (discount.percents, discount.pointsCosts);
    }

    function updateDaily(address user) public returns (uint256) {
        uint256 last = addressToLastDailyClaim[user];
        if (block.timestamp >= last + 1 days) {
            addressToLastDailyClaim[user] = block.timestamp;
            return uint256(permanentSelectorToPoints[ReferralProgram.Daily].points);
        }
        return 0;
    }

    function createReferralHash(address user) public pure returns (bytes4) {
        return bytes4(keccak256(abi.encode(this.generateReferralHash.selector, user)));
    }

    function calculateListedCarsPoints(int256 points, address user) public view returns (uint256, uint256[] memory) {
        uint256 totalPoints = 0;
        uint256 supply = carQuery.totalSupply();
        uint256[] memory temp = new uint256[](supply);
        uint256 count = 0;

        for (uint256 i = 1; i <= supply; i++) {
            if (!carQuery.exists(i) || carQuery.getOwner(i) != user) {
                continue;
            }

            uint256 listingMoment = carQuery.getListingMoment(i);
            if (listingMoment == 0) {
                continue;
            }

            uint256 claimedAt = carIdToDailyClaimed[i];
            if (block.timestamp >= claimedAt + 1 days) {
                totalPoints += uint256(points);
                temp[count++] = i;
            }
        }

        uint256[] memory cars = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            cars[i] = temp[i];
        }

        return (totalPoints, cars);
    }

    function _getHashProgramInfoIfExists(ReferralProgram selector, bytes4 hash, address user)
        internal
        view
        returns (address, uint256)
    {
        if (createReferralHash(user) == hash) {
            revert OwnHash();
        }

        if (selectorHashToPoints[selector] > 0) {
            return (hashToOwnerV2[hash], selectorHashToPoints[selector]);
        }

        return (address(0), 0);
    }

    function _setPassedIfExists(
        ReferralProgram selector,
        bytes memory callbackArgs,
        bool hasReferralCode,
        address user
    ) internal returns (int256, bool) {
        ReferralPointsRule memory rule = selectorToPoints[selector];
        bool isOneTime = true;

        if (rule.points != 0) {
            bool passed = selectorToPassedAddress[selector][user];
            if (passed) {
                rule = permanentSelectorToPoints[selector];
                isOneTime = false;
            } else {
                selectorToPassedAddress[selector][user] = true;
                if (hasReferralCode) {
                    rule.points = rule.pointsWithReferralCode;
                }
            }
        } else {
            rule = permanentSelectorToPoints[selector];
            isOneTime = false;
        }

        if (rule.callback != bytes4(0) && referralLib != address(0)) {
            (bool ok, bytes memory callbackResult) = referralLib.staticcall(
                abi.encodeWithSelector(rule.callback, rule.points, callbackArgs)
            );
            if (!ok) {
                revert FailedToCalculatePoints();
            }
            rule.points = abi.decode(callbackResult, (int256));
        }

        return (rule.points, isOneTime);
    }
}
