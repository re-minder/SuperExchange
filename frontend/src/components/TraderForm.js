import React, {Component} from 'react';
import { Tab, Tabs } from 'react-bootstrap';

import '../App.css';

export default class TraderForm extends Component {
    constructor(props) {
        super(props);
        this.state = {
            ...this.props,
            newUser: {
                userType: 'trader',
                name: 'Your Name',
                streamRatePerHour: 'Stream Rate per Second',
                tokenSwap: 'DAI → ETH',
            }
        };
    }

    handleTabSelect = key => {
        console.log('HANDLING TAB EVENT : ', key);
        this.setState({...this.setState, newUser: {...this.state.newUser, tokenSwap: key}});
    }

    handleInputChange = event => {
        console.log('HANDLING CHANGE EVENT : ', event);
        const { name, value } = event.target;
        this.setState({...this.setState, newUser: {...this.state.newUser, [name]: value}});
        console.log('NEW USERFORM STATE ON CHANGE: ', this.state);
    };

    handleSubmit = event => {
        event.preventDefault();
        console.log('HANDLING SUBMTI EVENT : ', event);
        console.log('NEW USERFORM STATE ON SUBMIT: ', this.state);
        this.props.onSubmit(this.state.newUser);
    };

    render() {
        return (
            <form onSubmit={this.handleSubmit}>
                <input className='inputText' style={{textAlign:'center'}} type='text' name='name' placeholder={this.state.newUser.name} onChange={this.handleInputChange} />
                <Tabs 
                    defaultActiveKey='trader' transition={false} id='uncontrolled-tab-example' 
                    onSelect={(k) => this.handleTabSelect(k)}>
                    <Tab eventKey='DAI → ETH' title='DAI → ETH' unmountOnExit={true} />
                    <Tab eventKey='ETH → DAI' title='ETH → DAI' unmountOnExit={true} />
                </Tabs>
                <input className='inputText' style={{textAlign:'center'}} type='text' name='streamRatePerHour' placeholder={this.state.newUser.streamRatePerHour} onChange={this.handleInputChange} />
                <input className='submitButton' type='submit' value='Start Streaming' />
            </form>
        );
    }
}
