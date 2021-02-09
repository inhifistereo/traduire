using System; 
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.WebUtilities;
using System.Text.Encodings.Web;
using Dapr;
using Dapr.Client;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace TraduireAPi.Controllers
{ 
    [Route("api/{controller}")]
    [ApiController]
    public class UploadController : ControllerBase
    {
        private readonly string BlobStoreName = Environment.GetEnvironmentVariable("DAPR_BLOB_STORE_NAME", EnvironmentVariableTarget.Process);

        private readonly ILogger _logger;

        public UploadController(ILogger<UploadController> logger)
        {
            _logger = logger;
        }

        [HttpPost]
        public async Task<ActionResult<Guid>> Post(IFormFile file, CancellationToken cancellationToken, [FromServices] DaprClient daprClient)
        {
            try{
                var id = Guid.NewGuid().ToString();
                
                var metadata = new Dictionary<string, string>();
                metadata.Add("blobName", WebUtility.HtmlEncode(file.FileName));
                metadata.Add("Custom", id);

                await daprClient.InvokeBindingAsync(BlobStoreName, "create",  await ConvertFileToBase64Encoding(file), metadata, cancellationToken);                      
                
                _logger.LogInformation($"{id} was successfullly as {file.FileName}");
                return Ok(id); 
            }
            catch( Exception ex ) {
                _logger.LogWarning($"Failed to create {file.FileName} - {ex.Message}");
            }

            return Ok(null);
        }

        private async Task<string> ConvertFileToBase64Encoding( IFormFile f )
        {          
            try
            {
                using (var memoryStream = new MemoryStream())
                {
                    await f.CopyToAsync(memoryStream);
                    return Convert.ToBase64String(memoryStream.ToArray());
                }            
            }
            catch{}

            return String.Empty;
        }
    }
}