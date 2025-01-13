param location string
param prefix string
param logAnalyticsWorkspaceId string

// Logic App that monitors VM status changes
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: '${prefix}-vm-monitor'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_VM_Status_Changes': {
          type: 'Microsoft.Azure.Monitoring.ActivityLog.ActivityLogAlert'
          inputs: {
            body: {
              properties: {
                enabled: true
                scopes: [
                  resourceGroup().id
                ]
                condition: {
                  allOf: [
                    {
                      field: 'category'
                      equals: 'Administrative'
                    }
                    {
                      field: 'resourceType'
                      equals: 'Microsoft.Compute/virtualMachines'
                    }
                    {
                      field: 'operationName'
                      containsAny: [
                        'Microsoft.Compute/virtualMachines/start/action'
                        'Microsoft.Compute/virtualMachines/deallocate/action'
                      ]
                    }
                  ]
                }
              }
            }
          }
        }
      }
      actions: {
        'Send_Data': {
          type: 'ApiConnection'
          inputs: {
            body: {
              StatusChangeEvent: '@{triggerBody().status.code}'
              ResourceId: '@{triggerBody().resourceId}'
              Status: '@{triggerBody().status.displayStatus}'
              EventType: '@{triggerBody().operationName}'
              TimeGenerated: '@{utcNow()}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureloganalyticsdatacollector\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/api/logs'
          }
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          azureloganalyticsdatacollector: {
            connectionId: logAnalyticsConnection.id
            connectionName: 'azureloganalyticsdatacollector'
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureloganalyticsdatacollector'
          }
        }
      }
    }
  }
}

// API Connection for Log Analytics
resource logAnalyticsConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: '${prefix}-la-connection'
  location: location
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureloganalyticsdatacollector'
    }
    displayName: 'Log Analytics Data Collector'
    parameterValues: {
      username: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
      password: listKeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
    }
  }
}

// Role assignment for Logic App to read VM status
resource logicAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, logicApp.id, 'Reader')
  properties: {
    principalId: logicApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
    principalType: 'ServicePrincipal'
  }
}

// Diagnostic settings for Logic App
resource logicAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${logicApp.name}-diag'
  scope: logicApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output logicAppName string = logicApp.name 
