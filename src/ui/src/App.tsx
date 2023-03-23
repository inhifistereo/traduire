import React, { Component } from 'react';
import './App.css';
import FileSelector from './Components/FileSelector/FileSelector'
import Transcription from './Components/Transcription/Transcription';
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
		const uploadFileUri = config.UPLOAD_URI;
		const statusUri = config.STATUS_URI;
		const transcriptUri = config.TRANSCRIPT_URI;
		const webpubSubUri = config.WEB_PUBSUB_URI;
		const webpubSubKey = config.WEB_PUBSUB_KEY;
		
		return ( 
			<div>
				<Header />
				<FileSelector selectedFile={this.state.selectedFile} onFileSelected={this.handleFileSelection} />
				{selectedFile.name !== "foo.txt" && <Transcription selectedFile={this.state.selectedFile} 
														uploadFileUri={uploadFileUri} 
														statusUri={statusUri}
														transcriptUri={transcriptUri} 
														webpubSubUri={webpubSubUri}
														webpubSubKey={webpubSubKey} /> 
				}
				<Footer />
			</div>
  		);
  	}
}
export default App;
