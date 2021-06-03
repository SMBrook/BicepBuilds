param roleNameGalleryImage string = '${'BicepAIB'}${utcNow()}'
param uamiName string = '${'AIBUser'}${utcNow()}'
param uamiId string = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', uamiName)
param roleName string = '${'AIBRoleForSIG'}${utcNow()}'
param sigName string
param sigLocation string
param imagePublisher string
param imageDefinitionName string
param imageOffer string
param imageSKU string


//Create Shared Image Gallery
resource wvdsig 'Microsoft.Compute/galleries@2020-09-30' = {
  name: sigName
  location: sigLocation
}

// Create User-Assigned Managed Identity

resource managedidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uamiName
  location: resourceGroup().location
}

//Create Role Definition with added VM Run Action for Image Builder
resource gallerydef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(roleNameGalleryImage)
  properties: {
    roleName: '${roleName}${sigName}'
    description: 'Custom role for SIG and AIB'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/galleries/read'
          'Microsoft.Compute/galleries/images/read'
          'Microsoft.Compute/galleries/images/versions/read'
          'Microsoft.Compute/galleries/images/versions/write'
          'Microsoft.Compute/images/write'
          'Microsoft.Compute/images/read'
          'Microsoft.Compute/images/delete'
          'Microsoft.VirtualMachineImages/imageTemplates/Run/action' //Not required if not running Powershell Deployment Script for AIB
          'Microsoft.Storage/storageAccounts/*'//Not required if not running Powershell Deployment Script for AIB
          'Microsoft.ContainerInstance/containerGroups/*'//Not required if not running Powershell Deployment Script for AIB
          'Microsoft.Resources/deployments/*'//Not required if not running Powershell Deployment Script for AIB
          'Microsoft.Resources/deploymentScripts/*'//Not required if not running Powershell Deployment Script for AIB
        ]
      }
    ]
    assignableScopes: [
      resourceGroup().id
    ]
  }
}

output uamioutput string = uamiId

// Create Role Assignment
resource galleryassignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, gallerydef.id, managedidentity.id)
  properties: {
   roleDefinitionId: gallerydef.id
    principalId: managedidentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Create Managed Identity Operator Role Assignment - Not required if not running Powershell Deployment Script for AIB
resource miorole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830', managedidentity.id)
  properties: {
   roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830'
    principalId: managedidentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
 

// Create SIG Image Definition
resource wvdid 'Microsoft.Compute/galleries/images@2019-07-01' = {
  name: '${wvdsig.name}/${imageDefinitionName}'
  location: sigLocation
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    identifier: {
      publisher: imagePublisher
      offer: imageOffer
      sku: imageSKU
    }
    recommended: {
      vCPUs: {
        min: 2
        max: 32
      }
      memory: {
        min: 4
        max: 64
      }
    }
    hyperVGeneration: 'V2'
  }
  tags: {}
}

output wvdidoutput string = wvdid.id
