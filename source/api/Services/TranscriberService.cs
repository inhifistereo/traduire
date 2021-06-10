using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Grpc.Core;
using Microsoft.Extensions.Logging;
using Dapr.Client;

using transcription.models;
using transcription.api.dapr;

namespace traduire.webapi
{
    public class TranscriberService : Transcriber.TranscriberBase
    {
        private readonly ILogger<TranscriberService> _logger;
        private readonly DaprHelper _daprClient;
        public TranscriberService(ILogger<TranscriberService> logger)
        {
            _daprClient = new DaprHelper( new DaprClientBuilder().Build() );
            _logger = logger;
        }

        private TranscriptionReply TranscriptionReplyFactory(string id, string status, string uri, string createdTime, string transcription)
        {
            return new TranscriptionReply {
                TranscriptionId = id,
                CreateTime = createdTime,
                LastUpdateTime = DateTime.UtcNow.ToString(),
                Status = status,
                BlobUri = uri,
                TranscriptionText = transcription
            };
        }

        public override async Task TranscribeAudioStream(TranscriptionRequest request, IServerStreamWriter<TranscriptionReply> responseStream, ServerCallContext context)
        {
            var TranscriptionId = Guid.NewGuid(); 
            var createdTime = DateTime.UtcNow.ToString();

            _logger.LogInformation($"Transcription request was received.");
            try{

                var state = await _daprClient.UpdateState(TranscriptionId, request.BlobUri);
                _logger.LogInformation($"{TranscriptionId}. Record was successfullly saved as to {Components.StateStoreName} State Store");
                await responseStream.WriteAsync( TranscriptionReplyFactory(TranscriptionId.ToString(), TraduireTranscriptionStatus.Pending.ToString(), request.BlobUri, createdTime, string.Empty ));

                await _daprClient.PublishEvent( TranscriptionId, request.BlobUri, context.CancellationToken );
                _logger.LogInformation($"{TranscriptionId}. {request.BlobUri} was successfullly published to {Components.PubSubName} pubsub store");
                await responseStream.WriteAsync( TranscriptionReplyFactory(TranscriptionId.ToString(), TraduireTranscriptionStatus.SentToCognitiveServices.ToString(), request.BlobUri, createdTime, string.Empty ));

                TraduireTranscription currentState;
                do {
                    await Task.Delay(TimeSpan.FromSeconds(30));

                    currentState = await _daprClient.GetState(TranscriptionId);

                    _logger.LogInformation($"{TranscriptionId}. Transcription status is {currentState.Status}");
                    await responseStream.WriteAsync( TranscriptionReplyFactory(TranscriptionId.ToString(), currentState.Status.ToString(), request.BlobUri, createdTime, string.Empty ));

                } while( currentState.Status != TraduireTranscriptionStatus.Completed );

                _logger.LogInformation($"{TranscriptionId}. Attempting to download completed transcription"); 
                await responseStream.WriteAsync( TranscriptionReplyFactory(TranscriptionId.ToString(), TraduireTranscriptionStatus.Completed.ToString(), request.BlobUri, createdTime, currentState.TranscriptionText ));
            }
            catch( Exception ex ) 
            {
                _logger.LogWarning($"Failed to transcribe {request.BlobUri} - {ex.Message}");        
                await responseStream.WriteAsync( TranscriptionReplyFactory(TranscriptionId.ToString(), TraduireTranscriptionStatus.Failed.ToString(), request.BlobUri, createdTime, string.Empty ));            
            }
            
        }
    }
}