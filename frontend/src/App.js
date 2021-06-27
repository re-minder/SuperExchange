import React, {Component} from 'react';
import UserForm from './components/UserForm';
import Traders from './components/Traders';
import LProviders from './components/LProviders';

import './App.css';

export default class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      users: {
        traders:[],
        lProviders:[]
      }
    }
    this.handleCallback = this.handleCallback.bind(this);
  }

  handleCallback(newUsers) {
    this.setState({users: newUsers});
    console.log("CALLBACK in App.js", this.state.users);
  }

  render() {
    return (
      <div>
        <div className="header">
          <img className="logo" alt="Logo" src="https://s3.us-west-2.amazonaws.com/secure.notion-static.com/636f5717-0184-4160-986f-1613a96e355c/SuperFluid_Animation_Linkedin_V10_Var_1_res_fix_%285%29.gif?X-Amz-Algorithm=AWS4-HMAC-SHA256&amp;X-Amz-Credential=AKIAT73L2G45O3KS52Y5%2F20210626%2Fus-west-2%2Fs3%2Faws4_request&amp;X-Amz-Date=20210626T152033Z&amp;X-Amz-Expires=86400&amp;X-Amz-Signature=ba31fcf53395d2a09fe659e03f21420de3729ed23f224bc536ac6ef87ef542e8&amp;X-Amz-SignedHeaders=host"></img>
          <h1 className="appName">Super Exchange</h1>
        </div>

        <div className="rowComp">
          <UserForm users={this.state.users} onChange={this.handleCallback}/>
          <div className="rightComponent liquidityPool"> 
            <h1>Liquidity Pool</h1>
          </div>
        </div>
        
        <br/>
        <div className="rowComp" style={{marginTop:"50px"}}>
          <Traders traders={this.state.users.traders} />
          <LProviders lProviders={this.state.users.lProviders}/>
        </div>
      </div>
    );
  }
} 
