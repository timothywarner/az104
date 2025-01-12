# AZ-104 Sample Landing Zone

This landing zone implementation demonstrates a simplified but production-ready Azure environment based on the [Cloud Adoption Framework (CAF)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/). It's designed to be both exam-relevant and practical for real-world scenarios.

## Architecture Overview

This landing zone implements a simplified version of the CAF enterprise-scale landing zone with:

- Hub-spoke network topology
- Centralized security and governance
- Core platform services
- Workload separation

![Landing Zone Architecture](landing-zone-architecture.png)

## Components

1. **Management Groups Structure**
   - Root Management Group
   - Platform Management Group
   - Landing Zones Management Group

2. **Foundational Components**
   - Hub Virtual Network (shared services)
   - Azure Firewall
   - Azure Bastion
   - Log Analytics Workspace
   - Key Vault

3. **Security & Governance**
   - Built-in and Custom RBAC Roles
   - Azure Policy Assignments
   - Network Security Groups
   - Resource Locks

4. **Landing Zone (Spoke)**
   - Workload Virtual Network
   - Network Peering
   - Application Gateway
   - Sample Web App deployment

## Implementation Steps

1. **Foundation Setup**
   ```powershell
   # Deploy management group hierarchy
   # Deploy hub network infrastructure
   # Configure core platform services
   ```

2. **Security Configuration**
   ```powershell
   # Apply RBAC roles
   # Assign Azure Policies
   # Configure network security
   ```

3. **Landing Zone Deployment**
   ```powershell
   # Deploy spoke network
   # Configure network peering
   # Deploy sample workload
   ```

## Deployment

The landing zone is implemented using Infrastructure as Code (IaC) with Bicep templates, organized in a modular structure:

```
landing-zone/
├── bicep/
│   ├── main.bicep                 # Main deployment template
│   ├── modules/
│   │   ├── hub-network.bicep      # Hub network configuration
│   │   ├── spoke-network.bicep    # Spoke network configuration
│   │   ├── security.bicep         # Security configurations
│   │   └── monitoring.bicep       # Monitoring resources
├── scripts/
│   ├── deploy.ps1                 # Deployment script
│   └── configure-policy.ps1       # Policy configuration
└── policies/
    └── custom-policies.json       # Custom Azure policies
```

## Learning Objectives

This sample landing zone helps you understand:

1. How to implement a secure baseline architecture
2. Management group and subscription organization
3. Network topology and security in Azure
4. Policy-based governance
5. Infrastructure as Code practices

## Next Steps

1. Review the architecture diagram
2. Examine the Bicep templates
3. Deploy the foundation components
4. Configure security and governance
5. Deploy a sample workload

## References

- [Microsoft Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Azure Landing Zone Reference Architecture](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

