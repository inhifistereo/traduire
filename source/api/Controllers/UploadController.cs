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
    [Route("api/upload")]
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

            _logger.LogInformation($"File upload request was received.");
            try{
                _logger.LogInformation($"{TranscriptionId}. Base64 encoding file and uploading via Dapr to {Components.BlobStoreName}.");
                
                var response = await dapr.UploadFile(cancellationToken);
                _logger.LogInformation($"{TranscriptionId}. File was successfullly saved to {Components.BlobStoreName} blob storage"); 
                
                var sasUrl = await dapr.GetBlobSasToken(response.blobURL, Environment.GetEnvironmentVariable("MSI_CLIENT_ID"));
                _logger.LogInformation($"{TranscriptionId}. File was successfullly saved to {Components.BlobStoreName} blob storage"); 

                var state = await dapr.UpdateState(TranscriptionId, sasUrl);
                _logger.LogInformation($"{TranscriptionId}. Record was successfullly saved as to {Components.StateStoreName} State Store");

                await dapr.PublishEvent( TranscriptionId, sasUrl, cancellationToken);
                _logger.LogInformation($"{TranscriptionId}. {sasUrl} was successfullly published to {Components.PubSubName} pubsub store");

                return Ok( new { TranscriptionId = TranscriptionId, StatusMessage = state.Value.Status, LastUpdated = state.Value.LastUpdateTime }  ); 
            }
            catch( Exception ex ) 
            {
                _logger.LogWarning($"Failed to create {file.FileName} - {ex.Message}");    

                if (ex.InnerException != null)
                    _logger.LogWarning("Inner exception: {0}", ex.InnerException);
            }

            return BadRequest();
        }
    }
}
