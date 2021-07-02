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

    connectWallet = async (newUser) => {
        if (window.ethereum) {
            try {
                await window.ethereum.request({
                    method: 'eth_requestAccounts',
                    params: [
                      {
                        eth_accounts: {}
                      }
                    ]
                }).then((accounts) => {
                    console.log('Connected Wallets :', accounts);
                    this.setState({...this.state, newUser: {...this.state.newUser, walletAddress: accounts[0]}});
                    console.log('New User after connecting wallet : ', this.state.newUser);
                    console.log('User has allowed account access to dApp...');
                });
                window.web3 = new Web3(window.ethereum);
                return true;
            } catch(e) {
                console.error('User has denied account access to dApp...');
            }
        } else {
            alert("Please install MetaMask to use this dApp!");
        }
        return false;
    }

    addUser = (newUser) => {
        if (newUser.userType==='trader') {
            var newTraders = this.state.users.traders;
            newTraders.push(newUser);
            this.setState({...this.state, users: {...this.state.users, traders: newTraders}});
            console.log('TRADERS : ', this.props.users.traders);
        } else if (newUser.userType==='lProvider') {
            var newLProviders = this.state.users.lProviders;
            newLProviders.push(newUser);
            this.setState({...this.state, users: {...this.state.users, lProviders: newLProviders}});
            this.props.onChange(this.props.users);
            console.log('LIQUIDITY PROVIDERS : ', this.props.users.lProviders);
        }
    }

    handleCallback(newUser) {
        this.setState({newUser});
        console.log('CALLBACK in UserForm.js', this.state);
        this.connectWallet(newUser).then((res) => {
            if(res){
                this.addUser(this.state.newUser);
                this.props.onChange(this.state.users);
            }
        });
    }

    render() {
        return (
            <div className='leftComponent userInput'>
                <h1 className='sectionTitle'> Stream Liquidity </h1>
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
