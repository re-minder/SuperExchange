import React, {Component} from 'react';
import Table from "./Table";

export default class LProviders extends Component {

  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      rows: [
          { "id": 1, "Name": "John", "DAI Stream Rate": 0, "ETH Stream Rate": 0, "Fee Earned": 0},
          { "id": 1, "Name": "John", "DAI Stream Rate": 0, "ETH Stream Rate": 0, "Fee Earned": 0},
      ],
      header: ["id", "Name", "DAI Stream Rate", "ETH Stream Rate", "Fee Earned"],
      headerLength: 5,
    };
  }

  render() {
    return (
    <div className="rightComponent lProviders">
      <h1 style={{textAlign:'center'}}> Liquidity Providers </h1>
      <Table rows={this.state.rows} header={this.state.header} headerLength={this.state.headerLength}/>
      {this.state.lProviders.map(function(d, idx) {
          return (<li key={idx}>{d.name}</li>)}
      )}
    </div>
    );
  }
}
