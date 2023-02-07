import './App.css';
import Profile from './components/Profile';
import SelectMode from './components/SelectMode';
import Host from './components/Host';
import AddCar from './components/AddCar';
import CarInfo from './components/CarInfo';
import Guest from './components/Guest';
import RentCar from './components/RentCar';
import RentCarInfo from './components/RentCarInfo';
import {
  Routes,
  Route,
} from "react-router-dom";

function App() {
  return (
    <div className="container">
        <Routes>
          <Route path="/" element={<SelectMode />}/>
          <Route path="/host" element={<Host />}/>
          <Route path="/addCar" element={<AddCar />}/>
          <Route path="/carInfo" element={<CarInfo />}/>
          <Route path="/guest" element={<Guest />}/>
          <Route path="/rentCar" element={<RentCar />}/>
          <Route path="/rentCarInfo" element={<RentCarInfo />}/>
          <Route path="/profile" element={<Profile />}/>  
        </Routes>
    </div>
  );
}

export default App;
