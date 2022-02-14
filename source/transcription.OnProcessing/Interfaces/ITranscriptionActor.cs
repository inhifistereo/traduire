using System.Threading.Tasks;
using Dapr.Actors;

namespace transcription.actors {
    public interface ITranscriptionActor : IActor
    {
        Task CheckTranscriptionStatus();
        Task UnRegisterReoccuring(string uri);
        Task RegisterReoccuring(string uri);
    }
}