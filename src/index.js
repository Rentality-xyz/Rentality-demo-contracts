import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import reportWebVitals from './reportWebVitals';
import {
  BrowserRouter,
  Routes,
  Route,
} from "react-router-dom";
import Profile from './pages/Profile';
import SelectMode from './pages/SelectMode';
import Host from './pages/host/Host';
import AddCar from './pages/host/AddCar';
import CarInfo from './pages/host/CarInfo';
import Guest from './pages/guest/Guest';
import RentCar from './pages/guest/RentCar';
import RentCarInfo from './pages/guest/RentCarInfo';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<SelectMode />}/>
        <Route path="/host" element={<Host />}/>
        <Route path="/addCar" element={<AddCar />}/>
        <Route path="/carInfo/:tokenId" element={<CarInfo />}/>
        <Route path="/guest" element={<Guest />}/>
        <Route path="/rentCar" element={<RentCar />}/>
        <Route path="/rentCarInfo/:tokenId" element={<RentCarInfo />}/>
        <Route path="/profile" element={<Profile />}/> 
      </Routes>
    </BrowserRouter>
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
