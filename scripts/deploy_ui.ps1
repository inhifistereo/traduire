[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $SubscriptionName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [string] $ApiUri
)

. .\modules\traduire_functions.ps1

Set-Variable -Name APP_UI_NAME      -Value ("{0}-ui" -f $AppName)         -Option Constant
Set-Variable -Name APP_UI_RG        -Value ("{0}_ui_rg" -f $AppName)       -Option Constant
Set-Variable -Name APP_PUBSUB_NAME  -Value ("{0}-pubsub" -f $AppName)    -Option Constant
Set-Variable -Name APP_RG_NAME      -Value ("{0}_app_rg" -f $AppName)      -Option Constant
Set-Variable -Name APP_K8S_NAME     -Value ("{0}-aks" -f $AppName)       -Option Constant

Set-Variable -Name cwd              -Value $PWD.Path
Set-Variable -Name root             -Value (Get-Item $PWD.Path).Parent.FullName
Set-Variable -Name ui_source_dir    -Value (Join-Path -Path $root -ChildPath "src\ui")

Set-Location -Path $ui_source_dir

#Write-Log -Message "Logging into Azure"
Add-AzureCliExtensions

#Get AKS Credential file
Get-AKSCredentials -AKSName $APP_K8S_NAME -AKSResourceGroup $APP_RG_NAME

Write-Log -Message "Getting API Gateway Secret"
$kong_api_key = Get-KubernetesSecret -secret ("{0}-apikey" -f $AppName) -value "key"

Write-Log -Message "Getting Web PubSub AccessKey"
$pubsub_key = Get-WebPubSubAccessKey -PubSubName $APP_PUBSUB_NAME -ResourceGroup $APP_UI_RG

Write-Log -Message "Setting Reactjs Environment File"
Set-ReactEnvironmentFile -Path "src\config.json.template" -OutPath "src\config.json" -Uri $ApiUri -Key $kong_api_key -WebPubSubUri $APP_PUBSUB_NAME  -WebPubSubKey $pubsub_key

Write-Log -Message "Building UI Code"
Start-UiBuild

Write-Log -Message "Deploying to Azure Static Web Site"
Deploy-toAzStaticWebApp -Name $APP_UI_NAME -ResourceGroup $APP_UI_RG -LocalPath (Join-Path -Path $ui_source_dir -ChildPath "build")

Set-Location -Path $cwd