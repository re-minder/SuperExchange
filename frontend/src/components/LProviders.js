import React, {Component} from 'react';

export default class LProviders extends Component {

  constructor(props) {
    super(props);
    this.state = {...this.props};
  }

  render() {
    return (
    <div className="LProviders">
      <h1> Liquidity Providers </h1>
      {this.state.lProviders.map(function(d, idx) {
          return (<li key={idx}>{d.name}</li>)}
      )}
    </div>
    );
  }
}
