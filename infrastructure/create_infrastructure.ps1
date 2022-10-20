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

$NAMESPACE="keda-system"
$AKS_RESOURCE_GROUP=$(terraform -chdir=terraform output -raw AKS_RESOURCE_GROUP)
$CLUSTER_NAME=$(terraform -chdir=terraform output -raw CLUSTER_NAME)
$IDENTITY_NAME=$(terraform -chdir=terraform output -raw KEDA_MI_NAME)
$RESOURCEID=$(terraform -chdir=terraform output -raw KEDA_RESOURCE_ID)
az aks pod-identity add --resource-group $AKS_RESOURCE_GROUP --cluster-name $CLUSTER_NAME --namespace $NAMESPACE --name $IDENTITY_NAME --identity-resource-id $RESOURCEID

# echo Application name
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
