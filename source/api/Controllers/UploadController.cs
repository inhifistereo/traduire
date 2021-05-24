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
    [Route("api/{controller}")]
    [ApiController]
    public class UploadController : ControllerBase
    {
        private readonly ILogger _logger;
        
        public UploadController(ILogger<UploadController> logger)
        {
            _logger = logger;
        }
        
        [HttpPost, DisableRequestSizeLimit]
        public async Task<ActionResult> Post([FromForm] IFormFile file, [FromServices] DaprClient daprClient, CancellationToken cancellationToken)
        {
            var dapr = new DaprHelper( daprClient, file );
            var TranscriptionId = Guid.NewGuid();

            try{
                var response = await dapr.UploadFile(cancellationToken);
                _logger.LogInformation($"{TranscriptionId}. File was successfullly saved to {Components.BlobStoreName} blob storage");

                var state = await dapr.UpdateState(TranscriptionId, response.blobURL);
                _logger.LogInformation($"{TranscriptionId}. Record was successfullly saved as to {Components.StateStoreName} State Store");

                await dapr.PublishEvent( TranscriptionId, response.blobURL, cancellationToken);
                _logger.LogInformation($"{TranscriptionId}. {response.blobURL} was successfullly published to {Components.PubSubName} pubsub store");
                
                return Ok( new { TranscriptionId = TranscriptionId, StatusMessage = state.Value.Status, LastUpdated = state.Value.LastUpdateTime }  ); 
            }
            catch( Exception ex ) 
            {
                _logger.LogWarning($"Failed to create {file.FileName} - {ex.Message}");    
            }

            return BadRequest();
        }
    }
}