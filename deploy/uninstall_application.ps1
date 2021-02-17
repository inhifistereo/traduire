param(
    [switch] $Complete
)

helm uninstall dapr --namespace dapr-system
kubectl delete namespace dapr-system

helm uninstall traduire 

if($Complete) {
    helm uninstall traefik          
    helm uninstall keda --namespace keda
    kubectl delete namespace keda
    helm uninstall aad-pod-identity
}