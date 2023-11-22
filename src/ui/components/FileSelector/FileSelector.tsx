import React, { Component, useEffect } from 'react'
import Form from 'react-bootstrap/Form';
import Container from 'react-bootstrap/Container';
import Stack from 'react-bootstrap/Stack';

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
			<div>
				<Container>
					<Stack gap={15}>
					<Form>
						<Form.Group> 
						<Form.Label>Select Podcast to Transcribe</Form.Label>
						<Form.Control 
							type="file"
							id="custom-file"
							onChange={this.handleChange}/>
						</Form.Group>
					</Form>
					</Stack>
				</Container>
			</div>
		)
	}
}

export default FileSelector
