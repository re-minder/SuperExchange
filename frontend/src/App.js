import React, {useState} from 'react';
import UserForm from './components/UserForm';
import Traders from './components/Traders';
import LProviders from './components/LProviders';

function App() {
  const [traders, setTraders] = useState([])
  const [lProviders, setLProviders] = useState([])

  function handleTradersCallback(newTraders) {
    setTraders(newTraders);
    console.log("CALLBACK in App.js", traders);
  }

  return (
    <div className="App">
      <h1>{traders}</h1>
      <UserForm traders={traders} onTradersChange={handleTradersCallback} lProviders={lProviders} onLProvidersChange={setLProviders}/>
      <Traders traders={traders} onTradersChange={setTraders} />
      <br/>
      <LProviders lProviders={lProviders} onLProvidersChange={setLProviders} />
    </div>
  );
} 

export default App;