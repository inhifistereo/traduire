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

using transcription.models;
using transcription.common;

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

        private async Task<string> ConvertFileToBase64Encoding( IFormFile f )
        {          
            try
            {
                using (var memoryStream = new MemoryStream())
                {
                    await f.CopyToAsync(memoryStream);
                    return Convert.ToBase64String(memoryStream.ToArray());
                }            
            }
            catch{}

            return String.Empty;
        }

        [HttpPost]
        public async Task<ActionResult> Post(IFormFile file, CancellationToken cancellationToken, [FromServices] DaprClient daprClient)
        {
            try{
                var TranscriptionId = Guid.NewGuid();
                var safeFileName = WebUtility.HtmlEncode(file.FileName); 

                var metadata = new Dictionary<string, string>();
                metadata.Add("blobName", safeFileName);

                var encodedFile = await ConvertFileToBase64Encoding(file);

                var response = await daprClient.InvokeBindingAsync<string,BlobBindingResponse>(
                        Components.BlobStoreName, 
                        Components.CreateOperation, 
                        encodedFile, 
                        metadata,
                        cancellationToken
                );                      
                _logger.LogInformation($"{TranscriptionId}. File was successfullly saved as {safeFileName} to {Components.BlobStoreName} blob storage");

                var state = await daprClient.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, TranscriptionId.ToString());
                state.Value ??= new TraduireTranscription() { 
                    TranscriptionId     = TranscriptionId,
                    CreateTime          = DateTime.UtcNow,
                    LastUpdateTime      = DateTime.UtcNow,
                    Status              = TraduireTranscriptionStatus.Started,
                    FileName            = safeFileName,
                    BlobUri             = response.blobURL
                };
                await state.SaveAsync();
                _logger.LogInformation($"{TranscriptionId}. Record was successfullly saved as to {Components.StateStoreName} State Store");

                var eventdata = new TradiureTranscriptionRequest() { 
                    TranscriptionId = TranscriptionId, 
                    BlobUri = response.blobURL
                };
                await daprClient.PublishEventAsync(Components.PubSubName, Topics.TranscriptionSubmittedTopicName, eventdata, cancellationToken );

                _logger.LogInformation($"{TranscriptionId}. Event was successfullly published to {Components.PubSubName} pubsub store");
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