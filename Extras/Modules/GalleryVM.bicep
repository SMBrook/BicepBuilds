@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

@description('(Required when vmImageType = Gallery) Gallery image Offer.')
param vmGalleryImageOffer string = 'windows-10'

@description('(Required when vmImageType = Gallery) Gallery image Publisher.')
param vmGalleryImagePublisher string = 'MicrosoftWindowsDesktop'

@description('(Required when vmImageType = Gallery) Gallery image SKU.')
param vmGalleryImageSKU string = '21h1-evd'

@description('This prefix will be used in combination with the VM number to create the VM name. This value includes the dash, so if using “rdsh” as the prefix, VMs would be named “rdsh-0”, “rdsh-1”, etc. You should use a unique prefix to reduce name collisions in Active Directory.')
param rdshPrefix string = take(toLower(resourceGroup().name), 10)

@description('Number of session hosts that will be created and added to the hostpool.')
param rdshNumberOfInstances int

@description('The size of the session host VMs.')
param rdshVmSize string = 'Standard_B2ms'

@description('Enables Accelerated Networking feature, notice that VM size must support it, this is supported in most of general purpose and compute-optimized instances with 2 or more vCPUs, on instances that supports hyperthreading it is required minimum of 4 vCPUs.')
param enableAcceleratedNetworking bool = false

@description('The username for the domain admin.')
param administratorAccountUsername string

@description('The password that corresponds to the existing domain username.')
@secure()
param administratorAccountPassword string

@description('A username to be used as the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
param vmAdministratorUsername string = 'avdlocal'

@description('The password associated with the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
@secure()
param vmAdministratorPassword string

@description('Resource ID of the image.')
param rdshImageSourceId string = '/subscriptions/1ad7e9b0-b59b-42f7-a9f6-8d971cc1f1ea/resourceGroups/BICEP-AVD-RG-SIG/providers/Microsoft.Compute/galleries/BicepavdSIG/images/BicepAIBavdImage/versions/0.24793.41679'

@description('Location for all resources to be created in.')
param location string = 'westeurope'

@description('The tags to be assigned to the network interfaces')
param networkInterfaceTags object = {}

@description('The tags to be assigned to the virtual machines')
param virtualMachineTags object = {}

@description('VM name prefix initial number.')
param vmInitialNumber int = 0

@description('The token for adding VMs to the hostpool')
param hostpoolToken string

@description('The name of the hostpool')
param hostpoolName string = 'myBicepHostpool'

@description('OUPath for the domain join')
param ouPath string = ''

@description('Domain to join')
param domain string = 'azurelabsmb.local'

param subnet_id string = '/subscriptions/1ad7e9b0-b59b-42f7-a9f6-8d971cc1f1ea/resourceGroups/BICEP-AVD-RG-NETWORK/providers/Microsoft.Network/virtualNetworks/bicep-vnet/subnets/bicep-subnet' 

param aadJoin bool = false

param storageAccountType string = 'Premium_LRS'

resource nic 'Microsoft.Network/networkInterfaces@2018-11-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + vmInitialNumber)}-nic'
  location: location
  tags: networkInterfaceTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: { 
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_id
          }
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2018-10-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + vmInitialNumber)}'
  location: location
  tags: virtualMachineTags
  identity: {
    type: (aadJoin ? 'SystemAssigned' : 'None')
  }
  properties: {
    hardwareProfile: {
      vmSize: rdshVmSize
    }
    osProfile: {
      computerName: '${rdshPrefix}${(i + vmInitialNumber)}'
      adminUsername: vmAdministratorUsername
      adminPassword: vmAdministratorPassword
    }
    storageProfile: {
      imageReference: {
        id:rdshImageSourceId
        //publisher: vmGalleryImagePublisher
        //offer: vmGalleryImageOffer
       // sku: vmGalleryImageSKU
        //version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${rdshPrefix}${(i + vmInitialNumber)}-nic')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: 'Windows_Client'
  }
    dependsOn: [
    nic
  ]
}]

resource vm_DSC 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/Microsoft.PowerShell.DSC'
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
    vm
  ]
}]

resource vm_joindomain 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, rdshNumberOfInstances): if (!aadJoin) {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domain
      ouPath: ouPath
      user: administratorAccountUsername
      restart: 'true'
      options: '3'
    }
    protectedSettings: {
      password: administratorAccountPassword
    }
  }
  dependsOn: [
    vm_DSC
  ]
}]
