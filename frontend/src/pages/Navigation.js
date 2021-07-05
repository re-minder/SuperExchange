import React, { Component } from 'react';
import { NavLink } from 'react-router-dom';

import SuperExchange_Logo from '../assets/SuperExchange_Logo_Circle.gif';
import '../App.css';

export default class Navigation extends Component {
    render() {
        return(
            <div className='header'>
                <img
                className='logo'
                alt='Logo'
                src={SuperExchange_Logo}
                ></img>
                <h1 className='appName'>SuperExchange</h1>         
                <nav className='homeNavigationBar'>
                    <ul>
                        <li><NavLink exact activeClassName='currentPage' to='/'>Home</NavLink></li>
                        <li><NavLink exact activeClassName='currentPage' to='/portal'>Portal</NavLink></li>
                    </ul>
                </nav>
            </div>
        )
    }
}
