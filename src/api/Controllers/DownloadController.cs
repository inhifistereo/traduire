using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Dapr.Client;
using Microsoft.Extensions.Logging;

using transcription.models;
using transcription.api.dapr;

namespace transcription.Controllers
{
    [Route("api/download")]
    [ApiController]
    public class DownloadController : ControllerBase
    {
        private readonly ILogger _logger;
        private static DaprTranscriptionService _client;

        public DownloadController(ILogger<DownloadController> logger, DaprTranscriptionService client)
        {
            _logger = logger;
            _client = client;
        }

        [HttpGet("{TranscriptionId}")]
        public async Task<ActionResult> Get(string TranscriptionId, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation($"{TranscriptionId}. Attempting to download completed transcription");

                var state = await _client.GetState(TranscriptionId);

                if (state == null)
                {
                    return NotFound();
                }

                if (state.Status == TraduireTranscriptionStatus.Completed)
                {
                    _logger.LogInformation($"{TranscriptionId}. Current status is {TraduireTranscriptionStatus.Completed}. Returning transcription");
                    return Ok(new { TranscriptionId = TranscriptionId, StatusMessage = state.Status, Transcription = state.TranscriptionText });
                }

                _logger.LogInformation($"{TranscriptionId}. Transcription status is not {TraduireTranscriptionStatus.Completed}");
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Failed to transctionId {TranscriptionId} - {ex.Message}");
            }


            return BadRequest();
        }
    }
}