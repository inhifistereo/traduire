param(
    [switch] $Complete
)

helm uninstall dapr --namespace dapr-system
kubectl delete namespace dapr-system

helm uninstall traduire 

if($Complete) {
    helm uninstall keda --namespace keda
    helm uninstall aad-pod-identity
    helm uninstall cert-manager --namespace cert-manager 
    helm uninstall kong kong/kong --namespace kong-gateway
}