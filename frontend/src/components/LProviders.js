import React, {Component} from 'react';
import Table from './Table';

export default class LProviders extends Component {

  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      rows: [
          {'id': 1, 'Name': 'John', 'DAI Stream Rate': 0, 'ETH Stream Rate': 0, 'DAI Earned': 0, 'ETH Earned': 0, 'Net Earning ($)': 0},
          {'id': 2, 'Name': 'John', 'DAI Stream Rate': 0, 'ETH Stream Rate': 0, 'DAI Earned': 0, 'ETH Earned': 0, 'Net Earning ($)': 0},
      ],
      header: ['id', 'Name', 'DAI Stream Rate', 'ETH Stream Rate', 'DAI Earned', 'ETH Earned', 'Net Earning ($)'],
      headerLength: 7,
    };
  }

  render() {
    return (
    <div className='rightComponent lProviders'>
      <h1 className='sectionTitle'> Liquidity Providers </h1>
      <Table name='lProviders' rows={this.state.rows} header={this.state.header} headerLength={this.state.headerLength}/>
      {this.state.lProviders.map(function(d, idx) {
          return (<li key={idx}>{d.name}, {d.walletAddress}</li>)}
      )}
    </div>
    );
  }
}
