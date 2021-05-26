targetScope = 'subscription'

//Define WVD deployment parameters
param resourceGroupPrefrix string = 'AZDemoSB-Bicep-WVD'
param hostpoolName string = 'myBicepHostpool'
param hostpoolFriendlyName string = 'My Bicep deployed Hostpool'
param appgroupName string = 'myBicepAppGroup'
param appgroupNameFriendlyName string = 'My Bicep deployed Appgroup'
param workspaceName string = 'myBicepWorkspace'
param workspaceNameFriendlyName string = 'My Bicep deployed Workspace'
param preferredAppGroupType string = 'Desktop'
param wvdbackplanelocation string = 'eastus'
param hostPoolType string = 'pooled'
param loadBalancerType string = 'BreadthFirst'
param logAnalyticsWorkspaceName string = 'AZDemosSBLAWorkspace'

//Define Networking deployment parameters
param vnetName string = 'bicep-vnet'
param vnetaddressPrefix string ='10.50.0.0/23'
param subnetPrefix string = '10.50.1.0/24'
param vnetLocation string = 'northeurope'
param subnetName string = 'bicep-subnet'
param HubvnetName string = 'Identity-vnet'
param HubvnetRg string = 'AzDemoSB-Identity-rg'

//Define Azure Files deployment parameters
param storageaccountlocation string = 'northeurope'
param storageaccountName string = 'bicepsaazsmblabs'
param storageaccountkind string = 'FileStorage'
param storgeaccountglobalRedundancy string = 'Premium_LRS'
param fileshareFolderName string = 'profilecontainers'

//Define VM Parameters
param existingVnetName string = vnetName
param existingSubnetName string = subnetName
@minLength(1)
@maxLength(62)
param dnsLabelPrefix string
param vmSize string = 'Standard_B2ms'
param domainToJoin string
param domainUserName string
@secure()
param domainPassword string
param vmAdminUsername string
@secure()
param vmAdminPassword string
param location string = vnetLocation
param publicIpName string = 'SHPIP1'
param dnsservers string = '10.1.0.4'

//Create Resource Groups
resource rgwvd 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name : '${resourceGroupPrefrix}'
  location : 'northeurope'
}

// Get Existing Identity RG
resource rgwvdIdentity 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: 'AzDemoSB-Identity-rg'
}

//Get Existing Identity VNet Details
resource identityvnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: HubvnetName
  scope: resourceGroup(HubvnetRg)
}

//Create WVD backplane objects and configure Log Analytics Diagnostics Settings
module wvdbackplane 'wvd-backplane-module.bicep' = {
  name: 'wvdbackplane'
  scope: resourceGroup(rgwvd.name)
  params: {
    hostpoolName: hostpoolName
    hostpoolFriendlyName: hostpoolFriendlyName
    appgroupName: appgroupName
    appgroupNameFriendlyName: appgroupNameFriendlyName
    workspaceName: workspaceName
    workspaceNameFriendlyName: workspaceNameFriendlyName
    preferredAppGroupType: preferredAppGroupType
    applicationgrouptype: preferredAppGroupType
    wvdbackplanelocation: wvdbackplanelocation
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsResourceGroup : rgwvd.name
    wvdBackplaneResourceGroup : rgwvd.name
  }
}

//Create WVD Network and Subnet
module wvdnetwork './wvd-network-module.bicep' = {
  name: 'wvdnetwork'
  scope: resourceGroup(rgwvd.name)
  params: {
    vnetName : vnetName
    vnetaddressPrefix : vnetaddressPrefix
    subnetPrefix : subnetPrefix
    vnetLocation : vnetLocation
    subnetName : subnetName
    dnsservers : dnsservers
  }
}

module wvdpeering './wvd-peering-module.bicep' = {
  name: '${wvdnetwork.name}wvdpeering1'
  scope: resourceGroup(rgwvd.name)
  params:{
    peeringnamefromwvdvnet : '${vnetName}/${vnetName}-to-${identityvnet.name}'
    identityVnetID : identityvnet.id
  }
}

module wvdpeeringid './wvd-peering-id-module.bicep' = {
  name: '${wvdnetwork.name}wvdpeeringid'
  scope: resourceGroup(rgwvdIdentity.name)
  params:{
    peeringnamefromhubvnet : '${identityvnet.name}/${identityvnet.name}-to-${vnetName}'
    wvdvnetID : wvdnetwork.outputs.vnet1id
  }
}

//Create WVD Azure File Services and FileShare`
module wvdFileServices './wvd-fileservices-module.bicep' = {
  name: 'wvdFileServices'
  scope: resourceGroup(rgwvd.name)
  params: {
    storageaccountlocation : storageaccountlocation
    storageaccountName : storageaccountName
    storageaccountkind : storageaccountkind
    storgeaccountglobalRedundancy : storgeaccountglobalRedundancy
    fileshareFolderName : fileshareFolderName
  }
}


//Create WVD Session Host

module vmcreation './wvd-vm-module.bicep' = {
  name: 'wvdfirstsessionhost'
  scope: resourceGroup(rgwvd.name)
  params: {
    dnsLabelPrefix: dnsLabelPrefix
    vmSize: vmSize
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
    domainToJoin: domainToJoin
    domainUserName: domainUserName
    domainPassword: domainPassword
    existingSubnetName: existingSubnetName
    existingVnetName: existingVnetName
   }

}

