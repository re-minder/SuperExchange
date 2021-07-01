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
    }
    this.handleCallback = this.handleCallback.bind(this);
  }

  setState(state) {
    window.localStorage.setItem('state', JSON.stringify(state));
    super.setState(state);
  }

  handleCallback(newUsers) {
    this.setState({users: newUsers});
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
