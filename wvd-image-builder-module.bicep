param siglocation string
param imageTemplateName string = '${'WVDBicep'}${utcNow()}'
param outputname string = uniqueString(resourceGroup().name)
param rgname string = resourceGroup().name
param userAssignedIdentities string
param galleryImageId string
param imagePublisher string
param imageOffer string
param imageSKU string

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
      publisher: imagePublisher
      offer: imageOffer
      sku: imageSKU
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
        galleryImageId: galleryImageId
        runOutputName:  outputname
        artifactTags: {
          source: 'wvd10'
          baseosimg: 'windows10'
        }
        replicationRegions: []
      }
    ]
  }
}

resource scriptName_BuildVMImage 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'BuildVMImage'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentities}': {}
    }
  }
  properties: {
    forceUpdateTag: '1'
    azPowerShellVersion: '5.9'
    arguments: ''
    scriptContent: 'Invoke-AzResourceAction -ResourceName ${imageTemplateName} -ResourceGroupName ${rgname} -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2020-02-14" -Action Run -Force\r\n$Timeout = 3600\r\n$timer = [Diagnostics.Stopwatch]::StartNew()\r\n$Result = Get-AzImageBuilderTemplate -ResourceGroupName BICEP-WVD-SIG -Name WVDBicep20210603T101135Z | select LastRunStatusRunState\r\nWrite-Host $Result\r\n\r\nwhile (($timer.Elapsed.TotalSeconds -lt $Timeout) -and ($Result -match "Running")) \r\n{\r\n    Start-Sleep -Seconds 1\r\n    Write-Host -Message "Still waiting for action to complete after",($timer.Elapsed.TotalSeconds)\r\n}\r\n\r\nif ($Result -match "Failed") {\r\n    Write-Host "Job failed after" ($timer.Elapsed.TotalSeconds)\r\n}\r\n\r\nif ($Result -match "Succeeded") {\r\n    Write-Host "Job completed after" ($timer.Elapsed.TotalSeconds)\r\n}\r\n\r\n$timer.Stop()'
    timeout: 'PT5M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    imageTemplateName_resource
  ]
}
