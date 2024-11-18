Ref 1: https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough

# Create resource group
az group create --name aks --location eastus

# Create cluster
az aks create --resource-group aks --name oreillyAKS --node-count 1 --enable-addons monitoring --generate-ssh-keys

<#
SSH key files '/home/tim/.ssh/id_rsa' and '/home/tim/.ssh/id_rsa.pub' have been generated under ~/.ssh to allow SSH access to the VM. If using machines without permanent storage like Azure Cloud Shell without an attached file share, back up your keys to a safe location
#>
# Connect to the cluster
az aks install-cli

az aks get-credentials --resource-group aks --name oreillyAKS

kubectl get nodes

# Deploy the application (YAML is in cloud drive)
kubectl apply -f azure-vote.yaml

# Test the application (CTRL+C to stop)
kubectl get service azure-vote-front --watch

# Browse to load balancer external IP

# Start the Kubernetes dashboard
az aks browse --resource-group aks --name oreillyAKS

# Sign into the dashboard (K8S 1.16+)
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard

## Update <RESOURCE_GROUP and <AKS_NAME> with your input.

kubectl config view -o jsonpath='{.users[?(@.name == "clusterUser_aks_oreillyAKS")].user.auth-provider.config.access-token}'

