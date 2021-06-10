using System; 
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using Dapr;
using Dapr.Client;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Sas;

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

        public async Task<string> GetBlobSasToken(string url, string userAssignedClientId) 
        {
            var uri = new Uri(url);
            var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions { ManagedIdentityClientId = userAssignedClientId });
            var blobClient = new BlobServiceClient(new Uri($"https://{uri.Host}"), credential);
            var accountName = blobClient.AccountName;

            Console.WriteLine(uri.Segments[1].Trim('/'));
            
            var delegationKey = await blobClient.GetUserDelegationKeyAsync(DateTimeOffset.UtcNow, DateTimeOffset.UtcNow.AddDays(7));
            BlobSasBuilder sasBuilder = new BlobSasBuilder()
            {
                BlobContainerName = uri.Segments[1].Trim('/'),
                BlobName = uri.Segments[2],
                Resource = "b",
                StartsOn = DateTimeOffset.UtcNow,
                ExpiresOn = DateTimeOffset.UtcNow.AddHours(1)
            };

            sasBuilder.SetPermissions(BlobSasPermissions.Read);
            Console.WriteLine(sasBuilder.Permissions);
            var sasQueryParams = sasBuilder.ToSasQueryParameters(delegationKey, accountName).ToString();

            UriBuilder sasUri = new UriBuilder()
            {
                Scheme = "https",
                Host = uri.Host,
                Path = uri.AbsolutePath,
                Query = sasQueryParams
            };

            return sasUri.ToString();
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

        public async Task<TraduireTranscription> GetState(Guid id)
        {
            var state = await _client.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, id.ToString());
            return state.Value;
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