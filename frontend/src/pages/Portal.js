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
      },
      // sf: undefined,
    }
    this.handleCallback = this.handleCallback.bind(this);
  }

  setState(state) {
    window.localStorage.setItem('state', JSON.stringify(state));
    super.setState(state);
  }

  // async initializeSuperFluid() {
  //   const SuperfluidSDK = require("@superfluid-finance/js-sdk");
  //   const Web3 = require("web3");

  //   const sf = new SuperfluidSDK.Framework({
  //       web3: new Web3(window.ethereum),
  //   });
  //   await sf.initialize();
  //   this.setState({sf});
  //   console.log("SuperFluid Initialized ", this.state.sf);
  // }

  handleCallback(users) {
    this.setState({users});
    console.log('CALLBACK in Portal.js', this.state.users);
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
