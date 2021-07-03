import React, {Component} from 'react';

import '../App.css';

export default class LProviderForm extends Component {
    constructor(props) {
        super(props);
        this.state = {
            ...this.props,
            newUser: {
                userType: 'lProvider',
                name: 'Your Name',
                DAIStreamRatePerSecond: 'DAI Stream Rate per Second',
                ETHStreamRatePerSecond: 'ETH Stream Rate per Second',
            }
        };
    }

    handleInputChange = event => {
        const {name, value} = event.target;
        this.setState({...this.setState, newUser: {...this.state.newUser, [name]: value}});
        console.log('NEW USER STATE ON CHANGE: ', this.state);
    };

    handleSubmit = event => {
        event.preventDefault();
        console.log('NEW USERFORM STATE ON SUBMIT: ', this.state);
        this.props.onSubmit(this.state.newUser);
    };

    render() {
        return (
            <form onSubmit={this.handleSubmit}>
                <input className='inputText' style={{textAlign:'center'}} type='text' name='name' placeholder={this.state.newUser.name} onChange={this.handleInputChange} />
                <input className='inputText' style={{textAlign:'center'}} type='text' name='DAIStreamRatePerSecond' placeholder={this.state.newUser.DAIStreamRatePerSecond} onChange={this.handleInputChange} />
                <input className='inputText' style={{textAlign:'center'}} type='text' name='ETHStreamRatePerSecond' placeholder={this.state.newUser.ETHStreamRatePerSecond} onChange={this.handleInputChange} />
                <input className='submitButton' type='submit' value='Start Streaming' />
            </form>
        );
    }
}
