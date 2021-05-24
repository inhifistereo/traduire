using System; 
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using Dapr;
using Dapr.Client;

using transcription.models;

namespace transcription.api.dapr
{
    public class DaprHelper 
    {
        private string safeFileName;
        private static IFormFile _file;
        private static DaprClient _client; 

        public DaprHelper(DaprClient client, IFormFile file) 
        {
            _file = file;
            _client = client;
        }

        public DaprHelper(DaprClient client) 
        {
            _client = client;
        }

        private async Task<string> ConvertFileToBase64Encoding()
        {          
            try
            {
                using (var memoryStream = new MemoryStream())
                {
                    await _file.CopyToAsync(memoryStream);
                    return Convert.ToBase64String(memoryStream.ToArray());
                }            
            }
            catch{}

            return String.Empty;
        }

        public async Task<BlobBindingResponse> UploadFile (CancellationToken cancellationToken) 
        {
            safeFileName = WebUtility.HtmlEncode(_file.FileName); 

            var metadata = new Dictionary<string, string>();
            metadata.Add("blobName", safeFileName);

            var encodedFile = await ConvertFileToBase64Encoding();

            return( await _client.InvokeBindingAsync<string,BlobBindingResponse>(
                    Components.BlobStoreName, 
                    Components.CreateOperation, 
                    encodedFile, 
                    metadata,
                    cancellationToken
            ));   
        }

        public async Task<StateEntry<TraduireTranscription>> UpdateState(Guid id, string url)
        {
            var state = await _client.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, id.ToString());

            state.Value ??= new TraduireTranscription() { 
                TranscriptionId     = id,
                CreateTime          = DateTime.UtcNow,
                LastUpdateTime      = DateTime.UtcNow,
                Status              = TraduireTranscriptionStatus.Started,
                FileName            = safeFileName,
                BlobUri             = url
            };
            await state.SaveAsync();

            return state;
        }

        public async Task PublishEvent(Guid id, string url, CancellationToken cancellationToken)
        {
            var eventdata = new TradiureTranscriptionRequest() { 
                TranscriptionId = id, 
                BlobUri = url
            };

            await _client.PublishEventAsync( Components.PubSubName, Topics.TranscriptionSubmittedTopicName, eventdata, cancellationToken );
        }
    }
}