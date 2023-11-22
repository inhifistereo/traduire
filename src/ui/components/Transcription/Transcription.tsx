import React, { Component } from 'react'
import 'bootstrap/dist/css/bootstrap.min.css'

import { WebPubSubServiceClient, AzureKeyCredential } from "@azure/web-pubsub"
//import { WebPubSubClient } from "@azure/web-pubsub-client";

import Button from 'react-bootstrap/Button'
import Container from 'react-bootstrap/Container'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import Alert from 'react-bootstrap/Alert'
import Card from 'react-bootstrap/Card'
import Stack from 'react-bootstrap/Stack'

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
	transcriptionMessage: string,
	transcriptionStatus: string,
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

var ws:WebSocket
class Transcription extends Component<Props,State> 
{
	serviceClient:WebPubSubServiceClient
	transcriptionId:string = ""
	hubName:string = "transcription"

	constructor(props:any) 
	{
		super(props);
		this.state = {
			isLoading: false,
			isReady: false,
			transcriptionStatus: "Pending Upload...",
			transcriptionMessage: "....",
		}
		this.serviceClient = new WebPubSubServiceClient(this.props.webpubSubUri, new AzureKeyCredential(this.props.webpubSubKey), this.hubName)
	}

	private configWebPubSubConnection = async ( ) => 
	{
		var token = await this.serviceClient.getClientAccessToken({ userId: this.transcriptionId })

		ws = new WebSocket(token.url);
		ws.onopen = () =>{ 
			this.setState({
				transcriptionStatus: `[${new Date()}]: Connected to PubSub as ${this.transcriptionId}. Waiting for Updates`
			})
		}
		
		ws.onmessage = (event:MessageEvent) => {
			let msg = JSON.parse(event.data)
			
			this.setState({
				transcriptionStatus: `[${new Date(msg.lastUpdated)}]: ${msg.statusMessage}`
			})

			if( msg.statusMessage === 'Completed' ) {
				this.setState({
					isReady: true
				})	
			}
		};
	}

	private replaceUri = (uri: string, id: string) => 
	{
		return uri.replace("{0}", id)
	}

	private getTranscription = async () =>
	{
	    var uri = this.replaceUri(this.props.transcriptUri, this.transcriptionId)
		
		const response = await fetch(uri)
		var body = await response.json().then(data => data as TranscriptionText)
		
		this.setState({ 
			transcriptionMessage: body.transcription
		})
	}

	private publishFile = async () => 
	{
		const formData = new FormData()
		formData.append('file', this.props.selectedFile)

		const response = await fetch(this.props.uploadFileUri, {
			method: 'POST',
			body:  formData
		});

		return response;
	}

  	private uploadFile = async () => 
	{
		this.setState({ isLoading: true })

		var response = await this.publishFile()
		var msg = await response.json().then(data => data as TranscriptionMessage)
		
		this.transcriptionId = msg.transcriptionId 
		this.setState({ 
			isLoading: false,
			isReady: false,
		})
		
		await this.configWebPubSubConnection()
  	}

  	render() 
	{
		const selectedFile = this.props.selectedFile
		const transcriptionMessage = this.state.transcriptionMessage
		const transcriptionStatus = this.state.transcriptionStatus
	
	  	return ( 
			<div>
				<Container>
					<Stack gap={2} direction="horizontal">
						<Button variant="primary" disabled={this.state.isLoading} onClick={this.uploadFile} >
							{this.state.isLoading ? 'Uploading ' + selectedFile.name  : 'Upload ' + selectedFile.name }
						</Button> 
						<Button variant="primary" disabled={!this.state.isReady} onClick={this.getTranscription}>
							Get Transcription
						</Button>
					</Stack>
					<hr/>
				</Container>
				<Container>
					<Row>
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
