using System.Threading.Tasks;
using Dapr.Actors;

namespace transcription.actors {
    public interface ITranscriptionActor : IActor
    {
        Task CheckTranscriptionStatus();
        Task SubmitAsync(string uri);
    }
}