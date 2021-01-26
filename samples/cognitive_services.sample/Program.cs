using System;                        
using System.Collections.Generic;
using System.Threading.Tasks;

using System.Net.Http.Headers;
using System.Net.Http;

using Newtonsoft.Json;

namespace BatchClient
{
    class Program
    {
        const string SubscriptionKey = "*****************************************";
        const string Region = "centralus";
        const int Port = 443;
        const string Locale = "en-US";
        const string RecordingsBlobUri = "https://vxzjlfiles01.blob.core.windows.net/mp3files/01-_In_the_Beginning.mp3";

        const string Name = "Simple transcription";
        const string SpeechToTextBasePath = "speechtotext/v3.0/";

        static async Task Main()
        {
            await TranscribeAsync();
        }

        static async Task TranscribeAsync()
        {
            Console.WriteLine("Starting transcriptions client...");

            var client = new HttpClient
            {
                Timeout = TimeSpan.FromMinutes(25),
                BaseAddress = new UriBuilder(Uri.UriSchemeHttps, $"{Region}.api.cognitive.microsoft.com", Port).Uri,
                DefaultRequestHeaders =
                {
                    { "Ocp-Apim-Subscription-Key", SubscriptionKey }
                }
            };

            var request = new TranscriptionRequest();
            request.ContentUrls.Add(RecordingsBlobUri);
            request.DisplayName = Name;
            request.Locale = Locale;
            var res = JsonConvert.SerializeObject(request);

            var sc = new StringContent(res);
            sc.Headers.ContentType = new MediaTypeHeaderValue("application/json");
            
            Uri transcriptionLocation = null;
            using (var response = await client.PostAsync($"{SpeechToTextBasePath}Transcriptions/", sc))
            {
                if (!response.IsSuccessStatusCode)
                {
                    Console.WriteLine("Error {0} starting transcription.", response.StatusCode);
                    return;
                }

                transcriptionLocation = response.Headers.Location;
            }

            Console.WriteLine($"Created transcription at location {transcriptionLocation}.");
        }
    }

    public class TranscriptionRequest
    {
        public List<string> ContentUrls { get; set; }
        public string DisplayName { get; set; }
        public TranscriptionRequestProperties Properties { get; set; }
        public string Locale { get; set; }
        
        public TranscriptionRequest()
        {
            ContentUrls = new List<string>();
            Properties = new TranscriptionRequestProperties();
        }
    }

    public class TranscriptionRequestProperties 
    {
        public bool DiarizationEnabled { get; set; } = false; 
        public bool WordLevelTimestampsEnabled { get; set; } = false; 
        public string PunctuationMode { get; set; } = "DictatedAndAutomatic";
        public string ProfanityFilterMode { get; set;} = "Masked";
    }

}