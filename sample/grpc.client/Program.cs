using System;
using System.Net.Http;
using System.Threading.Tasks;
using Grpc.Net.Client;
using Grpc.Core;
using traduire.webapi;

namespace GrpcTraduireClient
{
    class Program
    {
        static async Task Main(string[] args)
        {
            var address = "";
	    var apikey = "";

            var credentials = CallCredentials.FromInterceptor((context, metadata) =>
            {
                metadata.Add("apikey", "");
                return Task.CompletedTask;
            });

            var channel = GrpcChannel.ForAddress(address, new GrpcChannelOptions
            {
                Credentials = ChannelCredentials.Create(new SslCredentials(), credentials)
            });
        
            var client =  new Transcriber.TranscriberClient(channel);
            var reply = await client.TranscribeAudioAsync(new TranscriptionRequest { 
                TranscriptionId = Guid.NewGuid().ToString(), 
                BlobUri = "https://www.bjdazure.tech"
            });
            
            Console.WriteLine("Transcription ID: " + reply.TranscriptionId);
            Console.WriteLine("Transcription ID: " + reply.CreateTime);
            Console.WriteLine("Transcription ID: " + reply.BlobUri);
            Console.WriteLine("Transcription ID: " + reply.FileName);
        }
    }
}
