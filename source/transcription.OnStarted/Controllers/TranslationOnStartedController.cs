using System; 
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.WebUtilities;
using System.Text.Encodings.Web;
using Dapr;
using Dapr.Client;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text.Json.Serialization;

using transcription.models;
using transcription.common;
using transcription.common.cognitiveservices;

namespace transcription.onstarted.Controllers
{ 
    [ApiController]
    public class TranslationOnStarted : ControllerBase
    {
        private readonly ILogger _logger;
                
        public TranslationOnStarted(ILogger<TranslationOnStarted> logger)
        {
            _logger = logger;
        }

        [Topic(Components.PubSubName, Topics.TranscriptionSubmittedTopicName)]
        [HttpPost("transcribe")]
        public async Task<ActionResult> Transcribe(TradiureTranscriptionRequest request,  CancellationToken cancellationToken, [FromServices] DaprClient daprClient)
        {
            _logger.LogInformation($"REGION: {Environment.GetEnvironmentVariable("REGION", EnvironmentVariableTarget.Process)}");
            _logger.LogInformation($"KEY: {Environment.GetEnvironmentVariable("AZURE_COGS_KEY", EnvironmentVariableTarget.Process)}");
    
            try
            {
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was successfullly received by Dapr PubSub");
                var state = await daprClient.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, request.TranscriptionId.ToString());
                state.Value ??= new TraduireTranscription();

                AzureCognitiveServicesClient client = new AzureCognitiveServicesClient();
                (Transcription response, HttpStatusCode code)  = await client.SubmitTranscriptionRequestAsync(new Uri(request.BlobUri));

                _logger.LogInformation($"{request.TranscriptionId}. Call to COGS response code - {code.ToString()}");

                var eventdata = new TradiureTranscriptionRequest() { 
                    TranscriptionId = request.TranscriptionId, 
                    BlobUri = response.Self
                };

                if( code == HttpStatusCode.Created ) {
                    state.Value.LastUpdateTime          = DateTime.UtcNow;
                    state.Value.Status                  = TraduireTranscriptionStatus.SentToCognitiveServices;
                    state.Value.TranscriptionStatusUri  = response.Self;
                    
                    await state.SaveAsync();
                    await daprClient.PublishEventAsync(Components.PubSubName, Topics.TranscriptionPendingTopicName, eventdata, cancellationToken );

                    _logger.LogInformation($"{request.TranscriptionId}. Event was successfullly publish to Azure Cognitive Services");
                    return Ok(request.TranscriptionId); 
                }
                else {
                    state.Value.LastUpdateTime          = DateTime.UtcNow;
                    state.Value.Status                  = TraduireTranscriptionStatus.Failed;
                    state.Value.StatusDetails           = code.ToString();
                    
                    await state.SaveAsync();
                    await daprClient.PublishEventAsync(Components.PubSubName, Topics.TranscriptionFailedTopicName, eventdata, cancellationToken );

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