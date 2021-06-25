import React from 'react';

const Traders = props => {

  return (
  <div>
    <h1> Traders </h1>
    {props.traders.map(function(d, idx) {
        return (<li key={idx}>{d.name}</li>)}
    )}
  </div>
  );
}

export default Traders;
