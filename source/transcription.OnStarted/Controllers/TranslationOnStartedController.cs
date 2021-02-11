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
        public async Task<ActionResult> Transcribe(TranscriptionRequest request, [FromServices] DaprClient daprClient)
        {
            try
            {
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was successfullly received by Dapr PubSub");
                var state = await daprClient.GetStateEntryAsync<Transcription>(Components.StateStoreName, request.TranscriptionId.ToString());
            
                _logger.LogInformation($"{request.TranscriptionId}. Event was successfullly publish to Azure Cognitive Services");
                return Ok(request.TranscriptionId); 
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