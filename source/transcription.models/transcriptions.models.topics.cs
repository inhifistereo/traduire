using System;

namespace transcription.models
{
    public class Topics
    {
        public const string TranscriptionSubmittedTopicName = "ontranscription_submitted";
        public const string TranscriptionProcessingTopicName   = "ontranscription_pending";
        public const string TranscriptionCompletedTopicName = "ontranscription_completed";
        public const string TranscriptionFailedTopicName    = "ontranscription_failed";
        public const string TranscriptionSleepTopicName    = "ontranscription_sleep";
    }
}