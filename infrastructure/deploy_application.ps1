param(
    [Parameter(Mandatory=$true)]
    [string] $AppName,
  
    [Parameter(Mandatory=$true)]
    [string] $SubscriptionName
)
Import-Module bjd.Common.Functions

function Start-Docker
{
    if(Get-OSType -eq "Unix") {
        sudo /etc/init.d/docker start
    }
    else {
        Start-Service -Name docker
    }
}

function Connect-Azure
{
    az account show 
    if(!$?) {
        az login
    }
    az account set -s $SubscriptionName -o none
}

Set-Variable -Name DAPR_VERSION -Value "1.0.0-rc.2"                     -Option Constant
Set-Variable -Name KEDA_VERSION -Value "1.5.0"                          -Option Constant
Set-Variable -Name APP_RG_NAME  -Value ("{0}_app_rg" -f $AppName)       -Option Constant
Set-Variable -Name APP_K8S_NAME -Value ("{0}-aks01" -f $AppName)        -Option Constant
Set-Variable -Name APP_ACR_NAME -Value ("{0}acr01" -f $AppName)         -Option Constant
Set-Variable -Name APP_KV_NAME  -Value ("{0}-kv01" -f $AppName)         -Option Constant
Set-Variable -Name APP_MSI_NAME -Value ("{0}-dapr-reader" -f $AppName)  -Option Constant

$cwd = $PWD.Path
Set-location -Path ..\deploy

#Start-Docker
Connect-Azure

#Set Subscription and login into ACR
az acr login -n $APP_ACR_NAME

#Get AKS Credential file
az aks get-credentials -n $APP_K8S_NAME -g $APP_RG_NAME

#Get MSI Account
$ms_resource_id = az identity show -n $APP_MSI_NAME -g $APP_RG_NAME --query id -o tsv
$ms_client_id = az identity show -n $APP_MSI_NAME -g $APP_RG_NAME --query clientId -o tsv

#Get Service Bus Connection String
#TBC

#Set Key Vault Secret for Connection Strings
#TBC

# Install Traefik Ingress 
helm repo add traefik https://helm.traefik.io/traefik    
helm upgrade -i traefik traefik/traefik -f  ../Infrastructure/traefik/values.yaml --wait
         
# Install Keda
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
kubectl create namespace keda
helm upgrade -i keda kedacore/keda --namespace keda --version $KEDA_VERSION

# Install Dapr
helm repo add dapr https://dapr.github.io/helm-charts
helm repo update
kubectl create namespace dapr-system
helm upgrade -i dapr dapr/dapr --namespace dapr-system --version $DAPR_VERSION --set global.logAsJson=true --set global.ha.enabled=true --wait

#Due to https://github.com/dapr/dapr/issues/1621#
kubectl -n dapr-system rollout restart deployment dapr-sidecar-injector

# Install Pod Identity 
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm repo update
helm upgrade -i aad-pod-identity aad-pod-identity/aad-pod-identity

# Install App
helm upgrade -i `
   --set app_name=$AppName `
   --set msi_client_id=$ms_client_id `
   --set msi_resource_id=$ms_resource_id `
   --set keyvault_name=$APP_KV_NAME `
   traduire . 

#Testing from within utils containers
#Invoke-RestMethod -Method Post -Uri "http://localhost:3500/v1.0/bindings/vxzjl-servicebus" -Body '{ "data": { "message": "bye" }, "operation": "create" }'
#Invoke-RestMethod -Uri "http://localhost:3500/v1.0/secrets/vxzjl-vault"

Set-location -Path $cwd