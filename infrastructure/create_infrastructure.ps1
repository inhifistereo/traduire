param(
  [Parameter(Mandatory=$true)]
  [string] $SubscriptionName,

  [Parameter(Mandatory=$true)]
  [string] $region
)

$today = (Get-Date).ToString("yyyyMMdd")

az account set -s $SubscriptionName

#$tenantId = (az account show --query "tenantId" -o tsv)
$tfPlanFileName = "{0}.plan.{1}" -f $AppName, $today

terraform -chdir=./infrastructure init
terraform -chdir=./infrastructure plan -out="$tfPlanFileName" -var "location=$region"
terraform -chdir=./infrastructure apply -auto-approve $tfPlanFileName

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