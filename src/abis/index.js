import RentCarJSONNet from "./RentCar.json";
import RentCarJSONLocal from "./RentCar.localhost.json";

const rentCarJSON = (process.env.REACT_APP_USE_LOCALHOST_BLOCKCHAIN)?.toLowerCase?.() === "true"
? RentCarJSONLocal
: RentCarJSONNet;

export default rentCarJSON;