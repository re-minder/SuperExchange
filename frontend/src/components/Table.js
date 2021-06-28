import React, { Component } from 'react'

class Table extends Component {
    constructor(props) {
        super(props) //since we are extending class Table so we have to use super in order to override Component class constructor
        this.state = {
            ...this.props,
        };
    }

   renderTableData() {
        return this.state.rows.map((row, index) => {
            var rowArray = [];

            for (var i=1; i<this.state.headerLength; i++) {
                rowArray.push(<td>{row[this.state.header[i]]}</td>)
            }
            return (
                <tr key={row[this.state.header[0]]}>
                    {rowArray}
                </tr>
            )
        })
    }

    renderTableHeader() {
        let header = this.state.header.slice(1, this.state.headerLength);
        return header.map((key, index) => {
           return <th key={index}>{key}</th>
        })
     }
  
     render() {
        return (
           <div>
              <table id="table">
                 <tbody>
                    <tr>{this.renderTableHeader()}</tr>
                    {this.renderTableData()}
                 </tbody>
              </table>
           </div>
        )
     }
}

export default Table