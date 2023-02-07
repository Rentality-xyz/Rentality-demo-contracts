import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';
import {
  BrowserRouter,
  Routes,
  Route,
} from "react-router-dom";
import SellNFT from './components/SellNFT';
import Marketplace from './components/Marketplace';
import NFTPage from './components/NFTpage';
import Profile from './components/Profile';
import SelectMode from './components/SelectMode';
import Host from './components/Host';
import AddCar from './components/AddCar';
import CarInfo from './components/CarInfo';
import Guest from './components/Guest';
import RentCar from './components/RentCar';
import RentCarInfo from './components/RentCarInfo';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        {/* <Route path="/" element={<Marketplace />}/>
        <Route path="/sellNFT" element={<SellNFT />}/> 
        <Route path="/nftPage/:tokenId" element={<NFTPage />}/>        
        <Route path="/profile" element={<Profile />}/>  */}
          
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
