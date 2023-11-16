param(
  [Parameter(Mandatory=$true)]
  [string] $SubscriptionName,

  [Parameter(Mandatory=$true)]
  [string] $region
)

$today = (Get-Date).ToString("yyyyMMdd")
$tfPlanFileName = "traduire.plan.{0}" -f $today

az account set -s $SubscriptionName
terraform -chdir=terraform init
terraform -chdir=terraform plan -out="$tfPlanFileName" -var "location=$region"
terraform -chdir=terraform apply -auto-approve $tfPlanFileName

if($?){
  Write-Host "------------------------------------"
  Write-Host "Infrastructure built successfully. Application Name: traduire"
  Write-Host "------------------------------------"
}
else {
  Write-Host "------------------------------------"
  Write-Host ("Errors encountered while building infrastructure. Please review. Application Name: traduire" )
  Write-Host "------------------------------------"
}
