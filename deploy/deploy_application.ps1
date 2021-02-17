param(
    [Parameter(Mandatory=$true)]
    [string] $AppName,
  
    [Parameter(Mandatory=$true)]
    [string] $SubscriptionName
)
function Start-Docker
{
    if(Get-OSType -eq "Unix") {
        sudo /etc/init.d/docker start
    }
    else {
        Start-Service -Name docker
    }
}

function Connect-ToAzureContainerRepo
{
    param(
        [string] $ACRName,
        [string] $SubscriptionName
    )
    az account show 
    if(!$?) {
        az login
    }
    az account set -s $SubscriptionName -o none
    az acr login -n $ACRName
}

function Get-AKSCredentials 
{
    param(
        [string] $AKSNAME,
        [string] $AKSResourceGroup
    )

    az aks get-credentials -n $AKSNAME -g $AKSResourceGroup
}

function New-MSIAccount 
{
    param(
        [string] $MSIName,
        [string] $MSMSIResourceGroup
    )

    return (New-Object psobject -Property @{
        client_id = (az identity show -n $MSIName -g $MSMSIResourceGroup --query clientId -o tsv)
        resource_id = (az identity show -n $MSIName -g $MSMSIResourceGroup --query id -o tsv)
    })
}

function New-CognitiveServicesAccount 
{
    param(
        [string] $CogsAccountName,
        [string] $CogsResourceGroup
    )

    return (New-Object psobject -Property @{
        region = (az cognitiveservices account show -n $CogsAccountName -g $CogsResourceGroup -o tsv --query location)
        key = (ConvertTo-Base64EncodedString (az cognitiveservices account keys list -n $CogsAccountName -g $CogsResourceGroup -o tsv --query key1))
    })
}

function Get-GitCommitVersion
{
    return (git rev-parse HEAD).SubString(0,8)
}

function Build-DockerContainers
{
    param(
        [string] $ContainerName,
        [string] $DockerFile,
        [string] $SourcePath
    )

    docker build -t $ContainerName -f $DockerFile $SourcePath
    docker push $ContainerName
}

Set-Variable -Name DAPR_VERSION     -Value "1.0.0-rc.3"                     -Option Constant
Set-Variable -Name KEDA_VERSION     -Value "1.5.0"                          -Option Constant
Set-Variable -Name APP_RG_NAME      -Value ("{0}_app_rg" -f $AppName)       -Option Constant
Set-Variable -Name APP_K8S_NAME     -Value ("{0}-aks01" -f $AppName)        -Option Constant
Set-Variable -Name APP_ACR_NAME     -Value ("{0}acr01" -f $AppName)         -Option Constant
Set-Variable -Name APP_KV_NAME      -Value ("{0}-kv01" -f $AppName)         -Option Constant
Set-Variable -Name APP_SA_NAME      -Value ("{0}files01" -f $AppName)       -Option Constant
Set-Variable -Name APP_MSI_NAME     -Value ("{0}-dapr-reader" -f $AppName)  -Option Constant
Set-Variable -Name APP_COGS_NAME    -Value ("{0}-cogs01" -f $AppName)       -Option Constant

Import-Module bjd.Common.Functions

$root   = (Get-Item $PWD.Path).Parent.FullName
$source = Join-Path -Path $root -ChildPath "source"

#Start-Docker
Start-Docker

#Connect to Azure and Log into ACR
Connect-ToAzureContainerRepo -ACRName $APP_ACR_NAME -SubscriptionName $SubscriptionName

#Get AKS Credential file
Get-AKSCredentials -AKSName $APP_K8S_NAME -AKSResourceGroup $APP_RG_NAME

#Get MSI Account Info
$msi = New-MSIAccount -MSIName $APP_MSI_NAME -MSIResourceGroup $APP_RG_NAME

#Get Cognitive Services Info
$cogs = New-CognitiveServicesAccount -CogsAccountName $APP_COGS_NAME -CogsResourceGroup $APP_RG_NAME

#Build Source
$commit_version = Get-GitCommitVersion
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/api:${commit_version}" -DockerFile "$source/dockerfile.api" -SourcePath $source
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/onstarted.handler:${commit_version}" -DockerFile "$source/dockerfile.onstarted" -SourcePath $source
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/onpending.handler:${commit_version}" -DockerFile "$source/dockerfile.onpending" -SourcePath $source
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/oncompletion.handler:${commit_version}" -DockerFile "$source/dockerfile.oncompletion" -SourcePath $source

# Install Traefik Ingress 
helm repo add traefik https://helm.traefik.io/traefik    
helm upgrade -i traefik traefik/traefik -f ./traefik/values.yaml --wait
         
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
#kubectl -n dapr-system rollout restart deployment dapr-sidecar-injector

# Install Pod Identity 
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm repo update
helm upgrade -i aad-pod-identity aad-pod-identity/aad-pod-identity

# Install App
helm upgrade -i `
   --set app_name=$AppName `
   --set msi_client_id=$msi.client_id `
   --set msi_resource_id=$msi.resource_id `
   --set keyvault_name=$APP_KV_NAME `
   --set storage_name=$APP_SA_NAME `
   --set acr_name=$APP_ACR_NAME `
   --set commit_version=$commit_version `
   --set cogs_region=$cogs.region `
   --set cogs_key=$cogs.key `
   traduire helm/. 