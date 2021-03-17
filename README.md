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
* ./deploy_application.ps1 -AppName $AppName -Subscription BJD_AZ_SUB01 -Uri api.bjd.tech [-upgrade] -verbose

### UI Deployment 
* TBD

## Validate 
_Temporary steps_
### Run UI
* Get Kong Service IP - kubectl get service kong-kong-proxy -o jsonpath={.status.loadBalancer.ingress[].ip}
* Get API Key  - kubectl get secret ${AppName}-apikey -o json | jq ".data.key" | tr -d "\"" | base64 -d
* cd source\ui\
* Update pages\Index.cshtml. Replace {{replaceme}} with Kong IP and API Key
* dotnet run --urls=http://localhost:5002/

### Browser 
* Launch UI
* Select assets\recording.m4a

## Backlog 
- [X] API exposed via Kong
- [X] Tracing with Dapr / OpenTelemetry / App Insights
- [X] Migrate Cognitive Services to Dapr Secure Store
- [X] API to display transcribed text
- [X] Additional Node Pool for AKS
- [X] Let's Encrypt 
- [ ] UX re-written in React (In-progress)
- [ ] ~~Port AKS, KeyVault, PostgreSQL, and Service Bus to GCP equivalents~~

