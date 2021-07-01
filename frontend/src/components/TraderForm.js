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
        this.props.onSubmit(this.state.newUser);
    };

    render() {
        return (
            <form onSubmit={this.handleSubmit}>
                <input className='inputText' style={{textAlign:'center'}} type='text' name='name' placeholder={this.state.newUser.name} onChange={this.handleInputChange} />
                <Tabs 
                    defaultActiveKey='trader' transition={false} id='uncontrolled-tab-example' 
                    onSelect={(index, label) => console.log(index + ' selected')}
                    style={{fontSize:'10px'}}>
                    <Tab eventKey='trader' title='DAI → ETH' unmountOnExit={true}>
                    </Tab>
                    <Tab eventKey='lProvider' title='ETH → DAI' unmountOnExit={true}>
                    </Tab>
                </Tabs>
                <input className='inputText' style={{textAlign:'center'}} type='text' name='streamRatePerHour' placeholder={this.state.newUser.streamRatePerHour} onChange={this.handleInputChange} />
                <input className='submitButton' type='submit' value='Start Streaming' />
            </form>
        );
    }
}
