function Write-Log 
{
    param( [string] $Message )
    Write-Verbose -Message ("[{0}] - {1} ..." -f $(Get-Date), $Message)
}

function ConvertFrom-Base64String($Text)
{
    return [Text.Encoding]::ASCII.GetString([convert]::FromBase64String($Text))
}

function ConvertTo-Base64EncodedString {
    param( 
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Text 
    )
    begin {
        $encodedString = [string]::Empty
    }
    process {
        $encodedString = [convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($Text))
    }
    end{
        return $encodedString
    }
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
    az storage copy --source $source --account-name $StorageAccount --destination-container $Container --recursive --put-md5

}

function Add-AzureCliExtensions
{
    az extension add --name application-insights -y
    az extension add --name aks-preview -y
}

function Get-AzStaticWebAppSecret
{
    param(
        [string] $Name,
        [string] $ResourceGroup
    )

    $id =$(az staticwebapp show -g $ResourceGroup -n $Name -o tsv --query id)
    return $(az rest --method post --url "$id/listsecrets?api-version=2020-06-01" --query properties.apiKey -o tsv)
}

function Get-WebPubSubAccessKey 
{
    param(
        [string] $PubSubName,
        [string] $ResourceGroup
    )
    return $(az webpubsub key show -n $PubSubName -g $ResourceGroup -o tsv --query primaryKey)
}

function Deploy-toAzStaticWebApp
{
    param(
        [string] $Name,
        [string] $ResourceGroup,
        [string] $LocalPath
    )

    $token = Get-AzStaticWebAppSecret -Name $Name -ResourceGroup $ResourceGroup

    docker run --entrypoint "/bin/staticsites/StaticSitesClient" `
        --volume ${LocalPath}:/root/build `
        mcr.microsoft.com/appsvc/staticappsclient:stable `
        upload `
        --skipAppBuild true `
        --app /root/build `
        --apiToken $token
}

function Set-ReactEnvironmentFile
{
    param(
        [string] $Path = ".env.template",
        [string] $OutPath = ".env",
        [string] $Uri,
        [string] $Key,
        [string] $WebPubSubUri,
        [string] $WebPubSubKey
    )

    (Get-Content -Path $Path -Raw).Replace("{{uri}}", $Uri).Replace("{{apikey}}", $Key).Replace("{{pubsub_uri}}", $WebPubSubUri).Replace("{{pubsub_key}}", $WebPubSubKey) |
    Set-Content -Path $OutPath -Encoding ascii
}

function New-APISecret 
{
    param( 
        [string] $Length = 20
    )
    
    [System.Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((New-Guid).ToString('N').Substring(0,$Length)))
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

function Connect-ToAzure 
{
    param(
        [string] $SubscriptionName
    )

    function Get-AzTokenExpiration {
        $e = (az account get-access-token --query "expiresOn" --output tsv)
        if($null -eq $e){
            return $null
        }        
        return (Get-Date -Date $e)
    }

    function Test-ExpireToken {
        param(
            [DateTime] $Expire
        )
        return (($exp - (Get-Date)).Ticks -lt 0 )
    }

    $exp = Get-AzTokenExpiration
    if( ($null -eq $exp) -or (Test-ExpireToken -Expire $exp)) {
        Write-Log -Message "Logging into Azure"
        az login
    }

    Write-Log -Message "Setting subscription context to ${SubscriptionName}"
    az account set -s $SubscriptionName
    
}

function Connect-ToAzureContainerRepo
{
    param(
        [string] $ACRName

    )

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

function  Add-IPtoAksAllowedRange 
{
    param(
        [string] $IP,
        [string] $AKSCluster,
        [string] $ResourceGroup
    )

    $range = @(az aks show -n $AKSCluster -g $ResourceGroup --query apiServerAccessProfile.authorizedIpRanges -o tsv)
    $range += $IP
    
    return ([string]::Join(',', $range))
}
