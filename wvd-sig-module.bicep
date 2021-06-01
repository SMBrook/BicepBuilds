targetScope = 'resourceGroup'

param subid string = subscription().id
param rgid string = resourceGroup().id
param imagePublisher string = 'MicrosoftWindowsDesktop'
param imageDefinitionName string = 'BicepAIBWVDImage'
param imageOffer string = 'windows-10'
param imageSKU string = '20h2-ent'
param imageLocation string = 'northeurope'
param roleNameGalleryImage string = '${'BicepAIB'}${utcNow()}'
param imageTemplateName string = 'WVDMain'
param svclocation string = 'northeurope'
param uamiName string
param uamiId string = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', uamiName)
param outputname string = uniqueString(resourceGroup().name)
param roleName string = '${'AIBRoleForSIG'}${utcNow()}'
param sigName string = 'wvdbicepsig'
param sigLocation string = 'northeurope'

// Create User-Assigned Managed Identity

resource managedidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uamiName
  location: resourceGroup().location
}

//Create Shared Image Gallery
resource wvdsig 'Microsoft.Compute/galleries@2020-09-30' = {
  name: sigName
  location: sigLocation
}

//create role definition
resource gallerydef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(roleNameGalleryImage)
  properties: {
    roleName: roleName
    description: 'Custom role for network read'
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
        ]
      }
    ]
    assignableScopes: [
      resourceGroup().id
    ]
  }
}

// create role assignment
resource galleryassignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, gallerydef.id, managedidentity.id)
  properties: {
   roleDefinitionId: gallerydef.id
    principalId: managedidentity.properties.principalId
  }
}

resource wvdid 'Microsoft.Compute/galleries/images@2019-07-01' = {
  name: '${sigName}/${imageDefinitionName}'
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


resource imageTemplateName_resource 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  name: imageTemplateName
  location: svclocation
  tags: {
    imagebuilderTemplate: 'AzureImageBuilderSIG'
    userIdentity: 'enabled'
  }
  identity: {
   type: 'UserAssigned'
   userAssignedIdentities: {
      '${uamiId}' :{}
    }
  }
  properties: {
    buildTimeoutInMinutes: 120
    vmProfile: {
      vmSize: 'Standard_D2_v2'
      osDiskSizeGB: 127
    }
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'windows-10'
      sku: '20h2-ent'
      version: 'latest'
    }
    customize: [
      {
        type: 'PowerShell'
        name: 'OptimizeOS'
        runElevated: true
        runAsSystem: true
        scriptUri: 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/14_Building_Images_WVD/1_Optimize_OS_for_WVD.ps1'
      }
      {
        type: 'WindowsRestart'
        restartCheckCommand: 'write-host \'restarting post Optimizations\''
        restartTimeout: '5m'
      }
      {
        type: 'PowerShell'
        name: 'Install Teams'
        runElevated: true
        runAsSystem: true
        scriptUri: 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/14_Building_Images_WVD/2_installTeams.ps1'
      }
      {
        type: 'WindowsRestart'
        restartCheckCommand: 'write-host \'restarting post Teams Install\''
        restartTimeout: '5m'
      }
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like \'*Preview*\''
          'include:$true'
        ]
        updateLimit: 40
      }
    ]
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: wvdid.id
        runOutputName:  outputname
        artifactTags: {
          source: 'wvd10'
          baseosimg: 'windows10'
        }
        replicationRegions: [
          'northeurope'
        ]
      }
    ]
  }
}

