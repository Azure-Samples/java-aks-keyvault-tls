# Callable Workflow

This repo contains a [workflow](.github\workflows\deployapp.yml) to install the sample app, along with all the accompanying configuration.
It's written as a [GitHub Reusable Workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows), which means that it is invoked by another GitHub workflow.

> The workflow is written to run on a hosted GitHub agent and leverage DockerHub for container image storage. If your environment does not allow hosted GitHub agents to communicate with the AKS endpoint, or if you have firewall controls or policies that prevent container images coming from DockerHub then you should follow the instructions in the [README.md](readme.md) where you can build the container and store in a private Azure Container Registry.

You can call the reusable workflow in this repository directly from your own GitHub repository.
You will need to providing the correct parameters to allow the workflow to run. Here's a sample;

```yaml
name: Sample workflow for calling JavaApp reusable workflow

on:
  workflow_dispatch:

jobs:
  azsamples-deploy-javaApp:
    uses: azure-samples/java-aks-keyvault-tls/.github/workflows/deployapp.yml@1.0-preview
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
