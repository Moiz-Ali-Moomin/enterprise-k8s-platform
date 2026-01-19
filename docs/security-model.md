# Security Model

## Principles
- **Least Privilege**: RBAC strictly enforced.
- **Defense in Depth**: Network Policies, Pod Security Standards (PSS).
- **Supply Chain Security**: Image scanning and signing.

## Implementation
- **Authentication**: OIDC integration.
- **Authorization**: Kubernetes RBAC.
- **Network Security**: Calico/Cilium policies.
