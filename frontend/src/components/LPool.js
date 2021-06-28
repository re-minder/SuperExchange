import React, {Component} from 'react';
import Table from "./Table";

export default class LPool extends Component {

  constructor(props) {
    super(props);
    this.state = {
        ...this.props,
        rows: [
            { "id": 1, "FlowRate": "IN", "DAI": 0, "ETH": 0},
            { "id": 2, "FlowRate": "OUT", "DAI": 0, "ETH": 0},
        ],
        header: ["id", "FlowRate", "DAI", "ETH"],
        headerLength: 4,
    };
  }

  renderTableHeader = () => {
    let header = Object.keys(this.state.tokens);
    return header.map((key, index) => {
        return <th key={index}>{key}</th>
    });
  }

  render() {
    return (
    <div className="rightComponent lPool">
      <h1 style={{textAlign:'center'}}> Liquidity Pool </h1>
      <Table rows={this.state.rows} header={this.state.header} headerLength={this.state.headerLength}/>
      <h2> Net Fee collected - {this.state.fee}</h2>
    </div>
    );
  }
}
