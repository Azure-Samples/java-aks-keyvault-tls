echo "Getting credentials for $AKSNAME in $RG"
az aks get-credentials -n $AKSNAME -g $RG --overwrite-existing

echo "Kubelogin $kubeloginversion"
wget https://github.com/Azure/kubelogin/releases/download/$kubeloginversion/kubelogin-linux-amd64.zip
unzip kubelogin-linux-amd64.zip
sudo mv bin/linux_amd64/kubelogin /usr/bin
kubelogin convert-kubeconfig -l azurecli