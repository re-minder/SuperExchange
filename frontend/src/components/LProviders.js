import React from 'react';

const LProviders = props => {

  return (
  <div className="LProviders">
    <h1> Liquidity Providers </h1>
    {props.lProviders.map(function(d, idx) {
        return (<li key={idx}>{d.name}</li>)}
    )}
  </div>
  );
}

export default LProviders;
