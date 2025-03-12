import '../Schemas.sol';

library RentalityQuery {

    function calculateGovSalesTaxes(bytes memory taxes) public view returns(uint64 totalTax, bytes memory data, string memory dataName) {
            (uint64 tripDays,
             uint64 value,
              bytes memory decodedTaxes)
               = abi.decode(taxes, (uint64, uint64, bytes));
               Schemas.GovermentSalesTaxes memory taxes = abi.decode(decodedTaxes,(Schemas.GovermentSalesTaxes) );
              Schemas.GovermentSalesTaxes memory tripTaxes = Schemas.GovermentSalesTaxes((value * taxes.salesTaxPPM) / 1_000_000, taxes.governmentTaxPerDayInUsdCents * tripDays);  

            return (
                tripTaxes.salesTaxPPM + tripTaxes.governmentTaxPerDayInUsdCents,
                abi.encode(tripTaxes),
                "GovermentSalesTaxes"
                );

    }
}