[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,
  
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $SubscriptionName
)

. .\modules\traduire_functions.ps1

Set-Variable -Name APP_RG_NAME      -Value ("{0}_app_rg" -f $AppName)        -Option Constant
Set-Variable -Name APP_K8S_NAME     -Value ("{0}-aks01" -f $AppName)         -Option Constant
Set-Variable -Name APP_ACR_NAME     -Value ("{0}acr01" -f $AppName)          -Option Constant

#Connect to Azure and Log into ACR
Connect-ToAzure -SubscriptionName $SubscriptionName

$public_ip = (Invoke-RestMethod http://checkip.amazonaws.com/).Trim()

$ip_ranges = Add-IPtoAksAllowedRange -IP $public_ip -AKSCluster $APP_K8S_NAME -ResourceGroup $APP_RG_NAME

Write-Log -Message "Adding ${public_ip} to ${APP_ACR_NAME}"
az acr network-rule add -n $APP_ACR_NAME --ip-address $public_ip

Write-Log -Message "Adding ${public_ip} to ${APP_K8S_NAME}"
az aks update -n $APP_K8S_NAME -g $APP_RG_NAME --api-server-authorized-ip-ranges $ip_ranges