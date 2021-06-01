param existingVnetName string
param existingSubnetName string

@minLength(1)
@maxLength(62)
param dnsLabelPrefix string

param vmSize string
param domainToJoin string
param domainUserName string

@secure()
param domainPassword string

param ouPath string

@description('Set of bit flags that define the join options. Default value of 3 is a combination of NETSETUP_JOIN_DOMAIN (0x00000001) & NETSETUP_ACCT_CREATE (0x00000002) i.e. will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx')
param domainJoinOptions int = 3

param vmAdminUsername string

@secure()
param vmAdminPassword string

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

param hostpoolName string
param hostpoolToken string

param location string = resourceGroup().location
var storageAccountName = uniqueString(resourceGroup().id, deployment().name)
var imagePublisher = 'microsoftwindowsdesktop'
var imageOffer = 'office-365'
var windowsOSVersion = '20h2-evd-o365pp-g2'
var nicName = '${dnsLabelPrefix}-nic'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingSubnetName)

resource storageAccount 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: dnsLabelPrefix
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: dnsLabelPrefix
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${dnsLabelPrefix}-OsDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${dnsLabelPrefix}-DataDisk'
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
          lun: 0
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
  }
}

resource domainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachine.name}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: '${domainToJoin}\\${domainUserName}'
      restart: true
      options: domainJoinOptions
    }
    protectedSettings: {
      password: domainPassword
    }
  }
}

resource rdshPrefix_vmInitialNumber_Microsoft_PowerShell_DSC 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  name: '${virtualMachine.name}/Microsoft.PowerShell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: artifactsLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostpoolName
        registrationInfoToken: hostpoolToken
       }
    }
  }
  dependsOn: [
    domainJoinExtension
  ]
}

/* resource rdshPrefix_vmInitialNumber_AADLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    rdshPrefix_vmInitialNumber_Microsoft_PowerShell_DSC
  ]
}
*/

/* resource rdshPrefix_vmInitialNumber_AADLoginForWindowsWithIntune 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/AADLoginForWindowsWithIntune'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    }
  }
  dependsOn: [
    rdshPrefix_vmInitialNumber_Microsoft_PowerShell_DSC
  ]
}
*/
