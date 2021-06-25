import React, {useState} from 'react';
import UserForm from './components/UserForm';
import Traders from './components/Traders';
// import LProviders from './components/LProviders';

function App() {
  const [traders, setTraders] = useState([])
  const [lProviders, setLProviders] = useState([])

  return (
    <div className="App">
      <UserForm traders={traders} onTradersChange={setTraders} lProviders={lProviders} onlProvidersChange={setLProviders}/>
      <Traders traders={traders} onTradersChange={setTraders}  lProviders={lProviders} onlProvidersChange={setLProviders}/>
      {/* <LProviders traders={traders} onTradersChange={setTraders}  lProviders={lProviders} onlProvidersChange={setLProviders}/> */}
    </div>
  );
} 

export default App;