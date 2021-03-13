import React, { Component } from 'react';
import './FileSelector.css';
import Form from 'react-bootstrap/Form';
import 'bootstrap/dist/css/bootstrap.min.css';

interface iFileSelector {
	selectedFile: File,
}

class FileSelector extends Component<any,iFileSelector> {
	constructor(props:any) {
		super(props);
		this.handleChange = this.handleChange.bind(this);
	}

	handleChange = (event:any) => {
		this.props.onFileSelected(event.target.files[0]);
	};
  	
  	render() {
	  return ( 
		<div>
			<Form>
			  <Form.Group> 
			 	<Form.File 
			    	id="custom-file"
				    label="Select Podcast to Transcribe" 
					custom 
					onChange={this.handleChange}/>
			  </Form.Group>
			</Form>
		</div>
  	);
  }
}
export default FileSelector;
