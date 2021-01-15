param(

)

# Install Traefik Ingress 
helm repo add traefik https://helm.traefik.io/traefik    
helm upgrade -i traefik traefik/traefik -f  ../Infrastructure/traefik/values.yaml --wait
         
# Install Keda
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
kubectl create namespace keda
helm upgrade -i keda kedacore/keda --namespace keda --version 1.5.0

# Install App
helm upgrade --install --set key=value traduire .