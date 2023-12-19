import "../RentalityUserService.sol";

contract UserServiceV2Test is RentalityUserService
{
    uint256 private newData;

    constructor() {}

    function initialize() public override {
        newData = 5;
    }

    function getNewData() public view returns(uint256) {
        return newData;
    }
}