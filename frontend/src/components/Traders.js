import React, {Component} from 'react';

export default class Traders extends Component {

  constructor(props) {
    super(props);
    this.state = {...this.props};
  }

  render() {
    return (
    <div className="Traders">
      <h1> Traders </h1>
      {this.state.traders.map(function(d, idx) {
          return (<li key={idx}>{d.name}</li>)}
      )}
    </div>
    );
  }
}
