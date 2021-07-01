import React, {Component} from 'react';
import Table from './Table';

export default class Traders extends Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      rows: [
          {'id': 1, 'Name': 'John', 'Token Swapped': 'DAI -> ETH', 'Streaming Rate': 0, 'Tokens Paid' : 'x ETH', 'Fee Paid ($)': 0},
          {'id': 2, 'Name': 'Jane', 'Token Swapped': 'ETH -> DAI', 'Streaming Rate': 0, 'Tokens Paid' : 'y DAI', 'Fee Paid ($)': 0},
      ],
      header: ['id', 'Name', 'Token Swapped', 'Streaming Rate', 'Tokens Paid', 'Fee Paid ($)'],
      headerLength: 6,
    };
  }

  render() {
    return (
    <div className='leftComponent traders center'>
      <h1> Traders </h1>
      <Table name='traders' rows={this.state.rows} header={this.state.header} headerLength={this.state.headerLength}/>
    </div>
    );
  }
}
