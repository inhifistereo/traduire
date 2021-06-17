using System; 
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Dapr;
using Dapr.Client;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Mvc;
using Azure.Messaging.WebPubSub; 
using Azure.Core;

using transcription.models;
using transcription.common;
using transcription.common.cognitiveservices;

namespace transcription.Controllers
{ 
    [ApiController]
    public class TranslationOnStarted : ControllerBase
    {
        private StateEntry<TraduireTranscription> state;
        private readonly TraduireNotificationService _serviceClient;
        private readonly IConfiguration _configuration;
        private readonly DaprClient _client;
        private readonly AzureCognitiveServicesClient _cogsClient; 
        private readonly ILogger _logger;
                
        public TranslationOnStarted(ILogger<TranslationOnStarted> logger, IConfiguration configuration, DaprClient Client, AzureCognitiveServicesClient CogsClient, WebPubSubServiceClient ServiceClient)
        {
            _client = Client;
            _logger = logger;
            _configuration = configuration;
            _cogsClient = CogsClient;
			_serviceClient = new TraduireNotificationService(ServiceClient);
        }

        [Topic(Components.PubSubName, Topics.TranscriptionSubmittedTopicName)]
        [HttpPost("transcribe")]
        public async Task<ActionResult> Transcribe(TradiureTranscriptionRequest request,  CancellationToken cancellationToken)
        {         
            try
            {
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was successfullly received by Dapr PubSub");
                state = await _client.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, request.TranscriptionId.ToString());
                state.Value ??= new TraduireTranscription();

                (Transcription response, HttpStatusCode code)  = await _cogsClient.SubmitTranscriptionRequestAsync(new Uri(request.BlobUri));

                await _serviceClient.PublishNotification(request.TranscriptionId.ToString(), response.Status);

                if( code == HttpStatusCode.Created ) {
                    _logger.LogInformation($"{request.TranscriptionId}. Event was successfullly publish to Azure Cognitive Services");
                    var createdEvent = await UpdateStateRepository(TraduireTranscriptionStatus.SentToCognitiveServices, code, response.Self);
                    await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionPendingTopicName, createdEvent, cancellationToken );
                    return Ok(request.TranscriptionId); 
                }
                
                _logger.LogInformation($"{request.TranscriptionId}. Transcription Failed for an unexpected reason. Added to Failed Queue for review");
                var failedEvent = await UpdateStateRepository(TraduireTranscriptionStatus.Failed, code, response.Self);
                await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionFailedTopicName, failedEvent, cancellationToken);

            }
            catch( Exception ex )  
            {
                _logger.LogWarning($"Nuts. Something really bad happened processing {request.BlobUri} - {ex.Message}"); 
            }

            return BadRequest(); 
        }

        private async Task<TradiureTranscriptionRequest> UpdateStateRepository(TraduireTranscriptionStatus status, HttpStatusCode code, string uri)
        {
            state.Value.LastUpdateTime = DateTime.UtcNow;
            state.Value.Status = status;
            state.Value.StatusDetails = code.ToString();
            state.Value.TranscriptionStatusUri = uri;
            await state.SaveAsync();

            return new TradiureTranscriptionRequest() {
                TranscriptionId = state.Value.TranscriptionId,
                BlobUri = uri
            };
        }
    }
}
