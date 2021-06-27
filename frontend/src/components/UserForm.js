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
                name: "name",
                walletAddress: "0x000000000000000000000000000000000000000",
                streamRatePerHour: 0,
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
                <label>
                UserType
                <div>
                    <select name="userType" value={userTypes.userType} onChange={this.handleInputChange}>
                        {userTypes.map((option) => (<option key={option.value} value={option.value}>{option.label}</option>))}
                    </select>
                </div>
                </label>

                <br/>
                <label>
                Name
                <input type="text" name="name" value={userTypes.name} onChange={this.handleInputChange} />
                </label>

                <br/>
                <label>
                Wallet Address
                <input type="text" name="walletAddress" value={userTypes.walletAddress} onChange={this.handleInputChange} />
                </label>

                <br/>
                <label>
                Streaming Rate Per Hour
                <input type="text" name="streamRatePerHour" value={userTypes.streamRatePerHour} onChange={this.handleInputChange} />
                </label>

                <br/>
                <input type="submit" value="Start Streaming" />
            </form>
        </div>
        );
    }
}
