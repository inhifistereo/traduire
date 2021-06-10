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
        private readonly int waitTime = 15;
        private readonly ILogger<TranscriberService> _logger;
        private readonly DaprHelper _daprClient;
        public TranscriberService(ILogger<TranscriberService> logger)
        {
            _daprClient = new DaprHelper( new DaprClientBuilder().Build() );
            _logger = logger;
        }

        public override async Task TranscribeAudioStream(TranscriptionRequest request, IServerStreamWriter<TranscriptionReply> responseStream, ServerCallContext context)
        {
            var TranscriptionId = Guid.NewGuid(); 
            var createdTime = DateTime.UtcNow.ToString();

            var reply = new TranscriptionReply {
                TranscriptionId = TranscriptionId.ToString(),
                CreateTime = DateTime.UtcNow.ToString(),
                LastUpdateTime = DateTime.UtcNow.ToString(),
                Status = TraduireTranscriptionStatus.Started.ToString(),
                BlobUri = request.BlobUri,
                TranscriptionText = string.Empty
            };

            _logger.LogInformation($"Transcription request was received.");
            try{

                var state = await _daprClient.UpdateState(TranscriptionId, request.BlobUri);
                _logger.LogInformation($"{TranscriptionId}. Transcription request was successfullly saved as to {Components.StateStoreName} State Store");
                await responseStream.WriteAsync(reply);

                await _daprClient.PublishEvent( TranscriptionId, request.BlobUri, context.CancellationToken );
                _logger.LogInformation($"{TranscriptionId}. {request.BlobUri} was successfullly published to {Components.PubSubName} pubsub store");
                reply.Status = TraduireTranscriptionStatus.SentToCognitiveServices.ToString();
                reply.LastUpdateTime = DateTime.UtcNow.ToString();
                await responseStream.WriteAsync(reply);

                TraduireTranscription currentState;
                do {
                    await Task.Delay(TimeSpan.FromSeconds(waitTime));

                    currentState = await _daprClient.GetState(TranscriptionId);

                    _logger.LogInformation($"{TranscriptionId}. Transcription status is {currentState.Status}");
                    reply.Status = currentState.Status.ToString();
                    reply.LastUpdateTime = DateTime.UtcNow.ToString();
                    await responseStream.WriteAsync(reply);

                } while( currentState.Status != TraduireTranscriptionStatus.Completed );

                _logger.LogInformation($"{TranscriptionId}. Attempting to download completed transcription");
                reply.TranscriptionText = currentState.TranscriptionText;
                await responseStream.WriteAsync(reply);
            }
            catch( Exception ex ) 
            {
                _logger.LogWarning($"Failed to transcribe {request.BlobUri} - {ex.Message}");
                reply.Status = TraduireTranscriptionStatus.Failed.ToString();
                reply.LastUpdateTime = DateTime.UtcNow.ToString();       
                await responseStream.WriteAsync(reply);            
            }
            
        }
    }
}