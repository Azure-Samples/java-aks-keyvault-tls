# Callable Workflow

This repo contains a [workflow](.github\workflows\deployapp.yml) to install the sample app, along with all the accompanying configuration.
It's written as a [GitHub Reusable Workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows), which means that it is invoked by another GitHub workflow.

You can call the reusable workflow in this repository directly from your own GitHub repository.
You will need to providing the correct parameters to allow the workflow to run. Here's a sample;

```yaml
name: Sample workflow for calling JavaApp reusable workflow

on:
  workflow_dispatch:

jobs:
  azsamples-deploy-javaApp:
    uses: azure-samples/java-aks-keyvault-tls/.github/workflows/deployapp.yml@gb-workflow
    with:
      RG: yourResourceGroup
      AKSNAME: yourAksClusterName
      DNSDOMAIN: yourazuremanageddnsdomain.something.something
      DNSRG: yourazuredomain
      DNSRECORDNAME: openjdk-demo
      AKVNAME: yourAzureKeyVaultName
      AGNAME: yourAppGatewayName
      APPNAME: openjdk-demo
      FRONTENDCERTTYPE: certmanager-staging
      CERTMANAGEREMAIL: yourworkingemail@address.something
    secrets:
      AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
```

You need to provide Azure Credentials in order for the appropriate Azure resources to be configured. The format of these secrets is as explained [here](https://github.com/Azure/login#configure-a-service-principal-with-a-secret).
Although it may appear you are passing secrets, the way GitHub deals with secrets is handled securely. Secrets and parameters are not sent to this repo, simply the reusable workflow file is downloaded to your GitHub runner where the activity takes place.
