using System; 
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Mvc;
using Dapr;
using Dapr.Actors;
using Dapr.Actors.Runtime;
using Dapr.Client;
using Azure.Messaging.WebPubSub;
using Azure.Core;

using transcription.models;
using transcription.common;
using transcription.Controllers;
using transcription.common.cognitiveservices;


namespace transcription.actors {
    public class TranscriptionActor : Actor, ITranscriptionActor, IRemindable
    {
        private StateEntry<TraduireTranscription> state;
        private readonly TraduireNotificationService _serviceClient;
        private readonly IConfiguration _configuration;
        private readonly DaprClient _client;
        private readonly AzureCognitiveServicesClient _cogsClient; 
        private readonly ILogger _logger;
                    
        public TranscriptionActor(ActorHost host, ILogger<TranslationOnProcessing> logger, IConfiguration configuration, DaprClient Client, AzureCognitiveServicesClient CogsClient, WebPubSubServiceClient ServiceClient)
            : base(host)
        {
            _client = Client;
            _logger = logger;
            _configuration = configuration;
            _cogsClient = CogsClient;
            _serviceClient = new TraduireNotificationService(ServiceClient);
        }

        public Task SubmitAsync(string uri)
        {
            return Task.CompletedTask;

            /*
            await StateManager.SetStateAsync(OrderDetailsStateName, orderState);
            await StateManager.SetStateAsync(OrderStatusStateName, OrderStatus.Submitted);

            await RegisterReminderAsync(
                GracePeriodElapsedReminder,
                null,
                TimeSpan.FromSeconds(_settings.Value.GracePeriodTime),
                TimeSpan.FromMilliseconds(-1));

            await _eventBus.PublishAsync(new OrderStatusChangedToSubmittedIntegrationEvent(
                OrderId,
                OrderStatus.Submitted.Name,
                buyerId,
                buyerEmail));
            */
        }

        public Task CheckTranscriptionStatus() 
        {
            return Task.CompletedTask;
        }

        public Task UnRegisterReoccuring(string uri)
        {
            return Task.CompletedTask;
        }

        public Task ReceiveReminderAsync(string reminderName, byte[] state, TimeSpan dueTime, TimeSpan period)
        {
            /*
                (Transcription response, HttpStatusCode code) = await _cogsClient.CheckTranscriptionRequestAsync(new Uri(request.BlobUri));
                await _serviceClient.PublishNotification(request.TranscriptionId.ToString(), response.Status);

                switch(code)
                {
                    case HttpStatusCode.OK when response.Status == "Succeeded":
                        _logger.LogInformation($"{request.TranscriptionId}. Azure Cognitive Services has completed processing transcription");
                        var completionEvent = await UpdateStateRepository(TraduireTranscriptionStatus.Completed, code, response.Links.Files); 
                        await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionCompletedTopicName, completionEvent, cancellationToken);  

                       return Ok(request.TranscriptionId);

                    case HttpStatusCode.OK:
                        _logger.LogInformation($"{request.TranscriptionId}. Azure Cognitive Services is still progressing request");
                        var pendingEvent = await UpdateStateRepository(TraduireTranscriptionStatus.Pending, code, response.Self );
                        await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionSleepTopicName, pendingEvent, cancellationToken);
                        return Ok(request.TranscriptionId);

                    default:
                        _logger.LogInformation($"{request.TranscriptionId}. Transcription Failed for an unexpected reason. Added to Failed Queue for review");
                        var failedEvent = await UpdateStateRepository(TraduireTranscriptionStatus.Failed, code, response.Self);
                        await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionFailedTopicName, failedEvent, cancellationToken);
                        break;
                }
            */
            return Task.CompletedTask;
        }
    }
}
