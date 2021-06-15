using System;
using System.Threading.Tasks;
using System.Linq;
using Azure.Messaging.WebPubSub;
using Azure.Core;

namespace publisher
{
    class Program
    {
        static async Task Main(string[] args)
        {
            if (args.Length != 1) {
                Console.WriteLine("Usage: publisher <connectionString>");
                return;
            }

            var connectionString = args[0];
            var hub = "test01";

            var serviceClient = new WebPubSubServiceClient(connectionString, hub);
            var user = "f2b672a3-6e7b-4ce5-98b3-0b0721cea52a";
            var count = 0;

            do {
                Console.WriteLine($"Sending {count}");

                serviceClient.SendToUser(user,  RequestContent.Create( new {
                    TimeStamp  = DateTime.UtcNow,
                    Message    = $"Hello World - {count}"
                }));
                
                count++;
                await Task.Delay(5000);

            }while(true);

        }
    }
}
