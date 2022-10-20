using System;

namespace transcription.models
{
    public class BlobBindingResponse
    {
        public string blobURL { get; set; }
    }

    public class TranscriptionReferenceRequest
    {
        public string blobURL { get; set; }
    }
}
