param sigName string
param siglocation string
param imageTemplateName string = '${'WVDBicep'}${utcNow()}'
param outputname string = uniqueString(resourceGroup().name)
param userAssignedIdentities string
param imagePublisher string
param imageDefinitionName string
param imageOffer string
param imageSKU string

resource wvdid 'Microsoft.Compute/galleries/images@2019-07-01' = {
  name: '${sigName}/${imageDefinitionName}'
  location: siglocation
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
  location: siglocation
  tags: {
    imagebuilderTemplate: 'AzureImageBuilderSIG'
    userIdentity: 'enabled'
  }
  identity: {
   type: 'UserAssigned'
   userAssignedIdentities: {
    '${userAssignedIdentities}' :{}
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

