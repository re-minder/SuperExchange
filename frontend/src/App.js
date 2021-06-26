import React, {Component} from 'react';
import UserForm from './components/UserForm';
import Traders from './components/Traders';
import LProviders from './components/LProviders';

export default class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
        traders:[],
        lProviders:[]
    }
    this.handleCallback = this.handleCallback.bind(this);
  }

  handleCallback(newUsers) {
    this.setState({users: newUsers});
    console.log("CALLBACK in App.js", this.state.users);
  }

  render() {
    return (
      <div className="App">
        <UserForm users={this.state} onChange={this.handleCallback}/>
        <Traders traders={this.state.traders} />
        <br/>
        <LProviders lProviders={this.state.lProviders}/>
      </div>
    );
  }
} 
