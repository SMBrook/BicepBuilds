resource ${1:AzureImageBuilderTemplate} 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  name:  ${2:'name'}
  location: resourceGroup().location
  identity: {}
  properties: {
    buildTimeoutInMinutes: ${3:'buildtimeoutmins'}
    vmProfile: {
      vmSize: ${4:'vmSize'}
      proxyVmSize: ${5:'proxyVmSize'}
      osDiskSizeGB: ${6:'osDiskSizeGB'}
      vnetConfig: {
        subnetId: '/subscriptions/<subscriptionID>/resourceGroups/<vnetRgName>/providers/Microsoft.Network/virtualNetworks/<vnetName>/subnets/<subnetName>'
      }
    }
    
    source: {}
    customize: {}
    distribute: {}
  }
  dependsOn: []
}


resource ${1:AzureImageBuilderTemplate} 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  name: ${2:'ImageTemplateName'}
  location: resourceGroup().location
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
      osDiskSizeGB: ${4:'osDiskSizeGB'}
    }
    source: {
      type: ${5:ManagedImage,PlatformImage,SharedImageVersion}
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
          'westeurope'
        ]
      }
    ]
  }
}
