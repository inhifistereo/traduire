using System; 
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Dapr.Client;
using Microsoft.Extensions.Logging;

using transcription.models;
using transcription.api.dapr;

namespace transcription.Controllers
{ 
    [Route("api/transcribe")]
    [ApiController]
    public class TranscribeController : ControllerBase
    {
        private readonly ILogger _logger;
        
        public TranscribeController(ILogger<TranscribeController> logger)
        {
            _logger = logger;
        }
        
        [HttpPost]
        public async Task<ActionResult> Post( TranscriptionReferenceRequest reference, [FromServices] DaprClient daprClient, CancellationToken cancellationToken)
        {
            var dapr = new DaprHelper( daprClient );
            var TranscriptionId = Guid.NewGuid();

            try{
                _logger.LogInformation($"{TranscriptionId}. Request to transcribe {reference.blobURL} was received");

                var state = await dapr.UpdateState(TranscriptionId, reference.blobURL);
                _logger.LogInformation($"{TranscriptionId}. Record was successfullly saved as to {Components.StateStoreName} State Store");

                await dapr.PublishEvent( TranscriptionId, reference.blobURL, cancellationToken);
                _logger.LogInformation($"{TranscriptionId}. {reference.blobURL} was successfullly published to {Components.PubSubName} pubsub store");
                
                return Ok( new { TranscriptionId = TranscriptionId, StatusMessage = state.Value.Status, LastUpdated = state.Value.LastUpdateTime }  ); 
            }
            catch( Exception ex ) 
            {
                _logger.LogWarning($"Failed to transcribe {reference.blobURL} - {ex.Message}");    
            }

            return BadRequest();
        }
    }
}