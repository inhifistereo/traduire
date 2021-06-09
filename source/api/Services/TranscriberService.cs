using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Grpc.Core;
using Microsoft.Extensions.Logging;

namespace traduire.webapi
{
    public class TranscriberService : Transcriber.TranscriberBase
    {
        private readonly ILogger<TranscriberService> _logger;
        public TranscriberService(ILogger<TranscriberService> logger)
        {
            _logger = logger;
        }

        public override Task<TranscriptionReply> TranscribeAudio(TranscriptionRequest request, ServerCallContext context)
        {
            return Task.FromResult(new TranscriptionReply {
                TranscriptionId = Guid.NewGuid().ToString(),
                CreateTime = DateTime.UtcNow.ToString(),
                LastUpdateTime = DateTime.UtcNow.ToString(),
                Status = "Running",
                FileName = "TBD",
                BlobUri = request.BlobUri,
                TranscriptionStatusUri = string.Empty,
                TranscriptionTextUri = string.Empty,
                TranscriptionText = string.Empty,
                StatusDetails = string.Empty
            });
        }
    }
}