import React, {Component} from 'react';
import Table from "./Table";

export default class Traders extends Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      rows: [
          { "id": 1, "Name": "John", "Token Swapped": "DAI", "Streaming Rate": 0, "Fee Paid": 0},
          { "id": 2, "Name": "Jane", "Token Swapped": "ETH", "Streaming Rate": 0, "Fee Paid": 0},
      ],
      header: ["id", "Name", "Token Swapped", "Streaming Rate", "Fee Paid"],
      headerLength: 5,
    };
  }

  render() {
    return (
    <div className="leftComponent traders">
      <h1 style={{textAlign:'center'}}> Traders </h1>
      <Table rows={this.state.rows} header={this.state.header} headerLength={this.state.headerLength}/>
      {this.state.traders.map(function(d, idx) {
          return (<li key={idx}>{d.name}</li>)}
      )}
    </div>
    );
  }
}
