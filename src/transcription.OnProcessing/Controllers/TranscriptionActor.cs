using System;
using System.Net;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Dapr;
using Dapr.Actors.Runtime;
using Dapr.Client;
using Azure.Messaging.WebPubSub;

using transcription.models;
using transcription.common;
using transcription.Controllers;
using transcription.common.cognitiveservices;


namespace transcription.actors
{
    public class TranscriptionActor : Actor, ITranscriptionActor, IRemindable
    {
        private const int WAIT_TIME = 30;
        private const string ProcessingStatusReminder = "ProcessingStatusReminder";

        private StateEntry<TraduireTranscription> state;
        private readonly TraduireNotificationService _serviceClient;
        private readonly IConfiguration _configuration;
        private readonly DaprClient _client;
        private readonly AzureCognitiveServicesClient _cogsClient;
        private readonly ILogger _logger;
        private TradiureTranscriptionRequest transcriptionRequest;

        public TranscriptionActor(ActorHost host, ILogger<TranslationOnProcessing> logger, IConfiguration configuration, DaprClient Client, AzureCognitiveServicesClient CogsClient, WebPubSubServiceClient ServiceClient)
            : base(host)
        {
            _client = Client;
            _logger = logger;
            _configuration = configuration;
            _cogsClient = CogsClient;
            _serviceClient = new TraduireNotificationService(ServiceClient);
        }

        public async Task SubmitAsync(string transcriptionId, string uri)
        {
            transcriptionRequest = new TradiureTranscriptionRequest()
            {
                TranscriptionId = new Guid(transcriptionId),
                BlobUri = uri
            };

            await UpdateStateRepository(TraduireTranscriptionStatus.Pending, HttpStatusCode.Accepted);

            _logger.LogInformation($"{transcriptionId}. Registering {ProcessingStatusReminder} Actor Reminder for {WAIT_TIME} seconds");
            await RegisterReminderAsync(
                ProcessingStatusReminder,
                null,
                TimeSpan.FromSeconds(WAIT_TIME),
                TimeSpan.FromSeconds(WAIT_TIME));

        }

        private async Task<(Transcription response, HttpStatusCode code)> CheckCognitiveServicesTranscriptionStatusAsync()
        {
            (Transcription response, HttpStatusCode code) = await _cogsClient.CheckTranscriptionRequestAsync(new Uri(transcriptionRequest.BlobUri));
            await _serviceClient.PublishNotification(transcriptionRequest.TranscriptionId.ToString(), response.Status);
            return (response, code);
        }

        private async Task<StateEntry<TraduireTranscription>> GetCurrentState(string transcriptionId)
        {
            var state = await _client.GetStateEntryAsync<TraduireTranscription>(Components.StateStoreName, transcriptionId);
            return state;
        }

        private async Task UpdateStateRepository(TraduireTranscriptionStatus status, HttpStatusCode code)
        {
            state = await GetCurrentState(transcriptionRequest.TranscriptionId.ToString());
            state.Value ??= new TraduireTranscription();
            state.Value.LastUpdateTime = DateTime.UtcNow;
            state.Value.Status = status;
            state.Value.StatusDetails = code.ToString();
            state.Value.TranscriptionStatusUri = transcriptionRequest.BlobUri;
            await state.SaveAsync();
        }

        private async Task PublishTranscriptionCompletion(string transcriptionId, string uri)
        {
            _logger.LogInformation($"{transcriptionId}. Azure Cognitive Services has completed processing transcription");
            await UpdateStateRepository(TraduireTranscriptionStatus.Completed, HttpStatusCode.OK);

            var completionEvent = new TradiureTranscriptionRequest()
            {
                TranscriptionId = new Guid(transcriptionId),
                BlobUri = uri
            };

            await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionCompletedTopicName, completionEvent, CancellationToken.None);
            await UnregisterReminderAsync(ProcessingStatusReminder);
        }

        private async Task PublishTranscriptionFailure()
        {
            _logger.LogInformation($"{transcriptionRequest.TranscriptionId.ToString()}. Transcription Failed for an unexpected reason. Added to Failed Queue for review");
            await UpdateStateRepository(TraduireTranscriptionStatus.Failed, HttpStatusCode.BadRequest);

            await _client.PublishEventAsync(Components.PubSubName, Topics.TranscriptionFailedTopicName, transcriptionRequest, CancellationToken.None);
            await UnregisterReminderAsync(ProcessingStatusReminder);
        }

        private async Task PublishTranscriptionStillProcessing()
        {
            _logger.LogInformation($"{transcriptionRequest.TranscriptionId.ToString()}. Azure Cognitive Services is still progressing request");
            await UpdateStateRepository(TraduireTranscriptionStatus.Pending, HttpStatusCode.OK);
        }

        private async Task CheckProcessingStatus()
        {
            (Transcription response, HttpStatusCode code) = await CheckCognitiveServicesTranscriptionStatusAsync();

            switch (code)
            {
                case HttpStatusCode.OK when response.Status == "Succeeded":
                    await PublishTranscriptionCompletion(transcriptionRequest.TranscriptionId.ToString(), response.Links.Files);
                    break;
                case HttpStatusCode.OK:
                    await PublishTranscriptionStillProcessing();
                    break;
                default:
                    await PublishTranscriptionFailure();
                    break;
            }
        }

        public Task ReceiveReminderAsync(string reminderName, byte[] state, TimeSpan dueTime, TimeSpan period)
        {
            return reminderName switch
            {
                ProcessingStatusReminder => CheckProcessingStatus(),
                _ => Task.CompletedTask,
            };
        }
    }
}
