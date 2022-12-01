#!/bin/bash

# this runs at Codespace creation - not part of pre-build

echo "$(date)    post-create start" >> ~/status

#Install jq
apt update
apt install -y jq

#Install Dapr cli
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

#Install Playwright 
sudo npx playwright install-deps

#Install Flux
VERSION=`curl --silent "https://api.github.com/repos/fluxcd/flux2/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/'`
curl -Ls "https://github.com/fluxcd/flux2/releases/download/v${VERSION}/flux_${VERSION}_linux_amd64.tar.gz" -o /tmp/flux2.tar.gz
tar -xf /tmp/flux2.tar.gz -C /tmp
sudo mv /tmp/flux /usr/local/bin
rm -f /tmp/flux2.tar.gz

#Install az extensions
sudo az aks install-cli -y
sudo az extension add --name application-insights -y
sudo az extension add --name aks-preview -y

#Install Azure Static WebApp cli
sudo npm install -g @azure/static-web-apps-cli

echo "$(date)    post-create complete" >> ~/status
