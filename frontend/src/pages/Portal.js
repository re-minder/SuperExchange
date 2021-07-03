import React, { Component } from 'react';

import UserForm from '../components/UserForm';
import Traders from '../components/Traders';
import LProviders from '../components/LProviders';
import LPool from '../components/LPool';

import '../App.css';

export default class Portal extends Component {
  constructor() {
    super();
    this.state = JSON.parse(window.localStorage.getItem('state')) || {
      users: {
        traders: [],
        lProviders: [],
      }
    };
    console.log('this.state in CONSTRUCTOR in Portal.js : ', this.state);
    this.handleCallback = this.handleCallback.bind(this);
  }

  componentDidMount() {
    try {
      this.initializeSuperFluid().then(sf => {
        console.log('SUPERFLUID INITIALIZED sf ', sf);
        var Flatted = require('flatted');
        this.setState({...this.state, sf: Flatted.stringify(sf)});
        // console.log('SUPERFLUID INITIALIZED this.state.sf ', this.state.sf);
      });
    } catch (error) {
      alert('Unable to initialize SUPERFLUID');
      console.error(error);
    }
  }

  setState(state) {
    window.localStorage.setItem('state', JSON.stringify(state));
    super.setState(state);
  }

  async initializeSuperFluid() {
    console.log('INITIALIZING SUPERFLUID in Portal.js');
    const SuperfluidSDK = require('@superfluid-finance/js-sdk');
    const Web3 = require('web3');

    const sf = new SuperfluidSDK.Framework({
        web3: new Web3(window.ethereum),
    });
    await sf.initialize();
    return sf;
  }

  handleCallback(users) {
    this.setState({...this.state, users: users});
    console.log('CALLBACK in Portal.js', this.state.users);

    var Flatted = require('flatted');
    const sf = Flatted.parse(this.state.sf);
    console.log('SUPERFLUID UNFLATTENED sf ', sf);
    // // const user = sf.user({
    // //   address: walletAddress[0],
    // //   token: '0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00'
    // // });
  }

  render() {
    return (
      <div>
        <div className='rowComp'>
          <UserForm users={this.state.users} onChange={this.handleCallback} />
          <LPool />
        </div>
        <br/>
        <div className='rowComp'>
          <Traders traders={this.state.users.traders} />
          <LProviders lProviders={this.state.users.lProviders} />
        </div>
      </div>
    );
  }
}
