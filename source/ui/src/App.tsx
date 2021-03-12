import React, { Component } from 'react';
import './App.css';
import FileSelector from './FileSelector'
import Uploader from './Uploader';

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
		return ( 
			<div>
				<FileSelector selectedFile={this.state.selectedFile} onFileSelected={this.handleFileSelection} />
				{selectedFile.name === "foo.txt" ?
					<Uploader selectedFile={this.state.selectedFile} show={false} />
				: <Uploader selectedFile={this.state.selectedFile} show={true} /> }
			</div>
  		);
  	}
}
export default App;
