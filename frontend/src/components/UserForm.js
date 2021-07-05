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
                    this.setState({...this.state, users: {...this.state.users, newUser: {...newUser, walletAddress: accounts[0]}}});
                    console.log('New User after connecting wallet : ', this.state.users.newUser);
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

    async createNewTrader(newTrader, traderId) {
        var row = {
          'id': traderId, 
          'Name': newTrader.name, 
          'Streaming Rate': newTrader.streamRatePerHour, 
          'Tokens Paid' : newTrader.tokenSwap==='DAI → ETH' ? '0 DAI' : '0 ETH', 
          'Fee Paid ($)': 0, 
          'Tokens Retrieved': newTrader.tokenSwap==='DAI → ETH' ? '0 ETH' : '0 DAI', 
        };
        await this.state.users.traders.push(row);
        console.log('Trader row pushed : ', this.state.traders);
    }

    async createNewLProvider(newLProvider, lProviderId) {
        var row = {
          'id': lProviderId,
          'Name': newLProvider.name,
          'DAI Stream Rate': newLProvider.DAIStreamRatePerSecond,
          'ETH Stream Rate': newLProvider.ETHStreamRatePerSecond,
          'DAI Earned': 0,
          'ETH Earned': 0,
          'Net Earning ($)': 0,
        };
        await this.state.rows.push(row);
        console.log('LProvider row pushed : ', this.state.rows);
    }

    addUser = (newUser) => {
        if (newUser.userType==='trader') {
            this.createNewTrader(newUser, this.state.users.traderCount+1);
            this.setState({...this.state, 
                users: {...this.state.users,
                    traderCount: this.state.users.traderCount+1,
                }
            });
            console.log('TRADERS : ', this.state.users.traderCount, this.state.users.traders);
        }
        else if (newUser.userType==='lProvider') {
            this.createNewLProvider(newUser, this.state.users.lProviderCount+1);
            this.setState({...this.state, 
                users: {...this.state.users,
                    lProviderCount: this.state.users.lProviderCount+1,
                }
            });
            console.log('LIQUIDITY PROVIDERS : ', this.state.users.lProviderCount, this.state.users.lProviders);
        }
    }

    handleCallback(newUser) {
        this.setState({...this.state, users: {...this.state.users, newUser: newUser}});
        console.log('CALLBACK in UserForm.js', this.state);
        this.connectWallet(newUser).then((res) => {
            if(res){
                this.addUser(this.state.users.newUser);
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
