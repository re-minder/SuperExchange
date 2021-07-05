import React, {Component} from 'react';
import Table from './Table';

export default class LProviders extends Component {

  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      header: ['id', 'Name', 'DAI Stream Rate', 'ETH Stream Rate', 'DAI Earned', 'ETH Earned', 'Net Earning ($)'],
      headerLength: 7,
    };
  }



  shouldComponentUpdate(nextState) {
    if(this.state.lProviderCount === nextState.lProviderCount-1) {
      const newLProvider = nextState.lProviders[nextState.lProviderCount-1];
      this.createNewLProvider(newLProvider, nextState.lProviderCount);
      return true;
    }
    return false;
  }

  render() {
    return (
    <div className='rightComponent lProviders'>
      <h1 className='sectionTitle'> Liquidity Providers </h1>
      <Table name='lProviders' rows={this.state.lProviders} header={this.state.header} headerLength={this.state.headerLength}/>
    </div>
    );
  }
}
