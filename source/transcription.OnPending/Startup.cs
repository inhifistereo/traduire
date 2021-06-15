using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Azure.Messaging.WebPubSub; 

using transcription.models;
using transcription.common.cognitiveservices;

namespace transcription.status
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddCors(options =>
            {
                options.AddDefaultPolicy(
                    builder =>
                    {
                        builder.WithOrigins("*");
                    });
            });

            services.AddControllers();

            var region = Environment.GetEnvironmentVariable("AZURE_COGS_REGION");
            var cogs = new AzureCognitiveServicesClient( Configuration[Components.SecretName], region);
            services.AddSingleton<AzureCognitiveServicesClient>(cogs);

            var pubsub = Environment.GetEnvironmentVariable("AZURE_PUBSUB_ENDPONT");
            var serviceClient = new WebPubSubServiceClient(new Uri(pubsub), Components.PubSubHubName, new AzureKeyCredential(Configuration[Components.PubSubSecretName]));
            services.AddSingleton<WebPubSubServiceClient>(serviceClient);
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseCors();
            app.UseCloudEvents();
            app.UseRouting();
            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapSubscribeHandler();
                endpoints.MapControllers();
            });
        }
    }
}
