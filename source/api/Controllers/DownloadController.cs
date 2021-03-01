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
    public class DownloadController : ControllerBase
    {
        private readonly ILogger _logger;

        public DownloadController(ILogger<UploadController> logger)
        {
            _logger = logger;
        }

        [HttpGet("{TranscriptionId}")]
        public async Task<ActionResult> Get(string TranscriptionId, CancellationToken cancellationToken, [FromServices] DaprClient daprClient)
        {
            try{
                _logger.LogInformation($"{TranscriptionId}. Attempting to download completed transcription");

                var state = await daprClient.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, TranscriptionId);
                
                if( state.Value == null ) {
                    return NotFound();
                }

                if( state.Value.Status == TraduireTranscriptionStatus.Completed ) {
                    _logger.LogInformation($"{TranscriptionId}. Current status is {TraduireTranscriptionStatus.Completed}. Returning transcription");
                    return Ok( new { TranscriptionId = TranscriptionId, StatusMessage = state.Value.Status, Transcription = state.Value.TranscriptionText }  ); 
                }    

                _logger.LogInformation($"{TranscriptionId}. Transcription status is not {TraduireTranscriptionStatus.Completed}");
            }
            catch( Exception ex ) 
            {
                //Add Compensating tranasaction to undo error
                _logger.LogWarning($"Failed to transctionId {TranscriptionId} - {ex.Message}");    
            }

            
            return BadRequest(); 
        }
    }
}