import React, { Component } from 'react'
import Container from 'react-bootstrap/Container'
import Row from 'react-bootstrap/Row'

type Props = {
}

type State = {
	currentYear: number
}

class Footer extends Component<Props,State> {
	constructor(props:any) {
		super(props);
		this.state = {
			currentYear: (new Date()).getFullYear()
		}
	}

  	render() {
		const currentYear = this.state.currentYear;
	  	return ( 
			<Container>
				<hr />
  				<Row className="justify-content-md-center">
				  <small>&copy; Copyright {currentYear}</small>
				</Row>
			</Container>
  		);
  	}
}
export default Footer;