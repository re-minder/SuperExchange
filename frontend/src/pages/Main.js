import React, { Component } from 'react';
import { Switch, Route } from 'react-router-dom';

import Home from './Home';
import Portal from './Portal';

export default class Main extends Component {
    render() {
        return (
        <Switch> {/* The Switch decides which component to show based on the current URL.*/}
            <Route exact path='/' component={Home}></Route>
            <Route exact path='/portal' component={Portal}></Route>
        </Switch>
        );
    }
}
