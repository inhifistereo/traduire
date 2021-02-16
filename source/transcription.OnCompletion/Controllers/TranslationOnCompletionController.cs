using System; 
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Dapr;
using Dapr.Client;
using Microsoft.Extensions.Logging;

using transcription.models;
using transcription.common;
using transcription.common.cognitiveservices;

namespace transcription.onstarted.Controllers
{ 
    [ApiController]
    public class TranslationOnCompletion : ControllerBase
    {
        private readonly ILogger _logger;
                
        public TranslationOnCompletion(ILogger<TranslationOnCompletion> logger)
        {
            _logger = logger;
        }

        [Topic(Components.PubSubName, Topics.TranscriptionSubmittedTopicName)]
        [HttpPost("transcribe")]
        public async Task<ActionResult> Transcribe(TradiureTranscriptionRequest request,  CancellationToken cancellationToken, [FromServices] DaprClient daprClient)
        {
            try
            {
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was successfullly received by Dapr PubSub");
                var state = await daprClient.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, request.TranscriptionId.ToString());

                AzureCognitiveServicesClient client = new AzureCognitiveServicesClient();
                (TranscriptionResults result, HttpStatusCode code)  = await client.DownloadTranscriptionResultAsync(new Uri(request.BlobUri)); 

                if( code == HttpStatusCode.OK ) {                  
                    var firstChannel                = result.CombinedRecognizedPhrases.FirstOrDefault();
                    state.Value.Status              = TraduireTranscriptionStatus.Completed;
                    state.Value.TranscriptionText   = firstChannel.Display;
                    await state.SaveAsync();
                }
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was ");
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