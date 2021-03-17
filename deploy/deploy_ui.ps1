[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [string] $ApiUri
)

function Write-Log 
{
    param( [string] $Message )
    Write-Verbose -Message ("[{0}] - {1} ..." -f $(Get-Date), $Message)
}

function ConvertFrom-Base64String($Text)
{
    return [Text.Encoding]::ASCII.GetString([convert]::FromBase64String($Text))
}

function Get-KubernetesSecret
{
    param(
        [string] $secret,
        [string] $value
    )

    $encoded_key = kubectl get secret $secret -o json | ConvertFrom-Json
    return ConvertFrom-Base64String($encoded_key.data.$value)
}

function Connect-ToAzure
{
    param(
        [string] $SubscriptionName
    )

    az account show 
    if(!$?) {
        az login
    }
}


function Start-UiBuild
{   
    npm install
    yarn build
}

function Copy-BuildToStorage
{
    param(
        [string] $StorageAccount,
        [string] $Container = "`$web",
        [string] $LocalPath
    )

    function Add-Quotes {
        begin {
            $quotedText = [string]::empty
        }
        process {
            $quotedText = "`"{0}`"" -f $_
        }
        end {
            return $quotedText
        }
    }

    $source = ("{0}/*" -f $LocalPath) | Add-Quotes 
    az storage copy --source-local-path $source --destination-account-name $StorageAccount --destination-container $Container --recursive --put-md5

}

function Set-ReactEnvironmentFile
{
    param(
        [string] $Path = ".env.template",
        [string] $OutPath = ".env",
        [string] $Uri,
        [string] $Key
    )

    (Get-Content -Path $Path -Raw).Replace("{{uri}}", $Uri).Replace("{{apikey}}", $Key) | 
        Set-Content -Path $OutPath -Encoding ascii

}

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
Set-ReactEnvironmentFile -Path ".env.template" -OutPath ".env" -Uri $ApiUri -Key $kong_api_key

Write-Log -Message "Building UI Code"
Start-UiBuild

Write-Log -Message "Uploading Files to ${APP_UI_NAME}"
Copy-BuildToStorage -StorageAccount $APP_UI_NAME -LocalPath (Join-Path -Path $ui_source_dir -ChildPath "build")

Set-Location -Path $cwd