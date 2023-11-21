import React, { Component } from 'react';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';

type Props = {
}

type State = {
}

class Header extends Component<Props,State> {
  	render() {
	  	return ( 
			<Container>
  				<Row className="justify-content-md-left">
					<h1>Tradiure</h1>
				</Row>
				<Row className="justify-content-md-left">
					<em>A podcast transcription site</em>
				</Row>
				<hr/>
			</Container>
  		);
  	}
}
export default Header;