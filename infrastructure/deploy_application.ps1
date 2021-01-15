param(
    [Parameter(Mandatory=$true)]
    [string] $AppName,
  
    [Parameter(Mandatory=$true)]
    [string] $SubscriptionName
)
Import-Module bjd.Common.Functions

function Get-GitBranchRevision
{
    return (git rev-parse HEAD).Substring(0,8)
}

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

Set-Variable -Name DAPR_VERSION -Value "1.0.0-rc.2" -Option Constant
Set-Variable -Name KEDA_VERSION -Value "1.5.0" -Option Constant
Set-Variable -Name APP_RG_NAME  -Value ("{0}_app_rg" -f $AppName)   -Option Constant
Set-Variable -Name APP_K8S_NAME -Value ("{0}-aks01" -f $AppName)    -Option Constant
Set-Variable -Name APP_ACR_NAME -Value ("{0}acr01" -f $AppName)     -Option Constant

Start-Docker
Connect-Azure

#Set Subscription and login into ACR
az acr login -n $APP_ACR_NAME

#Get AKS Credential file
az aks get-credentials -n $APP_K8S_NAME -g $APP_RG_NAME

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
helm upgrade -i dapr dapr/dapr --namespace dapr-system --version $DAPR_VERSION

# Install Pod Identity 
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm repo update
helm upgrade -i aad-pod-identity aad-pod-identity/aad-pod-identity

# Install App
# helm upgrade --install --set key=value traduire .