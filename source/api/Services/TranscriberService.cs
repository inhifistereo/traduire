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
                Status = "TBD",
                FileName = "TBD",
                BlobUri = request.BlobUri,
                TranscriptionStatusUri = string.Empty,
                TranscriptionTextUri = string.Empty,
                TranscriptionText = string.Empty,
                StatusDetails = string.Empty
            });
        }

        public override async Task TranscribeAudioStream(TranscriptionRequest request, IServerStreamWriter<TranscriptionReply> responseStream, ServerCallContext context)
        {
            await responseStream.WriteAsync(new TranscriptionReply {
                TranscriptionId = Guid.NewGuid().ToString(),
                CreateTime = DateTime.UtcNow.ToString(),
                LastUpdateTime = DateTime.UtcNow.ToString(),
                Status = "Started",
                FileName = "TBD",
                BlobUri = request.BlobUri,
                TranscriptionStatusUri = string.Empty,
                TranscriptionTextUri = string.Empty,
                TranscriptionText = string.Empty,
                StatusDetails = string.Empty
            });

            await Task.Delay(500);

            await responseStream.WriteAsync(new TranscriptionReply {
                TranscriptionId = Guid.NewGuid().ToString(),
                CreateTime = DateTime.UtcNow.ToString(),
                LastUpdateTime = DateTime.UtcNow.ToString(),
                Status = "SentToCognitiveServices",
                FileName = string.Empty,
                BlobUri = request.BlobUri,
                TranscriptionStatusUri = string.Empty,
                TranscriptionTextUri = string.Empty,
                TranscriptionText = string.Empty,
                StatusDetails = string.Empty
            });

            await Task.Delay(500);

            await responseStream.WriteAsync(new TranscriptionReply {
                TranscriptionId = Guid.NewGuid().ToString(),
                CreateTime = DateTime.UtcNow.ToString(),
                LastUpdateTime = DateTime.UtcNow.ToString(),
                Status = "Pending",
                FileName = string.Empty,
                BlobUri = request.BlobUri,
                TranscriptionStatusUri = string.Empty,
                TranscriptionTextUri = string.Empty,
                TranscriptionText = string.Empty,
                StatusDetails = string.Empty
            });

            await Task.Delay(500);

            await responseStream.WriteAsync(new TranscriptionReply {
                TranscriptionId = Guid.NewGuid().ToString(),
                CreateTime = DateTime.UtcNow.ToString(),
                LastUpdateTime = DateTime.UtcNow.ToString(),
                Status = "Completed",
                FileName = string.Empty,
                BlobUri = request.BlobUri,
                TranscriptionStatusUri = string.Empty,
                TranscriptionTextUri = string.Empty,
                TranscriptionText = string.Empty,
                StatusDetails = string.Empty
            });
        }
    }
}