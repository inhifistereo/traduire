[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,
  
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $SubscriptionName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $Uri,

    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $FrontEndUri,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [switch] $Upgrade
)

. .\modules\traduire_functions.ps1

Set-Variable -Name APP_RG_NAME          -Value ("{0}_app_rg" -f $AppName)        -Option Constant
Set-Variable -Name CORE_RG_NAME         -Value ("{0}_core_rg" -f $AppName)       -Option Constant
Set-Variable -Name APP_K8S_NAME         -Value ("{0}-aks01" -f $AppName)         -Option Constant
Set-Variable -Name APP_ACR_NAME         -Value ("{0}acr01" -f $AppName)          -Option Constant
Set-Variable -Name APP_KV_NAME          -Value ("{0}-kv01" -f $AppName)          -Option Constant
Set-Variable -Name APP_SA_NAME          -Value ("{0}files01" -f $AppName)        -Option Constant
Set-Variable -Name APP_MSI_NAME         -Value ("{0}-dapr-reader" -f $AppName)   -Option Constant
Set-Variable -Name APP_COGS_NAME        -Value ("{0}-cogs01" -f $AppName)        -Option Constant
Set-Variable -Name APP_AI_NAME          -Value ("{0}-ai01" -f $AppName)          -Option Constant
Set-Variable -Name KEDA_MSI_NAME        -Value ("{0}-keda-sb-owner" -f $AppName) -Option Constant
Set-Variable -Name KEDA_POD_BINDING     -Value "keda-podidentity"                -Option Constant

$root   = (Get-Item $PWD.Path).Parent.FullName
$source = Join-Path -Path $root -ChildPath "source"

#Start-Docker
#Start-Docker

#Connect to Azure and Log into ACR
#Connect-ToAzure -SubscriptionName $SubscriptionName
Add-AzureCliExtensions
Connect-ToAzureContainerRepo -ACRName $APP_ACR_NAME 

#Build Source
$commit_version = Get-GitCommitVersion
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/api:${commit_version}" -DockerFile "$source/dockerfile.api" -SourcePath $source
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/onstarted.handler:${commit_version}" -DockerFile "$source/dockerfile.onstarted" -SourcePath $source
Build-DockerContainers -ContainerName "${APP_ACR_NAME}.azurecr.io/traduire/onprocessing.handler:${commit_version}" -DockerFile "$source/dockerfile.onprocessing" -SourcePath $source
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
$app_msi  = New-MSIAccount -MSIName $APP_MSI_NAME -MSIResourceGroup $APP_RG_NAME
$keda_msi = New-MSIAccount -MSIName $KEDA_MSI_NAME -MSIResourceGroup $APP_RG_NAME

#Get Cognitive Services Info
$cogs = New-CognitiveServicesAccount -CogsAccountName $APP_COGS_NAME -CogsResourceGroup $APP_RG_NAME

# Install App
Write-Log -Message "Deploying Traduire"
helm upgrade -i `
   --set app_name=$AppName `
   --set msi_client_id=$($app_msi.client_id) `
   --set msi_resource_id=$($app_msi.resource_id) `
   --set keyvault_name=$APP_KV_NAME `
   --set storage_name=$APP_SA_NAME `
   --set acr_name=$APP_ACR_NAME `
   --set commit_version=$commit_version `
   --set cogs_region=$($cogs.region) `
   --set app_insights_key=$app_insights_key `
   --set kong_api_secret=$kong_api_secret `
   --set kong_api_uri=$Uri `
   --set keda_msi_client_id=$($keda_msi.client_id) `
   --set keda_msi_resource_id=$($keda_msi.resource_id) `
   --set frontend_uri=("https://{0}" -f $FrontEndUri) `
   traduire helm/. 

## TODO 
#* Federate K8S Service Accounts with AAD Identities

if($?){
    Write-Log ("Manually create DNS (A) Record: {0} - {1}" -f $uri, (Get-APIGatewayIP))
    Write-Log "API successfully deployed. Done"
}
else {
    Write-Log ("Errors encountered while deploying API. Please review. Application Name: {0}" -f $AppName )
} 
