import React, { Component } from 'react';
import './Uploader.css';
import Button from 'react-bootstrap/Button';
import 'bootstrap/dist/css/bootstrap.min.css';

type Props = {
	selectedFile: File,
	uploadFileUri: string
}

type State = {
	isLoading: boolean,
}

class Uploader extends Component<Props,State> {
	constructor(props:any) {
		super(props);
		this.state = {
			isLoading: false
		}
	}

	private uploadFileRequest = async () => {
		/*const response = await fetch(this.props.uploadFileUri, {
			method: 'POST',
			body: this.props.selectedFile
		});*/

		console.log(this.props.uploadFileUri);
		console.log(this.props.selectedFile);

		//return response;
		return new Promise((resolve) => setTimeout(resolve, 5000));
	}

  	private uploadFile = async () => {
	  this.setState({ isLoading: true })
	  try{
		await this.uploadFileRequest();
	  }
	  finally {
		this.setState({ isLoading: false })
	  }
  	}

  	render() {
		const selectedFile = this.props.selectedFile;
	  	return ( 
			<div>
				<Button variant="primary" disabled={this.state.isLoading} size="lg" block onClick={this.uploadFile} >
					{this.state.isLoading ? 'Uploading ' : 'Upload ' + selectedFile.name }
				</Button>
			</div>
  		);
  	}
}
export default Uploader;
