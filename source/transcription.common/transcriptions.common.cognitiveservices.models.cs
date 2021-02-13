using System;
using System.ComponentModel;
using System.Text.Json.Serialization;
using System.Collections.Generic;

namespace transcription.common.cognitiveservices 
{
    public enum ProfanityFilterMode
    {
        None,
        Removed,
        Tags,
        Masked
    }

    public enum PunctuationMode
    {
        None,
        Dictated,
        Automatic,
        DictatedAndAutomatic
    }

    public class AzureCognitiveServicesTextToSpeechRequest
    {
        public List<string> ContentUrls { get; set; }
        public string DisplayName { get; set; } = "Transcription of file using default model for en-US";
        public AzureCognitiveServicesTextToSpeechProperties Properties { get; set; }
        public string Locale { get; set; } = "en-US";
        
        public AzureCognitiveServicesTextToSpeechRequest()
        {
            ContentUrls = new List<string>();
            Properties = new AzureCognitiveServicesTextToSpeechProperties();
        }
    }

    public class AzureCognitiveServicesTextToSpeechProperties 
    {
        public AzureCognitiveServicesTextToSpeechProperties() {
            this.PunctuationMode = PunctuationMode.DictatedAndAutomatic;
            this.ProfanityFilterMode = ProfanityFilterMode.Masked; 
            WordLevelTimestampsEnabled =  DiarizationEnabled = false;
        }

        public bool DiarizationEnabled { get; set; }
        public bool WordLevelTimestampsEnabled { get; set; }
        public PunctuationMode PunctuationMode { get; set; } 
        public ProfanityFilterMode ProfanityFilterMode { get; set; } 
    }

    //Reference - https://westus.dev.cognitive.microsoft.com/docs/services/speech-to-text-api-v3-0/operations/GetTranscription
    public class Transcription
    {
        public string Self { get; set; }
        public List<string> ContentUrls { get; set; }
        public TranscriptionModel Model { get; set; }
        public TranscriptionLinks Links { get; set; }
        public TranscriptionProperties Properties { get; set; }   
        public DateTime LastActionDateTime { get; set; }
        public string Status { get; set; }
        public DateTime CreatedDateTime { get; set; }
        public string Locale { get; set; }
        public string DisplayName { get; }
        public IDictionary<string,string> CustomProperties { get; set;}
    }

    public class TranscriptionLinks 
    {
        public string files { get; set; }
    }

    public class TranscriptionModel 
    {
        public string Self { get; set;}
    }
    public class TranscriptionProperties
    {
        public bool DiarizationEnabled { get; set; }
        public bool WordLevelTimestampsEnabled { get; set; }
        public IEnumerable<int> Channels { get; set; }
        public PunctuationMode PunctuationMode { get; set; }
        public ProfanityFilterMode ProfanityFilterMode { get; set; }
        [JsonConverter(typeof(TimeSpanConverter))]
        public TimeSpan Duration { get; set; }
    }

    //Reference - https://westus.dev.cognitive.microsoft.com/docs/services/speech-to-text-api-v3-0/operations/GetTranscriptionFiles
    public class TranscriptionFiles {
        IEnumerable<TranscriptionFilesValues> Values { get; set; }
    }

    public class TranscriptionFilesValues 
    {
        public string Self;
        public DateTime CreatedDateTime { get; set; }
        public TranscriptionFilesLink Links { get; set; }
        public TranscriptionFilesProperties Properties { get; set; }
        public TranscriptionFileType Kind { get; set; }
    }

    public enum TranscriptionFileType 
    {
        DatasetReport,
        Audio,
        LanguageData,
        PronunciationData,
        AcousticDataArchive,
        AcousticDataTranscriptionV2,
        Transcription,
        TranscriptionReport,
        EvaluationDetails
    }

    public class TranscriptionFilesLink 
    {
        public string ContentUrl; 
    }

    public class TranscriptionFilesProperties 
    { 
        public long Size; 
    }
    
    //Reference - https://azure.microsoft.com/en-us/services/cognitive-services/
    public class TranscriptionResults
    {
        public string Source { get; set; }
        public DateTime Timestamp { get; set; }
        public long DurationInTicks { get; set; }
        [JsonConverter(typeof(TimeSpanConverter))]
        public TimeSpan Duration { get; set; }
        public IEnumerable<CombinedResults> CombinedRecognizedPhrases { get; set; }
        public IEnumerable<RecognitionResult> RecognizedPhrases { get; set; }
    }

    public class CombinedResults
    {
        public int Channel { get; set; }
        public string Lexical { get; set; }
        public string ITN { get; set; }
        public string MaskedITN { get; set; }
        public string Display { get; set; }
    }

    public class RecognitionResult
    {
        public string RecognitionStatus { get; set; }
        public int Channel { get; set; }
        public int? Speaker { get; set; }
        [JsonConverter(typeof(TimeSpanConverter))]
        public TimeSpan Offset { get; set; }
        [JsonConverter(typeof(TimeSpanConverter))]
        public TimeSpan Duration { get; set; }
        public long OffsetInTicks { get; set; }
        public long DurationInTicks { get; set; }
        public IEnumerable<NBest> NBest { get; set; }
    }

    public class NBest
    {
        public float Confidence { get; set; }
        public string Lexical { get; set; }
        public string ITN { get; set; }
        public string MaskedITN { get; set; }
        public string Display { get; set; }
        public IEnumerable<WordDetails> Words { get; set; }
    }

    public class WordDetails
    {
        public string Word { get; set; }
        [JsonConverter(typeof(TimeSpanConverter))]
        public TimeSpan Offset { get; set; }
        [JsonConverter(typeof(TimeSpanConverter))]
        public TimeSpan Duration { get; set; }
        public double OffsetInTicks { get; set; }
        public double DurationInTicks { get; set; }
        public float Confidence { get; set; }
    }
}
