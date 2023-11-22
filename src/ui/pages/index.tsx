import React, { useState } from "react"

import Head from 'next/head'
import { Inter } from 'next/font/google'
import 'bootstrap/dist/css/bootstrap.css';
import styles from '@/styles/Home.module.css'

import Header from '../components/Header/Header'
import FileSelector from '../components/FileSelector/FileSelector'
import Transcription from '../components/Transcription/Transcription'
import Footer from '../components/Footer/Footer'
import config from '../configs/config.json'

const inter = Inter({ subsets: ['latin'] })

export default function Home( { initialFile = new File([""], "file") }) {
  
  const [podcast, setPodcastFile] = useState(initialFile);

  const uploadFileUri = config.UPLOAD_URI;
  const statusUri     = config.STATUS_URI;
  const transcriptUri = config.TRANSCRIPT_URI;
  const webpubSubUri  = config.WEB_PUBSUB_URI;
  const webpubSubKey  = config.WEB_PUBSUB_KEY;

	function handleSelection(file:File) {
    setPodcastFile(file)
	}

  return (
    <>
      <Head>
        <title>Traduire</title>
        <meta name="description" content="Traduire - A podcast transcription service" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main className={`${styles.main} ${inter.className}`}>
        <Header />
        <FileSelector selectedFile={podcast} onFileSelected={handleSelection} />
        {podcast.name !== "file" && <Transcription selectedFile={podcast} 
						uploadFileUri={uploadFileUri} 
						statusUri={statusUri}
						transcriptUri={transcriptUri} 
						webpubSubUri={webpubSubUri}
						webpubSubKey={webpubSubKey} /> 
        }
        <Footer />
      </main>
    </>
  )
}

/*
				{/*<FileSelector selectedFile={this.state.selectedFile} onFileSelected={this.handleFileSelection} />
				{selectedFile.name !== "foo.txt" && <Transcription selectedFile={this.state.selectedFile} 
						uploadFileUri={uploadFileUri} 
						statusUri={statusUri}
						transcriptUri={transcriptUri} 
						webpubSubUri={webpubSubUri}
						webpubSubKey={webpubSubKey} /> 
				} 
*/