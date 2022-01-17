# Callable Workflow

This repo contains a workflow to install the sample app, along with the accompanying certificate and dns configuration.
It's written as a GitHub Reusable Workflow, which means that it is invoked by another GitHub workflow.

You can call the reusable workflow in this repository directly, providing the correct parameters. Here's a sample of how a calling workflow looks;

```yaml
name: Sample workflow for calling JavaApp reusable workflow

on:
  workflow_dispatch:

jobs:
  azsamples-deploy-javaApp:
    uses: azure-samples/java-aks-keyvault-tls/.github/workflows/deployapp.yml@gb-workflow
    with:
      RG: yourResourceGroup
      AKSNAME: aks-Byo
      DNSDOMAIN: azdemo.co.uk
      DNSRG: domainssl
      DNSRECORDNAME: openjdk-demo
      AKVNAME: kv-Byo
      AGNAME: agw-Byo
      APPNAME: openjdk-demo
      FRONTENDCERTTYPE: certmanager-staging
      CERTMANAGEREMAIL: gdogg@microsoft.com
    secrets:
      AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
```

You need to provide the Azure Credentials in order for the appropriate Azure resources to be configured. However the way GitHub deals with secrets is handled securely, secrets and parameters are not sent to this repo, simply the reusable workflow file is downloaded to your GitHub runner.