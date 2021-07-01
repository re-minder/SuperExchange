import React, { Component } from 'react';

import Navigation from './pages/Navigation';
import Main from './pages/Main';

import './App.css';

export default class App extends Component {
  render() {
    return (
      <div className='app'>
        <Navigation />
        <Main />
      </div>
    );
  }
}
