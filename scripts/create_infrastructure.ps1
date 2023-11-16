param(
  [Parameter(Mandatory=$true)]
  [string] $SubscriptionName,

  [Parameter(Mandatory=$true)]
  [string] $region
)

$today = (Get-Date).ToString("yyyyMMdd")
$tf_plan = "traduire.plan.{0}" -f $today

az account set -s $SubscriptionName
terraform -chdir=../infrastructure init
terraform -chdir=../infrastructure plan -out="${tf_plan}" -var "location=${region}"
terraform -chdir=../infrastructure apply -auto-approve ${tf_plan}

$app_name=$(terraform -chdir=../infrastructure output -raw APP_NAME)

if($?){
  Write-Host "------------------------------------"
  Write-Host "Infrastructure built successfully. Application Name: ${app_name}"
  Write-Host "------------------------------------"
}
else {
  Write-Host "------------------------------------"
  Write-Host ("Errors encountered while building infrastructure. Please review. Application Name: ${app_name}E" )
  Write-Host "------------------------------------"
}
