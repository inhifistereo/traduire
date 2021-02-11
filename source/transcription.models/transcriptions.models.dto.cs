using System;

namespace transcription.models
{ 
    public class TranscriptionRequest
    {
        public Guid TranscriptionId { get; set; }
        public string BlobUri { get; set; }
    }

    public class Transcription
    {
        public Guid TranscriptionId { get; set; }
        public DateTime CreateTime { get; set; }
        public DateTime LastUpdateTime { get; set; }
        public TranscriptionStatus Status { get; set; }
        public string FileName { get; set; }
        public string BlobUri { get; set; }
        public string TranscriptionStatusUri { get; set; }
        public string TranscriptionText { get; set; }
    }

    public enum TranscriptionStatus
    {
        Started,
        SentToCognitiveServices,
        Pending,
        Completed,
        Failed
    }
}
