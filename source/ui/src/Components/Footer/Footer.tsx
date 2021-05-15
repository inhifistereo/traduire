import React, { Component } from 'react';
import './Footer.css';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';

import 'bootstrap/dist/css/bootstrap.min.css';

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