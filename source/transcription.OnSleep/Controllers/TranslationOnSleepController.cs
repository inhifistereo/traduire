using System; 
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Mvc;
using Dapr;
using Dapr.Client;
using Azure.Messaging.WebPubSub;
using Azure.Core;

using transcription.models;
using transcription.common;
using transcription.common.cognitiveservices;

namespace transcription.Controllers
{ 
    [ApiController]
    public class TranslationOnSleep : ControllerBase
    {   
        private StateEntry<TraduireTranscription> state;
        private readonly TraduireNotificationService _serviceClient;
        private readonly IConfiguration _configuration;
        private readonly DaprClient _client;
        private readonly ILogger _logger;
                
        public TranslationOnPending(ILogger<TranslationOnPending> logger, IConfiguration configuration, DaprClient Client,  WebPubSubServiceClient ServiceClient)
        {
            _client = Client;
            _logger = logger;
            _configuration = configuration;
            _serviceClient = new TraduireNotificationService(ServiceClient);
        }

        [Topic(Components.PubSubName, Topics.TranscriptionPendingTopicName)]
        [HttpPost("sleep")]
        public async Task<ActionResult> Transcribe(TradiureTranscriptionRequest request,  CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation($"{request.TranscriptionId}. {request.BlobUri} was successfullly received by Dapr PubSub");
                await _serviceClient.PublishNotification(request.TranscriptionId.ToString(), $"Sleeping for {Components.SleepTimeInSeconds} s");
                await Task.Delay(new TimeSpan(0, 0, Components.SleepTimeInSeconds));
                await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionPendingTopicName, pendingEvent, cancellationToken);                      
                return Ok(request.TranscriptionId);
            }
            catch ( Exception ex )  
            {
                _logger.LogWarning($"Nuts. Something really bad happened processing {request.BlobUri} - {ex.Message}"); 
            }

            return BadRequest(); 
        }
    }
}
