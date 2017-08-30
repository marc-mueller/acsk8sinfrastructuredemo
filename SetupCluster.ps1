Param(
  [string]$vstspat = "xekjdwzofuorsbz4fpgf6vmd3lkktyuja5ssqgrks7ijikjssvtq",
  [string]$subscriptionname = "MVP VS Ultimate",
  [string]$rsakeyfile = "C:\Users\mmueller\.ssh\id_rsa",
  [string]$vstsaccount = "4tecture-training"
)

### setup the cli settings
kubectl config unset contexts.demo-4t-k8s
az account set --subscription $subscriptionname
az account show
#az login #if needed

### setup kubernetes cluster
az group create -n "KubernetesDemo" -l "westeurope"
az acs create -n KubernetesDemo -d demo-4t-k8s -g KubernetesDemo --generate-ssh-keys --orchestrator-type kubernetes
az acs kubernetes get-credentials -g=KubernetesDemo -n=KubernetesDemo --ssh-key-file=$rsakeyfile
az acr create --name 4tKubernetesDemoRegistry --resource-group KubernetesDemo --sku Basic
az acr update -n 4tKubernetesDemoRegistry --admin-enabled true
$acrusername = az acr credential show -n 4tKubernetesDemoRegistry --query username
$acrpassword = az acr credential show -n 4tKubernetesDemoRegistry --query passwords[0].value
kubectl create secret docker-registry 4tkubernetesdemoregistry --docker-username=$acrusername --docker-password=$acrpassword--docker-server='4tkubernetesdemoregistry.azurecr.io' --docker-email='info@4tecture.ch'

### deploy k8s configurations
kubectl apply -f .\devfun_namespaces.yaml
kubectl apply -f nginx-ingress-defaultbackend.yaml
kubectl apply -f nginx-ingress-controller.yaml
kubectl apply -f nginx-ingress-service.yaml
kubectl -n kube-system get po
kubectl apply -f vsts_namespaces.yaml
kubectl create secret generic vsts --from-literal=VSTS_TOKEN=$vstspat --from-literal=VSTS_ACCOUNT=$vstsaccount --namespace=vsts
kubectl apply -f vsts_agent.yaml
kubectl apply -f lego_namespaces.yaml
kubectl apply -f lego_configmap.yaml
kubectl apply -f lego_deployment.yaml
kubectl apply -f devfun_ingress-dev.yaml
kubectl apply -f devfun_ingress-test.yaml
kubectl apply -f devfun_ingress-prod.yaml