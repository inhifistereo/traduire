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
    public class TranslationOnPending : ControllerBase
    {
        private readonly ILogger _logger;
                
        public TranslationOnPending(ILogger<TranslationOnPending> logger)
        {
            _logger = logger;
        }

        [Topic(Components.PubSubName, Topics.TranscriptionPendingTopicName)]
        [HttpPost("status")]
        public async Task<ActionResult> Transcribe(TradiureTranscriptionRequest request,  CancellationToken cancellationToken, [FromServices] DaprClient daprClient)
        {
            try
            {
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was successfullly received by Dapr PubSub");
                var state = await daprClient.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, request.TranscriptionId.ToString());
                state.Value ??= new TraduireTranscription();

                AzureCognitiveServicesClient client = new AzureCognitiveServicesClient();
                (Transcription response, HttpStatusCode code)  = await client.CheckTranscriptionRequestAsync(new Uri(request.BlobUri));

                state.Value.LastUpdateTime = DateTime.UtcNow;

                var eventdata = new TradiureTranscriptionRequest() { 
                    TranscriptionId = request.TranscriptionId,
                    BlobUri = response.Self
                };

                if( code == HttpStatusCode.OK  && (response.Status == "NotStarted" || response.Status == "Running" )) {
                    
                    Thread.Sleep(10000);

                    state.Value.Status                  = TraduireTranscriptionStatus.Pending;
                    state.Value.TranscriptionStatusUri  = response.Self;
                    await state.SaveAsync();
                    await daprClient.PublishEventAsync(Components.PubSubName, Topics.TranscriptionPendingTopicName, eventdata, cancellationToken );

                    _logger.LogInformation($"{request.TranscriptionId}. Azure Cognitive Services is still progressing request");
                    return Ok(request.TranscriptionId); 
                }
                
                if( code == HttpStatusCode.OK && response.Status == "Succeeded" ) {
                                        
                    state.Value.Status                  = TraduireTranscriptionStatus.Completed;
                    state.Value.TranscriptionStatusUri  = response.Links.Files;
                    await state.SaveAsync();

                    eventdata.BlobUri = response.Links.Files;
                    await daprClient.PublishEventAsync(Components.PubSubName, Topics.TranscriptionCompletedTopicName, eventdata, cancellationToken );

                    _logger.LogInformation($"{request.TranscriptionId}. Azure Cognitive Services has completed processing transcription");
                    return Ok(request.TranscriptionId);    
                }

                state.Value.Status                  = TraduireTranscriptionStatus.Failed;
                state.Value.StatusDetails           = code.ToString();
                await state.SaveAsync();
                await daprClient.PublishEventAsync(Components.PubSubName, Topics.TranscriptionFailedTopicName, eventdata, cancellationToken );

                _logger.LogInformation($"{request.TranscriptionId}. Event Failed. Added to deadletter queue");
                return BadRequest(request.TranscriptionId);  

            }
            catch( Exception ex )  
            {
                //Add Compensating tranasaction to undo error
                _logger.LogWarning($"Failed to process {request.BlobUri} - {ex.Message}"); 
            }

            return BadRequest(); 
        }
    }
}