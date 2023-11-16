param(
  [Parameter(Mandatory=$true)]
  [string] $SubscriptionName,

  [Parameter(Mandatory=$true)]
  [string] $region
)

$today = (Get-Date).ToString("yyyyMMdd")
$tfPlanFileName = "traduire.plan.{0}" -f $today

az account set -s $SubscriptionName
terraform -chdir=../infrastructure init
terraform -chdir=../infrastructure plan -out="$tfPlanFileName" -var "location=$region"
terraform -chdir=../infrastructure apply -auto-approve $tfPlanFileName

$APP_NAME=$(terraform -chdir=../infrastructure output -raw APP_NAME)

if($?){
  Write-Host "------------------------------------"
  Write-Host "Infrastructure built successfully. Application Name: $APP_NAME"
  Write-Host "------------------------------------"
}
else {
  Write-Host "------------------------------------"
  Write-Host ("Errors encountered while building infrastructure. Please review. Application Name: $APP_NAME" )
  Write-Host "------------------------------------"
}
