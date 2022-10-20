using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Net;
using transcription.common.cognitiveservices;

namespace cognitiveservices.test
{
    class Program
    {
        static async Task Main(string[] args)
        {
            var file = new Uri("https://tra7db0afiles01.blob.core.windows.net/mp3files/01-_In_the_Beginning.mp3");
            AzureCognitiveServicesClient client = new AzureCognitiveServicesClient();

            (Transcription response, HttpStatusCode code)  = await client.SubmitTranscriptionRequestAsync(file);
            
            if( code != HttpStatusCode.Created ) {
                Console.WriteLine($"Transcription failed with status code of {code}");
                return;
            }

            Console.WriteLine($"Transcription submitted at {response.Self} with a status of {response.Status}");

            Transcription currentStatus;
            HttpStatusCode currentStatusCode;
            do {
                Console.WriteLine($"Sleeping for 1 minute....");
                Thread.Sleep(10000);
                (currentStatus, currentStatusCode)  = await client.CheckTranscriptionRequestAsync(new Uri(response.Self)); 
    
                if( currentStatusCode != HttpStatusCode.OK ) {
                    Console.WriteLine($"Transcription Status Checked failed with status code of {currentStatusCode}");
                    return;
                }
                else {
                    Console.WriteLine($"Transcription Current status {currentStatus.Status}");
                }

            } while( currentStatus.Status != "Succeeded");

            Console.WriteLine($"Transcription succeeded. Downloading results from {currentStatus.Links.Files}");
            (TranscriptionResults result, HttpStatusCode currentStatusCode2)  = await client.DownloadTranscriptionResultAsync(new Uri(currentStatus.Links.Files)); 
            
            var firstChannel = result.CombinedRecognizedPhrases.FirstOrDefault();
            Console.WriteLine($"Results:\n{firstChannel.Display}");
        }
    }
}
