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
    public class StatusController : ControllerBase
    {
        private readonly ILogger _logger;

        public StatusController(ILogger<UploadController> logger)
        {
            _logger = logger;
        }

        [HttpGet("{TranscriptionId}")]
        public async Task<ActionResult> Get(string TranscriptionId, CancellationToken cancellationToken, [FromServices] DaprClient daprClient)
        {
            try{
                _logger.LogInformation($"{TranscriptionId}. Status API Called");

                var state = await daprClient.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, TranscriptionId);
                
                if( state.Value == null ) {
                    return NotFound();
                }

                _logger.LogInformation($"{TranscriptionId}. Current status is {state.Value.Status}");
                return Ok( new { TranscriptionId = TranscriptionId, StatusMessage = state.Value.Status, LastUpdated = state.Value.LastUpdateTime }  ); 
            }
            catch( Exception ex ) 
            {
                _logger.LogWarning($"Failed to transctionId {TranscriptionId} - {ex.Message}");    
            }

            return BadRequest();
        }
    }
}