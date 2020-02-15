## `goofys.csi.azure.com` driver parameters
 > storage class `goofys.csi.azure.com` parameters are compatible with built-in [goofys](https://kubernetes.io/docs/concepts/storage/volumes/#goofys) plugin
 
 > parameter names are case-insensitive

 - Dynamic Provisioning
  > get a quick example [here](../deploy/example/storageclass-goofys-csi.yaml)

Name | Meaning | Example | Mandatory | Default value 
--- | --- | --- | --- | ---
skuName | goofys storage account type (alias: `storageAccountType`) | `Standard_LRS`, `Standard_GRS`, `Standard_RAGRS` | No | `Standard_LRS`
location | specify the location in which goofys share will be created | `eastus`, `westus`, etc. | No | if empty, driver will use the same location name as current k8s cluster
resourceGroup | specify the existing resource group name where the container is | existing resource group name | No | if empty, driver will use the same resource group name as current k8s cluster
storageAccount | specify the storage account name in which goofys share will be created | STORAGE_ACCOUNT_NAME | No | if empty, driver will find a suitable storage account that matches `skuName` in the same resource group; if a storage account name is provided, it means that storage account must exist otherwise there would be error
containerName | specify the existing container name where blob storage will be created | existing container name | No | if empty, driver will create a new container name, starting with `pvc-fuse`

 - `fsGroup` securityContext setting

goofys driver does not honor `fsGroup` securityContext setting, instead user could use `-o gid=1000` in `mountoptions` to set ownership, check https://github.com/Azure/azure-storage-fuse#mount-options for more mountoptions.

 - Static Provisioning(use existing storage container)
  > get a quick example [here](../deploy/example/pv-goofys-csi.yaml)
  >
  > get a key vault example [here](../deploy/example/keyvault/pv-goofys-csi-keyvault.yaml)

Name | Meaning | Available Value | Mandatory | Default value
--- | --- | --- | --- | ---
volumeAttributes.containerName | existing container name | existing container name | Yes |
volumeAttributes.storageAccountName | existing storage account name | existing storage account name | Yes |
volumeAttributes.keyVaultURL | Azure Key Vault DNS name | existing Azure Key Vault DNS name | No |
volumeAttributes.keyVaultSecretName | Azure Key Vault secret name | existing Azure Key Vault secret name | No |
volumeAttributes.keyVaultSecretVersion | Azure Key Vault secret version | existing version | No |if empty, driver will use "current version"
nodeStageSecretRef.name | secret name that stores storage account name and key(or sastoken) | existing kubernetes secret name |  No  |
nodeStageSecretRef.namespace | namespace where the secret is | k8s namespace  |  No  | `default`
