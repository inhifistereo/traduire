import React, { Component, useEffect } from 'react'
import Form from 'react-bootstrap/Form';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';

interface iFileSelector {
	selectedFile: File,
}

class FileSelector extends Component<any,iFileSelector> {	

	constructor(props:any) {
		super(props)
	}

	handleChange = (event:any) => {
		this.props.onFileSelected(event.target.files[0]);
	};

	render() {
		return ( 
			<Container>
				<Row>
				<Form>
					<Form.Group> 
					<Form.Label>Select Podcast to Transcribe</Form.Label>
					<Form.Control 
						type="file"
						id="custom-file"
						onChange={this.handleChange}/>
					</Form.Group>
				</Form>
				</Row>
			</Container>
		)
	}
}

export default FileSelector
