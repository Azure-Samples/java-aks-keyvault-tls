# End-2-End TLS with Azure Kubernetes Service and Application Gateway Ingress Controller & CSI Secret

This repo demonstrates deploying an example "Hello World" Java Spring Boot web app into a AKS cluster, securely exposing it to the web using end-to-end TLS.

## Features

This example uses the Azure Kubernetes managed WAF ingress __Application Gateway__, and the [CSI Secret Store Driver](https://docs.microsoft.com/azure/aks/csi-secrets-store-driver) addon, to store the certificates in [Azure KeyVault](https://azure.microsoft.com/services/key-vault/).

## Getting Started

The following instructions will walk you though

1. Creating the AKS Cluster with ACR (Azure Container Registry), AGIC addon (Application Gateway Ingress Controller), CSI Secret addon, AKV (Azure KeyVault), cert-manager for frontend certificate generation & external-dns for public DNS.
2. Generating a Self-signed backend certificate
3. Compile and running the App locally
4. Deploying the app to AKS

### Using the GitHub reusable workflow

As an alternative to the manual instructions detailed in this repo, you can call a GitHub workflow in this repo to install the app on an existing cluster. See [here](workflow.md) for instructions on how to do that.

## Prerequisites

Use the [AKS helper](https://azure.github.io/AKS-Construction) to provision your cluster, and configure the helper as follows:

Keep the default options for:

* __Operations Principles__: __"I want a managed environment"__
* __Security Principles__: __"Cluster with additional security controls"__

Now, to configure the TLS Ingress, go into the __Addon Details__ tab

  In the section __Securely Expose your applications via Layer 7 HTTP(S) proxies__, select the following options, providing all the require information

* __Create FQDN URLs for your applications using external-dns__
* __Automatically Issue Certificates for HTTPS using cert-manager__

  __NOTE:__ In the section __CSI Secrets : Store Kubernetes Secrets in Azure Keyvault, using AKS Managed Identity__,  ensure the following option is selected: __Yes, provision a new Azure KeyVault & enable Secrets Store CSI Driver__.  Also, __Enable KeyVault Integration for TLS Certificates__ is selected, this will integrate Application Gateway access to KeyVault,  and

Now, under the __Deploy__ tab, execute the commands to provision your complete environment. __NOTE__: Once complete, please remember to run the script on the __Post Configuration__ tab to complete the deployment.

## Installation

### Upload the Cert to KeyVault, and allow access from Application Gateway and your Java app

Set all required environment variables for the following commands:

```bash
export AKSRG=<resource group created by the template>
export AKSNAME=<cluster name created by the template>
export AGNAME=<application gateway name created by the template>
export ACRNAME=<container registry name created by the template>
export KVNAME=<KeyVault name created by the template>
export DNSZONE=<Your dnsZone name>
export KVTENANT=$(az account show --query tenantId -o tsv)
```

### Generate self signed Certificate

>__NOTE__: The CN you provide the certificate needs to match the Ingress annotation : "appgw.ingress.kubernetes.io/backend-hostname" currently ___"openjdk-demo"___

```bash
export COMMON_NAME=openjdk-demo
az keyvault certificate create --vault-name $KVNAME -n $COMMON_NAME -p "$(az keyvault certificate get-default-policy | sed -e s/CN=CLIGetDefaultPolicy/CN=${COMMON_NAME}/g )"
```

### Create a `SecretProvideClass` in AKS, to allow AKS to reference the values in the KeyVault

```bash
## Get the identity created from the KeyVaultSecret Addon
export CSISECRET_CLIENTID=$(az aks show  --resource-group $AKSRG --name $AKSNAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)


echo "
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-${KVNAME}
spec:
  provider: azure
  parameters:
    usePodIdentity: \"false\"         # [OPTIONAL] if not provided, will default to "false"
    useVMManagedIdentity: \"true\"
    userAssignedIdentityID: \"${CSISECRET_CLIENTID}\"
    keyvaultName: \"${KVNAME}\"          # the name of the KeyVault
    cloudName: \"\"                   # [OPTIONAL for Azure] if not provided, azure environment will default to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: ${COMMON_NAME}
          objectAlias: identity.p12
          objectType: secret
          objectFormat: PFX
          objectEncoding: base64
    tenantId: \"${KVTENANT}\"                 # the tenant ID of the KeyVault
" | kubectl apply -f -
```

### Upload backend cert to AppGw

This step is required if your backend cert is not a CA-signed cert, or a CA known to AppGw: [https://azure.github.io/application-gateway-kubernetes-ingress/tutorials/tutorial.e2e-ssl/](https://azure.github.io/application-gateway-kubernetes-ingress/tutorials/tutorial.e2e-ssl/)

```bash
## https://docs.microsoft.com/en-us/azure/application-gateway/key-vault-certs#how-integration-works

## Create Root Cert reference in AppGW
az network application-gateway root-cert create \
     --gateway-name $AGNAME  \
     --resource-group $AKSRG \
     --name $COMMON_NAME \
     --keyvault-secret $(az keyvault secret list-versions --vault-name $KVNAME -n $COMMON_NAME --query "[?attributes.enabled].id" -o tsv)
```

## Build Java App Container

```bash
### Create a deployable jar file
SSL_ENABLED="false" ./mvnw package

### Build the image locally
docker build -t ${ACRNAME}.azurecr.io/openjdk-demo:0.0.1 .
```

## Upload Container to ACR & Deploy to AKS

### Upload to ACR

```bash
az acr login -n  ${ACRNAME}
docker push ${ACRNAME}.azurecr.io/openjdk-demo:0.0.1
```

### Deploy to AKS

```bash
# In using Private Ingress, set PRIVATEIP to "true", otherwise "false"
export PRIVATEIP=false
export CHALLENGE_TYPE=$( [[ $PRIVATEIP == "true" ]] && echo "dns01" || echo "http01" )
sed -e "s|{{ACRNAME}}|${ACRNAME}|g" -e "s|{{DNSZONE}}|${DNSZONE}|g" -e "s|{{KVNAME}}|${KVNAME}|g" -e "s|{{PRIVATEIP}}|${PRIVATEIP}|g"  -e "s|{{CHALLENGE_TYPE}}|${CHALLENGE_TYPE}|g" ./deployment-csi.yml | kubectl apply -f -
```

Check your POD status is successfully running

```bash
kubectl get pods
```

After 3-4 minutes (while the dns and certificates are generated), your new webapp should be accessible on ```https://openjdk-demo.{{DNSZONE}}```.

## Run container locally (OPTIONAL)

Generate self signed PKCS12 backend cert, for local testing only

```bash
# Create a private key and public certificate
openssl req -newkey rsa:2048 -x509 -keyout cakey.pem -out cacert.pem -days 3650

# Create a JKS keystore
openssl pkcs12 -export -in cacert.pem -inkey cakey.pem -out identity.pfx

# Record your key store passwd for the following commands:
export KEY_STORE_PASSWD=<your pfx keystore password>
```

NOTE: When you use a bind mount, a file or directory on the host machine is mounted into a container. The file or directory is referenced by its absolute path on the host machine.

```bash
docker run -d \
  -it \
  -p 8080:8080 \
  --env SSL_ENABLED="true" \
  --env SSL_STORE=/cert/identity.p12 \
  --env KEY_STORE_PASSWD=${KEY_STORE_PASSWD} \
  --name openjdk-demo \
  --mount type=bind,source="$(pwd)"/identity.p12,target=/cert/identity.p12,readonly  \
  ${ACRNAME}.azurecr.io/openjdk-demo:0.0.1
```
