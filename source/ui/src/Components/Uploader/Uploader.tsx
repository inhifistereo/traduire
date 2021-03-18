import React, { Component } from 'react';
import './Uploader.css';
import 'bootstrap/dist/css/bootstrap.min.css';

import Button from 'react-bootstrap/Button';
import Toast from 'react-bootstrap/Toast';

type Props = {
	selectedFile: File,
	uploadFileUri: string
}

type State = {
	isLoading: boolean,
	showToast: boolean,
	toastBody: string
}

class Uploader extends Component<Props,State> {
	constructor(props:any) {
		super(props);
		this.state = {
			isLoading: false,
			showToast: false,
			toastBody: ""
		}
	}

	private setToastState(isShowing:boolean, msg: string = ""){
		this.setState({
			showToast: isShowing,
			toastBody: msg
		})
	}

	private uploadFileRequest = async () => {
		const response = await fetch(this.props.uploadFileUri, {
			method: 'POST',
			body: this.props.selectedFile,
			headers: {
				'Content-Type': "multipart/form-data"
			}
		});
		return response;
	}

  	private uploadFile = async () => {
	  this.setState({ isLoading: true })
	  try{
		var response = await this.uploadFileRequest();
		var msg = this.props.selectedFile.name + " upload status - " + response.status + ": " + response.statusText;
		this.setToastState(true, msg);
	  }
	  finally {
		this.setState({ isLoading: false })
	  }
  	}

  	render() {
		const selectedFile = this.props.selectedFile;
		const showToast = this.state.showToast;
		const toastBody = this.state.toastBody;

	  	return ( 
			<div>
				<Button variant="primary" disabled={this.state.isLoading} size="lg" block onClick={this.uploadFile} >
					{this.state.isLoading ? 'Uploading ' : 'Upload ' + selectedFile.name }
				</Button>
				<div style={{position: 'absolute', bottom: 0, right: 0}} >
					<Toast onClose={() => this.setToastState(false)} show={showToast} delay={3000} autohide >
						<Toast.Header>
							<strong className="mr-auto">Upload Status</strong>
						</Toast.Header>
						<Toast.Body>{toastBody}</Toast.Body>
					</Toast>
				</div>
			</div>
  		);
  	}
}
export default Uploader;
