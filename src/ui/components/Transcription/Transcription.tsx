import React, { Component, useState } from 'react';

import { WebPubSubServiceClient, AzureKeyCredential } from "@azure/web-pubsub";

import Button from 'react-bootstrap/Button';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col';
import Alert from 'react-bootstrap/Alert';
import Card from 'react-bootstrap/Card';

type Props = {
	selectedFile: File,
	uploadFileUri: string,
	statusUri: string,
	transcriptUri: string,
	webpubSubUri: string,
	webpubSubKey: string,
}

type State = {
	isLoading: boolean,
	isReady: boolean,
	transcriptionId: string,
	transcriptionMessage: string,
	transcriptionStatus: string,
	serviceClient: WebPubSubServiceClient,
}

type TranscriptionText = {
	transcriptionId: string,
	statusMessage: number,
	transcription: string
}

type TranscriptionMessage = {
	transcriptionId: string,
	statusMessage: number,
	lastUpdated: string
}

var ws:WebSocket;
var hubName:string = "transcription";

class Transcription extends Component<Props,State> 
{
	constructor(props:any) 
	{
		super(props);
		this.state = {
			isLoading: false,
			isReady: false,
			transcriptionId: "",
			transcriptionStatus: "Pending Upload...",
			transcriptionMessage: "....",
			serviceClient: new WebPubSubServiceClient(this.props.webpubSubUri, new AzureKeyCredential(this.props.webpubSubKey), hubName)
		}

		this.configWSConnection = this.configWSConnection.bind(this);
	}

	private configWSConnection = async () => 
	{
		var userId = this.state.transcriptionId;
		var token = await this.state.serviceClient.getClientAccessToken({userId: userId});
		ws = new WebSocket(token.url);
		ws.onmessage = (event:MessageEvent) => {
			let msg = JSON.parse(event.data);
			this.setState({
				transcriptionStatus: `${msg.statusMessage} [${new Date(msg.lastUpdated)}]`
			})
		};
	}

	private replaceUri = (uri: string, id: string) => 
	{
		return uri.replace("{0}", id);
	}

	private updateState = (msg: TranscriptionMessage) => 
	{
		this.setState({
			transcriptionId: msg.transcriptionId,
		})
	}

	private checkStatus = async () => 
	{
		var uri = this.replaceUri(this.props.statusUri, this.state.transcriptionId);
		const response = await fetch(uri);
		var body = await response.json().then(data => data as TranscriptionMessage);

		if(body.statusMessage === 3) {
			await this.getTranscription();
		}
	}

	private getTranscription = async () =>
	{
		var uri = this.replaceUri(this.props.transcriptUri, this.state.transcriptionId);
		const response = await fetch(uri);
		var body = await response.json().then(data => data as TranscriptionText);
		this.setState({ 
			transcriptionMessage: body.transcription
		})
	}

	private uploadFileRequest = async () => {
		const formData = new FormData();
		formData.append('file', this.props.selectedFile);

		const response = await fetch(this.props.uploadFileUri, {
			method: 'POST',
			body:  formData
		});

		return response;
	}

  	private uploadFile = async () => {
	  this.setState({ isLoading: true })
	  try{
		var response = await this.uploadFileRequest();
		var body = await response.json().then(data => data as TranscriptionMessage);
		this.updateState(body);
	  }
	  finally {
		this.setState({ 
			isLoading: false,
			isReady: true
		})
		await this.configWSConnection();
	  }
  	}

  	render() {
		const selectedFile = this.props.selectedFile;
		const transcriptionMessage = this.state.transcriptionMessage;
		const transcriptionStatus = this.state.transcriptionStatus;
	
		console.log("Passed file was named: " + selectedFile)

	  	return ( 
			<div>
				<Container>
					<Row>
						<Col>
						<Button variant="primary" disabled={this.state.isLoading} size="lg" onClick={this.uploadFile} >
							{this.state.isLoading ? 'Uploading ' : 'Upload ' + selectedFile.name }
						</Button>
						</Col>
					</Row>
				</Container>
				<hr/>
				<Container>
					<Row>
						<Col><Button variant="secondary" size="lg" onClick={this.checkStatus}>Get Transcription</Button></Col>
						<Col><Alert variant="info">{transcriptionStatus}</Alert></Col>
					</Row>
					<Row>
						<Col><Card body>{transcriptionMessage}</Card></Col>
					</Row>
				</Container>

			</div>
  		);
  	}
}
export default Transcription;
