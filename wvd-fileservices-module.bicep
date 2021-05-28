//Define Azure Files parmeters
param storageaccountlocation string
param storageaccountName string
param storageaccountkind string
param storageaccountredundancytype string = 'Premium_LRS'
param fileshareFolderName string = 'profilecontainers'

//Concat FileShare
var filesharelocation = '${sa.name}/default/${fileshareFolderName}'

//Create Storage account
resource sa 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: storageaccountName
  location: storageaccountlocation
  kind: storageaccountkind
  sku: {
    name: storageaccountredundancytype
  }
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    
  }
}

//Create FileShare
resource fs 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  name: filesharelocation
}

output storageAccountId string = sa.id

/*Enable SMB Multichannel
resource fsconfig 'Microsoft.Storage/storageAccounts/fileServices@2021-02-01' = {
  name: '${sa.name}/default'
  properties: {
   protocolSettings: {
      smb: {
        multichannel: {
          enabled: true
        }
       }
    }
  }
}
*/

