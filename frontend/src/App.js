import React, { Component } from "react";
import UserForm from "./components/UserForm";
import Traders from "./components/Traders";
import LProviders from "./components/LProviders";
import LPool from "./components/LPool";

import SuperExchange_Logo from "./assets/SuperExchange_Logo_Circle.gif";

import "./App.css";

export default class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      users: {
        traders: [],
        lProviders: [],
      },
    };
    this.handleCallback = this.handleCallback.bind(this);
  }

  handleCallback(newUsers) {
    this.setState({ users: newUsers });
    console.log("CALLBACK in App.js", this.state.users);
  }

  render() {
    return (
      <div>
        <div className="header">
          <img
            className="logo"
            alt="Logo"
            src={SuperExchange_Logo}
          ></img>
          <h1 className="appName">SuperExchange</h1>
        </div>

        <div className="rowComp">
          <UserForm users={this.state.users} onChange={this.handleCallback} />
          <LPool />
        </div>

        <div className="rowComp" style={{ marginTop: "50px" }}>
          <Traders traders={this.state.users.traders} />
          <LProviders lProviders={this.state.users.lProviders} />
        </div>
      </div>
    );
  }
}
