[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,
  
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $SubscriptionName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [string] $Uri,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [switch] $Upgrade
)

function New-APISecret 
{
    param( 
        [string] $Length = 20
    )
    
    [System.Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((New-Guid).ToString('N').Substring(0,$Length)))
}

function Write-Log 
{
    param( [string] $Message )
    Write-Verbose -Message ("[{0}] - {1} ..." -f $(Get-Date), $Message)
}

function Start-Docker
{
    Write-Log -Message "Starting Docker"
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

    Write-Log -Message "Logging into Azure"
    az account show 
    if(!$?) {
        az login
    }
    az account set -s $SubscriptionName -o none

    Write-Log -Message "Logging into ${ACRName} Azure Container Repo"
    az acr login -n $ACRName
}

function Get-AKSCredentials 
{
    param(
        [string] $AKSNAME,
        [string] $AKSResourceGroup
    )

    Write-Log -Message "Get ${AKSNAME} AKS Credentials"
    az aks get-credentials -n $AKSNAME -g $AKSResourceGroup
}

function Get-APIGatewayIP 
{
    function Test-IPAddress($IP) { return ($IP -as [IPAddress] -as [Bool]) }

    $ip = (kubectl -n kong-gateway get service kong-kong-proxy -o jsonpath=`{.status.loadBalancer.ingress[].ip`})

    if( (Test-IPAddress -IP $ip) ) { return $ip }
    return [string]::Empty
}

function New-MSIAccount 
{
    param(
        [string] $MSIName,
        [string] $MSIResourceGroup
    )

    Write-Log -Message "Get ${MSIName} Manage Identity properties"
    return (New-Object psobject -Property @{
        client_id = (az identity show -n $MSIName -g $MSIResourceGroup --query clientId -o tsv)
        resource_id = (az identity show -n $MSIName -g $MSIResourceGroup --query id -o tsv)
    })
}

function New-CognitiveServicesAccount 
{
    param(
        [string] $CogsAccountName,
        [string] $CogsResourceGroup
    )

    Write-Log -Message "Get ${CogsAccountName} Cognitive Services Account properties"
    return (New-Object psobject -Property @{
        region = (az cognitiveservices account show -n $CogsAccountName -g $CogsResourceGroup -o tsv --query location)
        key = (ConvertTo-Base64EncodedString (az cognitiveservices account keys list -n $CogsAccountName -g $CogsResourceGroup -o tsv --query key1))
    })
}

function Get-GitCommitVersion
{
    Write-Log -Message "Get Latest Git commit version id"
    return (git rev-parse HEAD).SubString(0,8)
}

function Build-DockerContainers
{
    param(
        [string] $ContainerName,
        [string] $DockerFile,
        [string] $SourcePath
    )

    Write-Log -Message "Building ${ContainerName}"
    docker build -t $ContainerName -f $DockerFile $SourcePath

    Write-Log -Message "Pushing ${ContainerName}"
    docker push $ContainerName
}

Set-Variable -Name DAPR_VERSION     -Value "1.0.0"                          -Option Constant
Set-Variable -Name KEDA_VERSION     -Value "2.1.1"                          -Option Constant
Set-Variable -Name APP_RG_NAME      -Value ("{0}_app_rg" -f $AppName)       -Option Constant
Set-Variable -Name CORE_RG_NAME     -Value ("{0}_core_rg" -f $AppName)      -Option Constant
Set-Variable -Name APP_K8S_NAME     -Value ("{0}-aks01" -f $AppName)        -Option Constant
Set-Variable -Name APP_ACR_NAME     -Value ("{0}acr01" -f $AppName)         -Option Constant
Set-Variable -Name APP_KV_NAME      -Value ("{0}-kv01" -f $AppName)         -Option Constant
Set-Variable -Name APP_SA_NAME      -Value ("{0}files01" -f $AppName)       -Option Constant
Set-Variable -Name APP_MSI_NAME     -Value ("{0}-dapr-reader" -f $AppName)  -Option Constant
Set-Variable -Name APP_COGS_NAME    -Value ("{0}-cogs01" -f $AppName)       -Option Constant
Set-Variable -Name APP_AI_NAME      -Value ("{0}-ai01" -f $AppName)         -Option Constant

$root   = (Get-Item $PWD.Path).Parent.FullName
$source = Join-Path -Path $root -ChildPath "source"

#Start-Docker
Start-Docker

#Connect to Azure and Log into ACR
Connect-ToAzureContainerRepo -ACRName $APP_ACR_NAME -SubscriptionName $SubscriptionName

#Build Source
$commit_version = Get-GitCommitVersion
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/api:${commit_version}" -DockerFile "$source/dockerfile.api" -SourcePath $source
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/onstarted.handler:${commit_version}" -DockerFile "$source/dockerfile.onstarted" -SourcePath $source
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/onpending.handler:${commit_version}" -DockerFile "$source/dockerfile.onpending" -SourcePath $source
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/oncompletion.handler:${commit_version}" -DockerFile "$source/dockerfile.oncompletion" -SourcePath $source

if($Upgrade) {
    Write-Log -Message "Upgrading Traduire to ${commit_version}"
    helm upgrade traduire helm/. --reuse-values --set commit_version=$commit_version 

    if($?){
        Write-Log ("Review DNS (A) Record: {0} - {1}" -f $uri, (Get-APIGatewayIP))
        Write-Log "API successfully updated. Done"
        return 0
    }
    return -1
}

#Get AKS Credential file
Get-AKSCredentials -AKSName $APP_K8S_NAME -AKSResourceGroup $APP_RG_NAME

#Generate Kong API secret
$kong_api_secret = New-APISecret -Length 25

#Get App Insights Key
$app_insights_key = (az monitor app-insights component show --app $APP_AI_NAME -g $CORE_RG_NAME --query instrumentationKey -o tsv)

#Get MSI Account Info
$msi = New-MSIAccount -MSIName $APP_MSI_NAME -MSIResourceGroup $APP_RG_NAME

#Get Cognitive Services Info
$cogs = New-CognitiveServicesAccount -CogsAccountName $APP_COGS_NAME -CogsResourceGroup $APP_RG_NAME

# Install Kong API Gateway 
Write-Log -Message "Deploying Kong API Gateway"
helm repo add kong https://charts.konghq.com
helm repo update        
kubectl create namespace kong-gateway
helm upgrade -i kong kong/kong --namespace kong-gateway --set ingressController.installCRDs=false
 
# Install Keda
Write-Log -Message "Deploying Keda"
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
kubectl create namespace keda
helm upgrade -i keda kedacore/keda --namespace keda --version $KEDA_VERSION

# Install Dapr
Write-Log -Message "Deploying Dapr"
helm repo add dapr https://dapr.github.io/helm-charts
helm repo update
kubectl create namespace dapr-system
helm upgrade -i dapr dapr/dapr --namespace dapr-system --version $DAPR_VERSION --set global.logAsJson=true --set global.ha.enabled=true --wait

#Due to https://github.com/dapr/dapr/issues/1621#
#kubectl -n dapr-system rollout restart deployment dapr-sidecar-injector

# Install Pod Identity 
Write-Log -Message "Deploying Pod Identity"
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm repo update
helm upgrade -i aad-pod-identity aad-pod-identity/aad-pod-identity

# Install Cert Manager
Write-Log -Message "Deploying Let's Encrypt Cert Manager"
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
helm upgrade -i cert-manager jetstack/cert-manager  --namespace cert-manager  --version v1.2.0  --set installCRDs=true

# Install App
Write-Log -Message "Deploying Traduire"
helm upgrade -i `
   --set app_name=$AppName `
   --set msi_client_id=$($msi.client_id) `
   --set msi_resource_id=$($msi.resource_id) `
   --set keyvault_name=$APP_KV_NAME `
   --set storage_name=$APP_SA_NAME `
   --set acr_name=$APP_ACR_NAME `
   --set commit_version=$commit_version `
   --set cogs_region=$($cogs.region) `
   --set app_insights_key=$app_insights_key `
   --set kong_api_secret=$kong_api_secret `
   --set kong_api_uri=$Uri `
   traduire helm/. 

if($?){
    Write-Log ("Manually create DNS (A) Record: {0} - {1}" -f $uri, (Get-APIGatewayIP))
    Write-Log "API successfully deployed. Done"
}
else {
    Write-Log ("Errors encountered while deploying API. Please review. Application Name: {0}" -f $AppName )
} 
