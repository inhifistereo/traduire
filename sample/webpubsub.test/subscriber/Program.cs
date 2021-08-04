using System;
using System.Net.WebSockets;
using System.Threading.Tasks;

using Azure.Messaging.WebPubSub;

using Websocket.Client;

namespace subscriber
{
    class Program
    {
        static async Task Main(string[] args)
        {
            if (args.Length != 1)
            {
                Console.WriteLine("Usage: subscriber <connectionString>");
                return;
            }

            var connectionString = args[0];
            var hub = "test01";
            var user = "f2b672a3-6e7b-4ce5-98b3-0b0721cea52a";

            var serviceClient = new WebPubSubServiceClient(connectionString, hub);
            var url = serviceClient.GetClientAccessUri(userId: user );

            using (var client = new WebsocketClient(url, () =>
            {
                var inner = new ClientWebSocket();
                inner.Options.AddSubProtocol("json.webpubsub.azure.v1");
                return inner;
            }))
            {
                client.MessageReceived.Subscribe(msg => Console.WriteLine($"Message received: {msg}"));
                await client.Start();
                Console.WriteLine("Connected.");
                Console.Read();
            }
        }
    }
}
