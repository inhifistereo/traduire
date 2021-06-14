[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [string] $ApiUri
)

. .\modules\traduire_functions.ps1

Set-Variable -Name APP_UI_NAME      -Value ("{0}ui01" -f $AppName)         -Option Constant
Set-Variable -Name APP_UI_RG        -Value ("{0}_ui_rg" -f $AppName)       -Option Constant

Set-Variable -Name cwd              -Value $PWD.Path
Set-Variable -Name root             -Value (Get-Item $PWD.Path).Parent.FullName
Set-Variable -Name ui_source_dir    -Value (Join-Path -Path $root -ChildPath "source\ui")

Set-Location -Path $ui_source_dir

Write-Log -Message "Logging into Azure"
Connect-ToAzure

Write-Log -Message "Getting API Gateway Secret"
$kong_api_key = Get-KubernetesSecret -secret ("{0}-apikey" -f $AppName) -value "key"

Write-Log -Message "Setting Reactjs Environment File"
Set-ReactEnvironmentFile -Path "src\config.json.template" -OutPath "src\config.json" -Uri $ApiUri -Key $kong_api_key

Write-Log -Message "Building UI Code"
Start-UiBuild

Write-Log -Message "Uploading Files to ${APP_UI_NAME}"
Copy-BuildToStorage -StorageAccount $APP_UI_NAME -LocalPath (Join-Path -Path $ui_source_dir -ChildPath "build")

Write-Log -Message "Deploying to Azure Static Web Site"
Deploy-toAzStaticWebApp -Name $APP_UI_NAME -ResourceGroup $APP_UI_RG -LocalPath (Join-Path -Path $ui_source_dir -ChildPath "build")

Set-Location Path $cwd