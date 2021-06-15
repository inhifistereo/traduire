using System; 
using System.Collections.Generic;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Dapr;
using Dapr.Client;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Azure.Messaging.WebPubSub; 

using transcription.models;
using transcription.common;
using transcription.common.cognitiveservices;

namespace transcription.Controllers
{ 
    [ApiController]
    public class TranslationOnStarted : ControllerBase
    {
        private readonly WebPubSubServiceClient _serviceClient;
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
        }

        [Topic(Components.PubSubName, Topics.TranscriptionSubmittedTopicName)]
        [HttpPost("transcribe")]
        public async Task<ActionResult> Transcribe(TradiureTranscriptionRequest request,  CancellationToken cancellationToken)
        {         
            try
            {
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was successfullly received by Dapr PubSub");
                var state = await _client.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, request.TranscriptionId.ToString());
                state.Value ??= new TraduireTranscription();

                (Transcription response, HttpStatusCode code)  = await _cogsClient.SubmitTranscriptionRequestAsync(new Uri(request.BlobUri));

                _logger.LogInformation($"{request.TranscriptionId}. Call to COGS response code - {code.ToString()}");

                var eventdata = new TradiureTranscriptionRequest() { 
                    TranscriptionId = request.TranscriptionId, 
                    BlobUri = response.Self
                };

                await _serviceClient.serviceClient.SendToAllAsync(
                    new
                    { 
                        TranscriptionId = request.TranscriptionId,
                        StatusMessage = response.Status,
                        LastUpdated = state.Value.LastUpdateTime
                    }
                );

                if( code == HttpStatusCode.Created ) {
                    state.Value.LastUpdateTime          = DateTime.UtcNow;
                    state.Value.Status                  = TraduireTranscriptionStatus.SentToCognitiveServices;
                    state.Value.TranscriptionStatusUri  = response.Self;
                    
                    await state.SaveAsync();
                    await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionPendingTopicName, eventdata, cancellationToken );

                    _logger.LogInformation($"{request.TranscriptionId}. Event was successfullly publish to Azure Cognitive Services");
                    return Ok(request.TranscriptionId); 
                }
                else {
                    state.Value.LastUpdateTime          = DateTime.UtcNow;
                    state.Value.Status                  = TraduireTranscriptionStatus.Failed;
                    state.Value.StatusDetails           = code.ToString();
                    
                    await state.SaveAsync();
                    await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionFailedTopicName, eventdata, cancellationToken );

                    _logger.LogInformation($"{request.TranscriptionId}. Event Failed. Added to deadletter queue");
                    return BadRequest(request.TranscriptionId);  
                }
            }
            catch( Exception ex )  
            {
                _logger.LogWarning($"Failed to process {request.BlobUri} - {ex.Message}"); 
            }

            return BadRequest(); 
        }
    }
}