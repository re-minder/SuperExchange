import React, { Component } from 'react';

import SuperExchange_Logo from '../assets/SuperExchange_Logo_Circle.png';

import '../App.css';

export default class Home extends Component {
  render() {
    return (
      <div className="homePage">
        <img
            className='logoHomePage'
            alt='Logo'
            src={SuperExchange_Logo}
        />
        <h1 className='appName' style={{textAlign:'center'}}>Streaming Liquidity</h1>
      </div>
    )
  }
}
