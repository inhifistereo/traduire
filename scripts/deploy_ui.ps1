[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $SubscriptionName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [string] $DomainName
)

. ./modules/traduire_functions.ps1
. ./modules/traduire_naming.ps1

Set-Location -Path $UI_SOURCE_DIR

#Write-Log -Message "Logging into Azure"
Add-AzureCliExtensions

#Get AKS Credential file
Get-AKSCredentials -AKSName $APP_K8S_NAME -AKSResourceGroup $APP_RG_NAME

Write-Log -Message "Getting API Gateway Secret"
$kong_api_key = Get-KubernetesSecret -secret ("{0}-apikey" -f $AppName) -value "key" -namespace $APP_NAMESPACE

Write-Log -Message "Getting Web PubSub AccessKey"
$pubsub_key = Get-WebPubSubAccessKey -PubSubName $APP_PUBSUB_NAME -ResourceGroup $APP_UI_RG

Write-Log -Message "Setting Reactjs Environment File"
Set-ReactEnvironmentFile -Path "configs/config.json.template" -OutPath "configs/config.json" -Uri $APP_FE_URI -Key $kong_api_key -WebPubSubUri $APP_PUBSUB_NAME  -WebPubSubKey $pubsub_key

Write-Log -Message "Building UI Code"
Start-UiBuild

Write-Log -Message "Deploying to Azure Static Web Site"
Deploy-toAzStaticWebApp -Name $APP_UI_NAME -ResourceGroup $APP_UI_RG -LocalPath (Join-Path -Path $UI_SOURCE_DIR -ChildPath "build")

Set-Location -Path $cwd