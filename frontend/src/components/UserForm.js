import React, {useState} from 'react';

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

const UserForm =  props => {
 
    let initialFormState = {
        userType: "trader",
        name: "name",
        walletAddress: "0x000000000000000000000000000000000000000",
        streamRatePerHour: 0,
    };

    const [formState, setFormState] = useState(initialFormState);

    const handleInputChange = event => {
        const { name, value } = event.target;
        setFormState({...formState, [name]: value});
    };

    const handleSubmit = event => {
        event.preventDefault();
        console.log(event);
        console.log(formState);
        addUser(formState);
    };

    const addUser = (formState) => {
        if (formState.userType==="trader") {
            props.traders.push(formState);
            props.onTradersChange(props.traders);
            console.log("Formstate: ", formState);
            console.log("Traders: ", props.traders);
        } else if (formState.userType==="lProvider") {
            props.traders.push(formState);
            props.onTradersChange(props.traders);
            console.log("Formstate: ", formState);
            console.log("Traders: ", props.traders);
        }
    }

    return (
    <div className="submit-form">
        <h1> Add New User </h1>
        <form onSubmit={handleSubmit}>
            <label>
            UserType
            <div className="select-container">
                <select name="userType" value={userTypes.userType} onChange={handleInputChange}>
                    {userTypes.map((option) => (<option key={option.value} value={option.value}>{option.label}</option>))}
                </select>
            </div>
            </label>

            <br/>
            <label>
            Name
            <input type="text" name="name" value={userTypes.name} onChange={handleInputChange} />
            </label>

            <br/>
            <label>
            Wallet Address
            <input type="text" name="walletAddress" value={userTypes.walletAddress} onChange={handleInputChange} />
            </label>

            <br/>
            <label>
            Streaming Rate Per Hour
            <input type="text" name="streamRatePerHour" value={userTypes.streamRatePerHour} onChange={handleInputChange} />
            </label>

            <br/>
            <input type="submit" value="Submit" />
        </form>
    </div>
    );
}

export default UserForm;
