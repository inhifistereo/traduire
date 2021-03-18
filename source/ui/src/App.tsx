import React, { Component } from 'react';
import './App.css';
import FileSelector from './Components/FileSelector/FileSelector'
import Uploader from './Components/Uploader/Uploader';
import Header from './Components/Header/Header';
import Footer from './Components/Footer/Footer';
import config from './config.json';

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
		const uploadFileUri = config.UPLOAD_URI ?? "http://localhost:3000/api/upload";
		
		return ( 
			<div>
				<Header />
				<FileSelector selectedFile={this.state.selectedFile} onFileSelected={this.handleFileSelection} />
				{selectedFile.name !== "foo.txt" && <Uploader selectedFile={this.state.selectedFile} uploadFileUri={uploadFileUri} /> }
				<Footer />
			</div>
  		);
  	}
}
export default App;
