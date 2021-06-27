import React, {Component} from 'react';
import '../App.css';

const userTypes = [
    {
        label: "Trader",
        value: "trader",
    },
    {
        label: "Liquidity Provider",
        value: "lProvider",
    }
];

export default class UserForm extends Component {
    constructor(props) {
        super(props);
        this.state = {
            ...this.props,
            newUser: {
                userType: "trader",
                name: "Your Name",
                walletAddress: "Your Wallet Addres",
                streamRatePerHour: "The rate at which you want to stream",
            }
        };
    }

    handleInputChange = event => {
        const { name, value } = event.target;
        this.setState({...this.setState, newUser: {...this.state.newUser, [name]: value}});
        console.log("NEW USERFORM STATE ON CHANGE: ", this.state);
    };

    handleSubmit = event => {
        event.preventDefault();
        console.log("HANDLING EVENT : ", event);
        console.log("NEW USERFORM STATE ON SUBMIT: ", this.state);
        this.addUser();
    };

    addUser = () => {
        if (this.state.newUser.userType==="trader") {
            var newTraders = this.state.users.traders;
            newTraders.push(this.state.newUser)
            this.setState({...this.state, users: {...this.state.users, traders: newTraders}})
            this.props.onChange(this.props.users);
            console.log("TRADERS : ", this.props.users.traders);
        } else if (this.state.newUser.userType==="lProvider") {
            var newLProviders = this.state.users.lProviders;
            newLProviders.push(this.state.newUser)
            this.setState({...this.state, users: {...this.state.users, lProviders: newLProviders}})
            this.props.onChange(this.props.users);
            console.log("LIQUIDITY PROVIDERS : ", this.props.users.lProviders);
        }
    }

    render() {
        return (
        <div className="leftComponent userInput">
            <h1> Stream Liquidity </h1>
            <form onSubmit={this.handleSubmit}>
                <select className="inputDropDown" name="userType" value={userTypes.userType} onChange={this.handleInputChange}>
                    {userTypes.map((option) => (<option key={option.value} value={option.value}>{option.label}</option>))}
                </select>
                <input className="inputText" type="text" name="name" placeholder={this.state.newUser.name} onChange={this.handleInputChange} />
                <input className="inputText" type="text" name="walletAddress" placeholder={this.state.newUser.walletAddress} onChange={this.handleInputChange} />
                <input className="inputText" type="text" name="streamRatePerHour" placeholder={this.state.newUser.streamRatePerHour} onChange={this.handleInputChange} />
                <input className="submitButton" type="submit" value="Start Streaming" />
            </form>
        </div>
        );
    }
}
