param(
  [Parameter(Mandatory=$true)]
  [string] $AppName,

  [Parameter(Mandatory=$true)]
  [string] $region
)

Import-Module -Name bjd.Common.Functions

$today= (Get-Date).ToString("yyyyMMdd")
$uuid= New-Uuid

#Terraform Variables
$tfVarFileName = "variables.tfvars"
$tfPlanFileName = "{0}.plan.{1}-{2}" -f $AppName, $today, $uuid

#Resource Names
$acrAccountName = "{0}acr01" -f $appName
$appInsightsName = "{0}-ai01" -f $appName
$logAnalyticsWorkspace = "{0}-logs01" -f $appName
$vnetName = "{0}-vnet01" -f $appName 
$aks = "{0}-aks01" -f $appName
$mp3StorageAccountName = "{0}files01" -f $appName
$uiStorageAccountName = "{0}ui01" -f $appName
$postgresqlAccountName = "{0}-psql01" -f $appName
$serviceBusAccountName = "{0}-sb01" -f $appName
$keyVaultAccountName = "{0}-kv01" -f $appName

$public_ip = (Invoke-RestMethod http://checkip.amazonaws.com/).Trim()
$ssh_pub_key= (Get-Content -Path ~/.ssh/id_rsa.pub)

$configuration=@"
application_name = "$appName"
region = "$region"
postgresql_name = "$postgresqlAccountName"
acr_account_name = "$acrAccountName"
ai_account_name = "$appInsightsName"
loganalytics_account_name = "$logAnalyticsWorkspace"
vnet_name = "$vnetName"
aks_name = "$aks"
ui_storage_name = "$uiStorageAccountName"
mp3_storage_name = "$mp3StorageAccountName"
service_bus_namespace_name = "$serviceBusAccountName"
keyvault_name = "$keyVaultAccountName"
ssh_public_key = "$ssh_pub_key"
api_server_authorized_ip_ranges = "$public_ip/32"
"@
Set-Content -Value $configuration -Path ./terraform/$tfVarFileName -Encoding ascii

Set-Location ./terraform
#terraform init 
#terraform plan -out="$tfPlanFileName" -var-file="$tfVarFileName"
#terraform apply -auto-approve $tfPlanFileName

# echo Application name
if($?){
  Write-Host "------------------------------------"
  Write-Host ("Infrastructure built successfully. Application Name: {0}" -f $AppName)
  Write-Host "------------------------------------"
}
else {
  Write-Host "------------------------------------"
  Write-Host ("Errors encountered while building infrastructure. Please review. Application Name: {0}" -f $AppName )
  Write-Host "------------------------------------"
}
Set-Location ..