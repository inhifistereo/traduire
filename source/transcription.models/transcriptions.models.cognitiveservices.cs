using System;
using System.Collections.Generic;

namespace transcription.models {
    public class AzureCognitiveServicesTextToSpeechRequest
    {
        public List<string> ContentUrls { get; set; }
        public string DisplayName { get; set; }
        public AzureCognitiveServicesTextToSpeechProperties Properties { get; set; }
        public string Locale { get; set; }
        
        public AzureCognitiveServicesTextToSpeechRequest()
        {
            ContentUrls = new List<string>();
            Properties = new AzureCognitiveServicesTextToSpeechProperties();
        }
    }

    public class AzureCognitiveServicesTextToSpeechProperties 
    {
        public bool DiarizationEnabled { get; set; } = false; 
        public bool WordLevelTimestampsEnabled { get; set; } = false; 
        public string PunctuationMode { get; set; } = "DictatedAndAutomatic";
        public string ProfanityFilterMode { get; set;} = "Masked";
    }
}
