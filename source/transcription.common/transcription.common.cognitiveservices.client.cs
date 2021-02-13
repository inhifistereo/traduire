using System;
using System.Threading;
using System.Threading.Tasks;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Collections.Generic;

namespace transcription.common.cognitiveservices
{  
    public class AzureCognitiveServicesClient 
    {
        private string SubscriptionKey = Environment.GetEnvironmentVariable("AZURE_COGS_KEY", EnvironmentVariableTarget.Process);
        private string region          = Environment.GetEnvironmentVariable("AZURE_COGS_REGION", EnvironmentVariableTarget.Process);
        private const int Port = 443;

        private const string SpeechToTextBasePath = "speechtotext/v3.0/";
        private HttpClient client;
        private string AzCognitiveServicesUri; 

        private string RecordingsBlobUri; 

        public AzureCognitiveServicesClient()
        {
            AzCognitiveServicesUri = $"{region}.api.cognitive.microsoft.com";
            client = new HttpClient
            {
                Timeout = TimeSpan.FromMinutes(25),
                BaseAddress = new UriBuilder(Uri.UriSchemeHttps, AzCognitiveServicesUri, Port).Uri,
                DefaultRequestHeaders =
                {
                    { "Ocp-Apim-Subscription-Key", SubscriptionKey }
                }
            };
            client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        }

        public async Task<(Transcription,HttpStatusCode)> SubmitTranscriptionRequestAsync( Uri blob )
        {
            var request = new AzureCognitiveServicesTextToSpeechRequest();
            request.ContentUrls.Add(blob.AbsoluteUri);

            var content = new StringContent(JsonSerializer.Serialize(request));                
            using (var response = await client.PostAsync($"{SpeechToTextBasePath}Transcriptions/", content))
            {
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    return (JsonSerializer.Deserialize<Transcription>(json), response.StatusCode);
                }

                return (null, response.StatusCode);
            }
        }
        public async Task<(Transcription,HttpStatusCode)> CheckTranscriptionRequestAsync( Uri location )
        {
            if (location == null)
            {
                throw new ArgumentNullException(nameof(location));
            }

            var response = await client.GetAsync(location);

            if (response.IsSuccessStatusCode)
            {
                var json = await response.Content.ReadAsStringAsync();
                return (JsonSerializer.Deserialize<Transcription>(json), response.StatusCode);
            }

            return (null, response.StatusCode);
        }

        public async Task<(TranscriptionResults,HttpStatusCode)> DownloadTranscriptionResultAsync( Uri location )
        {            
            using (var response = await client.GetAsync(location))
            {
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    JsonSerializer.Deserialize<TranscriptionResults>(json), response.StatusCode);
                }

                return (null, response.StatusCode);
            }
        }
    }
}