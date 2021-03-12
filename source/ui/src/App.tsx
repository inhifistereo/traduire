import React, { Component } from 'react';
import './App.css';
import FileSelector from './Components/FileSelector/FileSelector'
import Uploader from './Components/Uploader/Uploader';

interface iApp {
	selectedFile: File
}

class App extends Component<any, iApp> {
	constructor(props:any) {
		super(props);
		this.handleFileSelection = this.handleFileSelection.bind(this);
		this.state = {
			selectedFile: new File(["foo"], "foo.txt", {type: "text/plain"}) 
		};
	}
	
	handleFileSelection(file:File) {
		this.setState({selectedFile:file});
	}
	
  	render() {
		const selectedFile = this.state.selectedFile;
		const uploadFileUri = process.env.REACT_APP_APP_URI ?? "http://localhost:3000/api/upload";
		
		return ( 
			<div>
				<FileSelector selectedFile={this.state.selectedFile} onFileSelected={this.handleFileSelection} />
				{selectedFile.name !== "foo.txt" && <Uploader selectedFile={this.state.selectedFile} uploadFileUri={uploadFileUri} /> }
			</div>
  		);
  	}
}
export default App;
