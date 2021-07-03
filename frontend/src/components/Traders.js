import React, {Component} from 'react';
import Table from './Table';

export default class Traders extends Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      rows: [
          {'id': 1, 'Name': 'John', 'Streaming Rate': 0, 'Tokens Paid' : 'x ETH', 'Fee Paid ($)': 0, 'Tokens Retrieved': 'y DAI'},
          {'id': 2, 'Name': 'Jane', 'Streaming Rate': 0, 'Tokens Paid' : 'y DAI', 'Fee Paid ($)': 0, 'Tokens Retrieved': 'x ETH'},
      ],
      header: ['id', 'Name', 'Streaming Rate', 'Tokens Paid', 'Fee Paid ($)', 'Tokens Retrieved'],
      headerLength: 6,
    };
  }

  render() {
    return (
    <div className='leftComponent traders'>
      <h1 className='sectionTitle'> Traders </h1>
      <Table name='traders' rows={this.state.rows} header={this.state.header} headerLength={this.state.headerLength}/>
      {this.state.traders.map(function(d, idx) {
          console.log('Trader row', d);
          return (<li key={idx}>{d.name}, {d.walletAddress}</li>)}
      )}
    </div>
    );
  }
}
