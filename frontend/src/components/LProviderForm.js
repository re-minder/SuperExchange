import React, {Component} from 'react';
import '../App.css';
import Web3 from 'web3';

const userTypes = [
    {
        label: 'Trader',
        value: 'trader',
    },
    {
        label: 'Liquidity Provider',
        value: 'lProvider',
    }
];

export default class LProviderForm extends Component {
    constructor(props) {
        super(props);
        this.state = {
            ...this.props,
            newUser: {
                userType: 'trader',
                name: 'Your Name',
                walletAddress: 'Your Wallet Address',
                streamRatePerHour: 'The rate at which you want to stream',
            }
        };
    }

    handleInputChange = event => {
        const { name, value } = event.target;
        this.setState({...this.setState, newUser: {...this.state.newUser, [name]: value}});
        console.log('NEW USERFORM STATE ON CHANGE: ', this.state);
    };

    handleSubmit = event => {
        event.preventDefault();
        console.log('HANDLING EVENT : ', event);
        console.log('NEW USERFORM STATE ON SUBMIT: ', this.state);
        this.addUser();
        this.connectWallet();
    };

    connectWallet = async () => {
        let web3
        if (window.ethereum) {
            web3 = new Web3(window.ethereum);
            try { 
               window.ethereum.request({ method: 'eth_requestAccounts' }).then(function() {
                   console.log('User has allowed account access to DApp...');
               });
            } catch(e) {
               console.error('User has denied account access to DApp...')
            }
         } else if(window.web3) {
             web3 = new Web3(window.web3.currentProvider);
         }
    }

    addUser = () => {
        if (this.state.newUser.userType==='trader') {
            var newTraders = this.state.users.traders;
            newTraders.push(this.state.newUser)
            this.setState({...this.state, users: {...this.state.users, traders: newTraders}})
            this.props.onChange(this.props.users);
            console.log('TRADERS : ', this.props.users.traders);
        } else if (this.state.newUser.userType==='lProvider') {
            var newLProviders = this.state.users.lProviders;
            newLProviders.push(this.state.newUser)
            this.setState({...this.state, users: {...this.state.users, lProviders: newLProviders}})
            this.props.onChange(this.props.users);
            console.log('LIQUIDITY PROVIDERS : ', this.props.users.lProviders);
        }
    }

    render() {
        return (
            <h1>This is LProviderForm</h1>
            // <form onSubmit={this.handleSubmit}>
            //     <input className='inputText' type='text' name='name' placeholder={this.state.newUser.name} onChange={this.handleInputChange} />
            //     <input className='inputText' type='text' name='walletAddress' placeholder={this.state.newUser.walletAddress} onChange={this.handleInputChange} />
            //     <input className='inputText' type='text' name='streamRatePerHour' placeholder={this.state.newUser.streamRatePerHour} onChange={this.handleInputChange} />
            //     <input className='submitButton' type='submit' value='Start Streaming' />
            // </form>
        );
    }
}
