KVNAMELOWER=${AKVNAME,,}
KVTENANT=$(az account show --query tenantId -o tsv)
DNSNAME=${APPNAME}.${DNSDOMAIN}

echo 'Get the identity created from the KeyVaultSecret Addon'
export CSISECRET_CLIENTID=$(az aks show -g $RG --name $AKSNAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
echo $CSISECRET_CLIENTID

helm upgrade --install $APPNAME $APPURI --set nameOverride="${APPNAME}",frontendCertificateSource="${CERTSOURCE}",csisecrets.vaultname="${KVNAMELOWER}",csisecrets.tenantId="${KVTENANT}",csisecrets.clientId="${CSISECRET_CLIENTID}",dnsname="${DNSNAME}",appgw.frontendCertificateName="${APPNAME}-fe",appgw.rootCertificateName="${APPNAME}",letsEncrypt.issuer="${LEISSUER}",letsEncrypt.secretname="${APPNAME}-tls" --dry-run
helm upgrade --install $APPNAME $APPURI --set nameOverride="${APPNAME}",frontendCertificateSource="${CERTSOURCE}",csisecrets.vaultname="${KVNAMELOWER}",csisecrets.tenantId="${KVTENANT}",csisecrets.clientId="${CSISECRET_CLIENTID}",dnsname="${DNSNAME}",appgw.frontendCertificateName="${APPNAME}-fe",appgw.rootCertificateName="${APPNAME}",letsEncrypt.issuer="${LEISSUER},letsEncrypt.secretname="${APPNAME}-tls""
