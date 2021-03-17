# Traduire
This my fork of [inhifistereo/traduire](https://github.com/inhifistereo/traduire).  I am using it to learn [Dapr](https://dapr.io) patterns and practices. 

**Note**: It is known that the use of Dapr is overkill for this app (see [client example](./sample/cognitiveservices.test)). 

## App Overview 
The application uses Azure Cognitive Services to transcribe Podcasts in MP3 format to text.

## Data Flow
![Flow](./assets/flow_diagram.png)

## Dapr Components
![Dapr](./assets/dapr.png)

## Deployment
### Prerequisite
* A Linux machine or Windows Subsytem for Linux or Docker for Windows 
* PowerShell 7
* Azure Cli and an Azure Subscription
* Terraform 0.12 or greater
* Kubectl
* Helm 3 or greater
* Docker 

### Infrastructure 
* pwsh
* cd ./Infrastructure
* $AppName = "trad{0}" -f (New-Guid).ToString('N').Substring(0,4)
* ./create_infrastructure.ps1 -AppName $AppName -Subscription BJD_AZ_SUB01 -Region southcentralus

### Application Deployment 
* pwsh
* cd ./Deploy
* ./deploy_application.ps1 -AppName $AppName -Subscription BJD_AZ_SUB01 -verbose

### UI Deployment 
* pwsh
* cd ./Deploy
* ./deploy_ui.ps1 -AppName $AppName -ApiUri api.bjd.tech -Verbose

### Validate
* Launch Browser
* Navigate to https://{$AppName}.z21.web.core.windows.net/
* Select assets\recording.m4a and upload the test file

## Backlog 
- [X] API exposed via Kong
- [X] Tracing with Dapr / OpenTelemetry / App Insights
- [X] Migrate Cognitive Services to Dapr Secure Store
- [X] API to display transcribed text
- [ ] UX re-written in React 
- [ ] Port AKS, KeyVault, PostgreSQL, and Service Bus to GCP equivalents  

