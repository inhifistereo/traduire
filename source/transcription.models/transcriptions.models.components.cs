using System;

namespace transcription.models
{
    public class Components 
    {
        public readonly string BlobStoreName = Environment.GetEnvironmentVariable("DAPR_BLOB_STORE_NAME", EnvironmentVariableTarget.Process);
        public readonly string PubSubName = Environment.GetEnvironmentVariable("DAPR_PUBSUB_NAME", EnvironmentVariableTarget.Process);
        public readonly string StateStoreName = Environment.GetEnvironmentVariable("DAPR_STATESTORE_NAME", EnvironmentVariableTarget.Process);
        public readonly string CreateOperation = "create";
    }
}