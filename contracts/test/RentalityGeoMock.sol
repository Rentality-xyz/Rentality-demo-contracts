// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../libs/RentalityUtils.sol';
import 'hardhat/console.sol';
// For testing purposes
contract RentalityGeoMock {
    constructor() {
        countryToTimeZoneId['Ukraine'] = 'Europe/Kyiv';
        countryToTimeZoneId['USA'] = 'America/New_York';
        countryToTimeZoneId['Canada'] = 'America/Toronto';
        countryToTimeZoneId['Mexico'] = 'America/Mexico_City';
        countryToTimeZoneId['Brazil'] = 'America/Sao_Paulo';
        countryToTimeZoneId['Argentina'] = 'America/Argentina/Buenos_Aires';
        countryToTimeZoneId['Chile'] = 'America/Santiago';
        countryToTimeZoneId['Peru'] = 'America/Lima';
        countryToTimeZoneId['Colombia'] = 'America/Bogota';
        countryToTimeZoneId['Venezuela'] = 'America/Caracas';
        countryToTimeZoneId['Ecuador'] = 'America/Guayaquil';
        countryToTimeZoneId['Bolivia'] = 'America/La_Paz';
        countryToTimeZoneId['Paraguay'] = 'America/Asuncion';
        countryToTimeZoneId['Uruguay'] = 'America/Montevideo';
        countryToTimeZoneId['Panama'] = 'America/Panama';
        countryToTimeZoneId['Costa Rica'] = 'America/Costa_Rica';
        countryToTimeZoneId['Cuba'] = 'America/Havana';
        countryToTimeZoneId['Jamaica'] = 'America/Jamaica';
        countryToTimeZoneId['Haiti'] = 'America/Port-au-Prince';
        countryToTimeZoneId['Dominican Republic'] = 'America/Santo_Domingo';
        countryToTimeZoneId['Trinidad and Tobago'] = 'America/Port_of_Spain';
        countryToTimeZoneId['Guatemala'] = 'America/Guatemala';
        countryToTimeZoneId['Honduras'] = 'America/Tegucigalpa';
        countryToTimeZoneId['El Salvador'] = 'America/El_Salvador';
        countryToTimeZoneId['Nicaragua'] = 'America/Managua';
        countryToTimeZoneId['Costa Rica'] = 'America/Costa_Rica';
        countryToTimeZoneId['Belize'] = 'America/Belize';
        countryToTimeZoneId['Panama'] = 'America/Panama';
        countryToTimeZoneId['Bahamas'] = 'America/Nassau';
        countryToTimeZoneId['Jamaica'] = 'America/Jamaica';
        countryToTimeZoneId['Haiti'] = 'America/Port-au-Prince';
        countryToTimeZoneId['Dominican Republic'] = 'America/Santo_Domingo';
        countryToTimeZoneId['Barbados'] = 'America/Barbados';
        countryToTimeZoneId['Trinidad and Tobago'] = 'America/Port_of_Spain';
        countryToTimeZoneId['Dominica'] = 'America/Dominica';
        countryToTimeZoneId['St. Lucia'] = 'America/St_Lucia';
        countryToTimeZoneId['St. Kitts and Nevis'] = 'America/St_Kitts';
        countryToTimeZoneId['Antigua and Barbuda'] = 'America/Antigua';
        countryToTimeZoneId['Grenada'] = 'America/Grenada';
        countryToTimeZoneId['St. Vincent and the Grenadines'] = 'America/St_Vincent';
        countryToTimeZoneId['Cuba'] = 'America/Havana';
        countryToTimeZoneId['Mexico'] = 'America/Mexico_City';
        countryToTimeZoneId['Canada'] = 'America/Toronto';
        countryToTimeZoneId['United States'] = 'America/New_York';
        countryToTimeZoneId['Brazil'] = 'America/Sao_Paulo';
        countryToTimeZoneId['Argentina'] = 'America/Argentina/Buenos_Aires';
        countryToTimeZoneId['Colombia'] = 'America/Bogota';
        countryToTimeZoneId['Peru'] = 'America/Lima';
        countryToTimeZoneId['Venezuela'] = 'America/Caracas';
        countryToTimeZoneId['Chile'] = 'America/Santiago';
        countryToTimeZoneId['Ecuador'] = 'America/Guayaquil';
        countryToTimeZoneId['Bolivia'] = 'America/La_Paz';
        countryToTimeZoneId['Paraguay'] = 'America/Asuncion';
        countryToTimeZoneId['Uruguay'] = 'America/Montevideo';
        countryToTimeZoneId['Suriname'] = 'America/Paramaribo';
        countryToTimeZoneId['Guyana'] = 'America/Guyana';
        countryToTimeZoneId['French Guiana'] = 'America/Cayenne';
        countryToTimeZoneId['Falkland Islands'] = 'Atlantic/Stanley';
        countryToTimeZoneId['Greenland'] = 'America/Godthab';
        countryToTimeZoneId['Bermuda'] = 'Atlantic/Bermuda';
        countryToTimeZoneId['Iceland'] = 'Atlantic/Reykjavik';
        countryToTimeZoneId['Ireland'] = 'Europe/Dublin';
        countryToTimeZoneId['United Kingdom'] = 'Europe/London';
        countryToTimeZoneId['Norway'] = 'Europe/Oslo';
        countryToTimeZoneId['Sweden'] = 'Europe/Stockholm';
        countryToTimeZoneId['Finland'] = 'Europe/Helsinki';
        countryToTimeZoneId['Denmark'] = 'Europe/Copenhagen';
        countryToTimeZoneId['Netherlands'] = 'Europe/Amsterdam';
        countryToTimeZoneId['Belgium'] = 'Europe/Brussels';
        countryToTimeZoneId['Luxembourg'] = 'Europe/Luxembourg';
        countryToTimeZoneId['France'] = 'Europe/Paris';
        countryToTimeZoneId['Spain'] = 'Europe/Madrid';
        countryToTimeZoneId['Portugal'] = 'Europe/Lisbon';
        countryToTimeZoneId['Germany'] = 'Europe/Berlin';
        countryToTimeZoneId['Switzerland'] = 'Europe/Zurich';
        countryToTimeZoneId['Italy'] = 'Europe/Rome';
        countryToTimeZoneId['Austria'] = 'Europe/Vienna';
        countryToTimeZoneId['Czech Republic'] = 'Europe/Prague';
        countryToTimeZoneId['Slovakia'] = 'Europe/Bratislava';
        countryToTimeZoneId['Hungary'] = 'Europe/Budapest';
        countryToTimeZoneId['Poland'] = 'Europe/Warsaw';
        countryToTimeZoneId['Lithuania'] = 'Europe/Vilnius';
        countryToTimeZoneId['Latvia'] = 'Europe/Riga';
        countryToTimeZoneId['Estonia'] = 'Europe/Tallinn';
        countryToTimeZoneId['Belarus'] = 'Europe/Minsk';
        countryToTimeZoneId['Ukraine'] = 'Europe/Kiev';
        countryToTimeZoneId['Moldova'] = 'Europe/Chisinau';
        countryToTimeZoneId['Romania'] = 'Europe/Bucharest';
        countryToTimeZoneId['Bulgaria'] = 'Europe/Sofia';
        countryToTimeZoneId['Greece'] = 'Europe/Athens';
        countryToTimeZoneId['Cyprus'] = 'Asia/Nicosia';
        countryToTimeZoneId['Turkey'] = 'Europe/Istanbul';
        countryToTimeZoneId['Russia'] = 'Europe/Moscow';
        countryToTimeZoneId['Kazakhstan'] = 'Asia/Almaty';
        countryToTimeZoneId['Uzbekistan'] = 'Asia/Tashkent';
        countryToTimeZoneId['Turkmenistan'] = 'Asia/Ashgabat';
        countryToTimeZoneId['Kyrgyzstan'] = 'Asia/Bishkek';
        countryToTimeZoneId['Tajikistan'] = 'Asia/Dushanbe';
        countryToTimeZoneId['Armenia'] = 'Asia/Yerevan';
        countryToTimeZoneId['Azerbaijan'] = 'Asia/Baku';
        countryToTimeZoneId['Georgia'] = 'Asia/Tbilisi';
        countryToTimeZoneId['Afghanistan'] = 'Asia/Kabul';
        countryToTimeZoneId['Pakistan'] = 'Asia/Karachi';
        countryToTimeZoneId['India'] = 'Asia/Kolkata';
        countryToTimeZoneId['Bangladesh'] = 'Asia/Dhaka';
        countryToTimeZoneId['Sri Lanka'] = 'Asia/Colombo';
        countryToTimeZoneId['Nepal'] = 'Asia/Kathmandu';
        countryToTimeZoneId['Bhutan'] = 'Asia/Thimphu';
        countryToTimeZoneId['Maldives'] = 'Indian/Maldives';
        countryToTimeZoneId['Iran'] = 'Asia/Tehran';
        countryToTimeZoneId['Iraq'] = 'Asia/Baghdad';
        countryToTimeZoneId['Kuwait'] = 'Asia/Kuwait';
        countryToTimeZoneId['Saudi Arabia'] = 'Asia/Riyadh';
        countryToTimeZoneId['Qatar'] = 'Asia/Qatar';
        countryToTimeZoneId['Bahrain'] = 'Asia/Bahrain';
        countryToTimeZoneId['United Arab Emirates'] = 'Asia/Dubai';
        countryToTimeZoneId['Oman'] = 'Asia/Muscat';
        countryToTimeZoneId['Yemen'] = 'Asia/Aden';
        countryToTimeZoneId['Jordan'] = 'Asia/Amman';
        countryToTimeZoneId['Israel'] = 'Asia/Jerusalem';
        countryToTimeZoneId['Lebanon'] = 'Asia/Beirut';
        countryToTimeZoneId['Syria'] = 'Asia/Damascus';
        countryToTimeZoneId['Palestine'] = 'Asia/Gaza';
        countryToTimeZoneId['Egypt'] = 'Africa/Cairo';
        countryToTimeZoneId['Libya'] = 'Africa/Tripoli';
        countryToTimeZoneId['Tunisia'] = 'Africa/Tunis';
        countryToTimeZoneId['Algeria'] = 'Africa/Algiers';
        countryToTimeZoneId['Morocco'] = 'Africa/Casablanca';
        countryToTimeZoneId['Western Sahara'] = 'Africa/El_Aaiun';
        countryToTimeZoneId['Mauritania'] = 'Africa/Nouakchott';
        countryToTimeZoneId['Mali'] = 'Africa/Bamako';
        countryToTimeZoneId['Niger'] = 'Africa/Niamey';
        countryToTimeZoneId['Chad'] = 'Africa/Ndjamena';
        countryToTimeZoneId['Sudan'] = 'Africa/Khartoum';
        countryToTimeZoneId['South Sudan'] = 'Africa/Juba';
        countryToTimeZoneId['Djibouti'] = 'Africa/Djibouti';
        countryToTimeZoneId['Somalia'] = 'Africa/Mogadishu';
        countryToTimeZoneId['Ethiopia'] = 'Africa/Addis_Ababa';
        countryToTimeZoneId['Eritrea'] = 'Africa/Asmara';
        countryToTimeZoneId['Kenya'] = 'Africa/Nairobi';
        countryToTimeZoneId['Uganda'] = 'Africa/Kampala';
        countryToTimeZoneId['Tanzania'] = 'Africa/Dar_es_Salaam';
        countryToTimeZoneId['Rwanda'] = 'Africa/Kigali';
        countryToTimeZoneId['Burundi'] = 'Africa/Bujumbura';
        countryToTimeZoneId['Seychelles'] = 'Indian/Mahe';
        countryToTimeZoneId['Comoros'] = 'Indian/Comoro';
        countryToTimeZoneId['Madagascar'] = 'Indian/Antananarivo';
        countryToTimeZoneId['Mauritius'] = 'Indian/Mauritius';
        countryToTimeZoneId['Reunion'] = 'Indian/Reunion';
        countryToTimeZoneId['Sri Lanka'] = 'Asia/Colombo';
        countryToTimeZoneId['Nepal'] = 'Asia/Kathmandu';

        cityToTimeZoneId['Atlanta'] = 'America/New_York';
        cityToTimeZoneId['Austin'] = 'America/Chicago';
        cityToTimeZoneId['Baltimore'] = 'America/New_York';
        cityToTimeZoneId['Boston'] = 'America/New_York';
        cityToTimeZoneId['Charlotte'] = 'America/New_York';
        cityToTimeZoneId['Cincinnati'] = 'America/New_York';
        cityToTimeZoneId['Cleveland'] = 'America/New_York';
        cityToTimeZoneId['Columbus'] = 'America/New_York';
        cityToTimeZoneId['Dallas'] = 'America/Chicago';
        cityToTimeZoneId['Denver'] = 'America/Denver';
        cityToTimeZoneId['Detroit'] = 'America/Detroit';
        cityToTimeZoneId['Houston'] = 'America/Chicago';
        cityToTimeZoneId['Indianapolis'] = 'America/Indiana/Indianapolis';
        cityToTimeZoneId['Jacksonville'] = 'America/New_York';
        cityToTimeZoneId['Kansas City'] = 'America/Chicago';
        cityToTimeZoneId['Las Vegas'] = 'America/Los_Angeles';
        cityToTimeZoneId['Los Angeles'] = 'America/Los_Angeles';
        cityToTimeZoneId['Memphis'] = 'America/Chicago';
        cityToTimeZoneId['Miami'] = 'America/New_York';
        cityToTimeZoneId['Milwaukee'] = 'America/Chicago';
        cityToTimeZoneId['Minneapolis'] = 'America/Chicago';
        cityToTimeZoneId['Nashville'] = 'America/Chicago';
        cityToTimeZoneId['New Orleans'] = 'America/Chicago';
        cityToTimeZoneId['Chicago'] = 'America/Chicago';
        cityToTimeZoneId['New York City'] = 'America/New_York';
        cityToTimeZoneId['Oklahoma City'] = 'America/Chicago';
        cityToTimeZoneId['Orlando'] = 'America/New_York';
        cityToTimeZoneId['Philadelphia'] = 'America/New_York';
        cityToTimeZoneId['Phoenix'] = 'America/Phoenix';
        cityToTimeZoneId['Pittsburgh'] = 'America/New_York';
        cityToTimeZoneId['Portland'] = 'America/Los_Angeles';
        cityToTimeZoneId['Raleigh'] = 'America/New_York';
        cityToTimeZoneId['Sacramento'] = 'America/Los_Angeles';
        cityToTimeZoneId['Salt Lake City'] = 'America/Denver';
        cityToTimeZoneId['San Antonio'] = 'America/Chicago';
        cityToTimeZoneId['San Diego'] = 'America/Los_Angeles';
        cityToTimeZoneId['San Francisco'] = 'America/Los_Angeles';
        cityToTimeZoneId['San Jose'] = 'America/Los_Angeles';
        cityToTimeZoneId['Seattle'] = 'America/Los_Angeles';
        cityToTimeZoneId['St. Louis'] = 'America/Chicago';
        cityToTimeZoneId['Tampa'] = 'America/New_York';
        cityToTimeZoneId['Tucson'] = 'America/Phoenix';
        cityToTimeZoneId['Virginia Beach'] = 'America/New_York';
        cityToTimeZoneId['Washington, D.C.'] = 'America/New_York';
        cityToTimeZoneId['Winnipeg'] = 'America/Winnipeg';
        cityToTimeZoneId['Vancouver'] = 'America/Vancouver';
        cityToTimeZoneId['Toronto'] = 'America/Toronto';
        cityToTimeZoneId['Montreal'] = 'America/Toronto';
        cityToTimeZoneId['Calgary'] = 'America/Edmonton';
        cityToTimeZoneId['Edmonton'] = 'America/Edmonton';
        cityToTimeZoneId['Ottawa'] = 'America/Toronto';
    }
    struct CarMockLocationData {
        string carCity;
        string carState;
        string carCountry;
        string timeZoneId;
        bool validity;
    }

    mapping(uint256 => CarMockLocationData) private carCoordinate;

    mapping(string => string) public countryToTimeZoneId;

    mapping(string => string) public cityToTimeZoneId;

    /// @dev Function: setCarCoordinateValidity
    /// @notice Sets the validity of car coordinates for a specific car ID.
    /// @param carId The ID of the car.
    /// @param validity The validity status to be set.
    function setCarCoordinateValidity(uint256 carId, bool validity) external {
        carCoordinate[carId].validity = validity;
    }

    /// @dev Function: setCarCity
    /// @notice Sets the city information for a specific car ID.
    /// @param carId The ID of the car.
    /// @param city The city information to be set.
    function setCarCity(uint256 carId, string memory city) external {
        carCoordinate[carId].carCity = city;
    }

    /// @dev Function: setCarState
    /// @notice Sets the state information for a specific car ID.
    /// @param carId The ID of the car.
    /// @param state The state information to be set.
    function setCarState(uint256 carId, string memory state) external {
        carCoordinate[carId].carState = state;
    }

    /// @dev Function: setCarCountry
    /// @notice Sets the country information for a specific car ID.
    /// @param carId The ID of the car.
    /// @param country The country information to be set.
    function setCarCountry(uint256 carId, string memory country) external {
        carCoordinate[carId].carCountry = country;
    }

    /// @dev Function: executeRequest
    /// @notice Executes a mock request. Mock implementation, you can add your own logic if needed.
    /// @param addr The address parameter for the mock request.
    /// @param carId The ID of the car.
    /// @return The car ID as bytes32 (mock response).
    function executeRequest(string memory addr, string memory, uint256 carId) external returns (bytes32) {
        string[] memory parts = RentalityUtils.splitString(addr, bytes(','));

        if (parts.length > 3) {
            string memory country = removeFirstSpaceIfExist(parts[parts.length - 1]);
            string memory state = removeFirstSpaceIfExist(parts[parts.length - 2]);
            string memory city = removeFirstSpaceIfExist(parts[parts.length - 3]);

            carCoordinate[carId].validity = true;
            carCoordinate[carId].carCity = removeFirstSpaceIfExist(city);
            carCoordinate[carId].carState = removeFirstSpaceIfExist(state);
            carCoordinate[carId].carCountry = removeFirstSpaceIfExist(country);

            if (bytes(cityToTimeZoneId[city]).length > 0) {
                carCoordinate[carId].timeZoneId = cityToTimeZoneId[city];
            } else if (bytes(countryToTimeZoneId[country]).length > 0) {
                carCoordinate[carId].timeZoneId = countryToTimeZoneId[country];
            }
            else {
                carCoordinate[carId].timeZoneId = 'America/New_York';
            }
        }

        return bytes32(carId);
    }

    /// @notice Removes the first space character if it exists at the beginning of the input string.
    /// @dev This function iterates through the input string and shifts all characters one position to the left,
    ///      effectively removing the first space character. It then adjusts the length of the string in memory accordingly.
    /// @param input The input string to be processed.
    /// @return The modified string with the first space character removed, if it exists.
    function removeFirstSpaceIfExist(string memory input) public pure returns (string memory) {
        bytes memory inputBytes = bytes(input);

        if (inputBytes.length > 0 && inputBytes[0] == ' ') {
            for (uint i = 0; i < inputBytes.length - 1; i++) {
                inputBytes[i] = inputBytes[i + 1];
            }

            // remove last char, because it duplicated
            assembly {
                mstore(inputBytes, sub(mload(inputBytes), 1))
            }
        }

        return string(inputBytes);
    }

    /// @notice Retrieves the validity of car coordinates for a specific car ID.
    /// @param carId The ID of the car.
    /// @return The validity status of car coordinates.
    function getCarCoordinateValidity(uint256 carId) external view returns (bool) {
        return carCoordinate[carId].validity;
    }

    /// @notice Retrieves the city information for a specific car ID.
    /// @param carId The ID of the car.
    /// @return The city information.
    function getCarCity(uint256 carId) external view returns (string memory) {
        return carCoordinate[carId].carCity;
    }

    /// @notice Retrieves the state information for a specific car ID.
    /// @param carId The ID of the car.
    /// @return The state information.
    function getCarState(uint256 carId) external view returns (string memory) {
        return carCoordinate[carId].carState;
    }

    /// @notice Retrieves the country information for a specific car ID.
    /// @param carId The ID of the car.
    /// @return The country information.
    function getCarCountry(uint256 carId) external view returns (string memory) {
        return carCoordinate[carId].carCountry;
    }

    /// @notice Retrieves the timezone information for a specific car ID.
    /// @param carId The ID of the car.
    /// @return The time zone id.
    function getCarTimeZoneId(uint256 carId) external view returns (string memory) {
        return carCoordinate[carId].timeZoneId;
    }

    /// @notice Retrieves all location info for a specific car ID.
    /// @param carId The ID of the car.
    /// @return The geo data info.
    function getCarMockData(uint256 carId) public view returns (CarMockLocationData memory) {
        return carCoordinate[carId];
    }
}
