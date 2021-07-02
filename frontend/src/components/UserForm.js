import React, {Component} from 'react';
import { Tab, Tabs } from 'react-bootstrap';
import Web3 from 'web3';

import TraderForm from './TraderForm';
import LProviderForm from './LProviderForm';

import '../App.css';

export default class UserForm extends Component {
    constructor(props) {
        super(props);
        this.state = {
            ...this.props,
        };
        this.handleCallback = this.handleCallback.bind(this);
    }

    connectWallet = async () => {
        let web3
        if (window.ethereum) {
            web3 = new Web3(window.ethereum)
            try { 
               window.ethereum.request({ method: 'eth_requestAccounts' }).then(function() {
                   console.log('User has allowed account access to DApp...')
               });
            } catch(e) {
               console.error('User has denied account access to DApp...')
            }
         } else if(window.web3) {
             web3 = new Web3(window.web3.currentProvider)
         }
    }

    addUser = (newUser) => {
        this.connectWallet();
        if (newUser.userType==='trader') {
            var newTraders = this.state.users.traders
            newTraders.push(newUser)
            this.setState({...this.state, users: {...this.state.users, traders: newTraders}})
            console.log('TRADERS : ', this.props.users.traders);
        } else if (newUser.userType==='lProvider') {
            var newLProviders = this.state.users.lProviders;
            newLProviders.push(newUser)
            this.setState({...this.state, users: {...this.state.users, lProviders: newLProviders}})
            this.props.onChange(this.props.users);
            console.log('LIQUIDITY PROVIDERS : ', this.props.users.lProviders);
        }
    }

    handleCallback(newUser) {
        console.log('CALLBACK in UserForm.js', this.state.users);
        this.setState({newUser: newUser});
        this.addUser(newUser);
        this.props.onChange(this.state.users);
    }

    render() {
        return (
        <div className='leftComponent userInput'>
            <h1> Stream Liquidity </h1>
            <Tabs defaultActiveKey='trader' transition={false} id='uncontrolled-tab-example' onSelect={(key) => console.log(`HANDLING TAB EVENT : ${key} selected`)}>
                <Tab eventKey='trader' title='Trader' unmountOnExit={true}>
                    <TraderForm onSubmit={this.handleCallback}/>
                </Tab>
                <Tab eventKey='lProvider' title='Liquidity Provider' unmountOnExit={true}>
                    <LProviderForm onSubmit={this.handleCallback}/>
                </Tab>
            </Tabs>
        </div>
        );
    }
}
