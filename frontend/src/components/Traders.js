import React, {Component} from 'react';
import Table from './Table';

export default class Traders extends Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      header: ['id', 'Name', 'Streaming Rate', 'Tokens Paid', 'Fee Paid ($)', 'Tokens Retrieved'],
      headerLength: 6,
    };
  }

  render() {
    return (
    <div className='leftComponent traders'>
      <h1 className='sectionTitle'> Traders </h1>
      <Table name='traders' rows={this.state.traders} header={this.state.header} headerLength={this.state.headerLength}/>
    </div>
    );
  }
}
