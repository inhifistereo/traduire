using System; 
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Dapr;
using Dapr.Client;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;

using transcription.models;
using transcription.common;
using transcription.common.cognitiveservices;

namespace transcription.Controllers
{ 
    [ApiController]
    public class TranslationOnCompletion : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly DaprClient _client;
        private readonly AzureCognitiveServicesClient _cogsClient; 
        private readonly ILogger _logger;
                
        public TranslationOnCompletion(ILogger<TranslationOnCompletion> logger, IConfiguration configuration, DaprClient Client, AzureCognitiveServicesClient CogsClient)
        {
            _client = Client;
            _logger = logger;
            _configuration = configuration;
            _cogsClient = CogsClient;
        }

        [Topic(Components.PubSubName, Topics.TranscriptionCompletedTopicName)]
        [HttpPost("completed")]
        public async Task<ActionResult> Transcribe(TradiureTranscriptionRequest request,  CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was successfullly received by Dapr PubSub");
                var state = await _client.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, request.TranscriptionId.ToString());
                state.Value ??= new TraduireTranscription();

                (TranscriptionResults result, HttpStatusCode code)  = await _cogsClient.DownloadTranscriptionResultAsync(new Uri(request.BlobUri)); 

                if( code == HttpStatusCode.OK ) {                  
                    var firstChannel                = result.CombinedRecognizedPhrases.FirstOrDefault();
                    state.Value.Status              = TraduireTranscriptionStatus.Completed;
                    state.Value.TranscriptionText   = firstChannel.Display;
                    await state.SaveAsync();
                }
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was saved to state store ");
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