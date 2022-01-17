#!/bin/bash
echo "Installing $APPNAME from $APPURI using $CERTSOURCE $LEISSUER"

KVNAMELOWER=$(echo $AKVNAME | tr '[:upper:]' '[:lower:]')
DNSNAME=${APPNAME}.${DNSDOMAIN}

echo "Querying Azure CLI for tenant ID"
KVTENANT=$(az account show --query tenantId -o tsv)

echo 'Get the identity created from the KeyVaultSecret Addon'
CSISECRET_CLIENTID=$(az aks show -g $RG --name $AKSNAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
echo $CSISECRET_CLIENTID

helmcommand="helm upgrade --install $APPNAME $APPURI --set nameOverride="${APPNAME}",frontendCertificateSource="${CERTSOURCE}",csisecrets.vaultname="${KVNAMELOWER}",csisecrets.tenantId="${KVTENANT}",csisecrets.clientId="${CSISECRET_CLIENTID}",dnsname="${DNSNAME}",appgw.frontendCertificateName="${APPNAME}-fe",appgw.rootCertificateName="${APPNAME}",letsEncrypt.issuer="${LEISSUER}",letsEncrypt.secretname="${APPNAME}-tls""
echo "Prepared Helm Command: $helmcommand"

$(echo "${helmcommand} --dry-run")
$helmcommand
