import React, { Component } from 'react';
import './Uploader.css';
import Button from 'react-bootstrap/Button';
import 'bootstrap/dist/css/bootstrap.min.css';

type Props = {
	selectedFile: File,
	show: boolean
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

	private simulateNetworkRequest = async () => {
  		return new Promise((resolve) => setTimeout(resolve, 5000));
  	};

  	private uploadFile = async () => {
	  this.setState({ isLoading: true })
	  try{
		await this.simulateNetworkRequest();
	  }
	  finally {
		this.setState({ isLoading: false })
	  }
  	}

  	render() {
		const selectedFile = this.props.selectedFile;
	  	return ( 
			<div>
				{this.props.show ?
					<div>
						<Button variant="primary" disabled={this.state.isLoading} size="lg" block onClick={this.uploadFile} >
							{this.state.isLoading ? 'Uploading ' : 'Upload ' + selectedFile.name }
						</Button>
					</div>
				: null }
			</div>
  		);
  	}
}
export default Uploader;
