# Phase 1: EKS Cluster Provisioning Verification Evidence

Date & Time: 2026-11-20T21:33:55+05:30 (16:03:55 UTC)
Environment: AWS Personal Sandbox (Region: ap-south-1)

## Timings
- Apply Duration: Background task started 2026-11-20T21:18:23+05:30, completed 2026-11-20T21:30:43+05:30 (elapsed: 12 minutes 20 seconds).
- Cluster Resource Creation Reference Points:
  - EKS Control Plane `createdAt`: 2026-11-20T21:18:50.129000+05:30
  - Managed Node Group `createdAt`: 2026-11-20T21:28:02.531000+05:30

---

## 1. Node Status (`kubectl get nodes -o wide`)
```text
NAME                                        STATUS   ROLES    AGE     VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                        KERNEL-VERSION                            CONTAINER-RUNTIME
ip-10-0-1-98.ap-south-1.compute.internal    Ready    <none>   4m37s   v1.37.1-eks-9adbfea   10.0.1.98     <none>        Amazon Linux 2023.12.20261118   6.18.62-127.179.amzn2023.x86_64 (amd64)   containerd://2.3.7+unknown
ip-10-0-2-232.ap-south-1.compute.internal   Ready    <none>   4m37s   v1.37.1-eks-9adbfea   10.0.2.232    <none>        Amazon Linux 2023.12.20261118   6.18.62-127.179.amzn2023.x86_64 (amd64)   containerd://2.3.7+unknown
```

---

## 2. Pod Status (`kubectl get pods -A`)
```text
NAMESPACE     NAME                           READY   STATUS    RESTARTS   AGE
kube-system   aws-node-8vn45                 2/2     Running   0          3m36s
kube-system   aws-node-cpwxp                 2/2     Running   0          3m48s
kube-system   coredns-8966fd9f9-5l9cg        1/1     Running   0          3m48s
kube-system   coredns-8966fd9f9-zg6kv        1/1     Running   0          3m48s
kube-system   eks-pod-identity-agent-kjlm8   1/1     Running   0          3m48s
kube-system   eks-pod-identity-agent-nr2gm   1/1     Running   0          3m49s
kube-system   kube-proxy-xz2gg               1/1     Running   0          3m44s
kube-system   kube-proxy-zq25d               1/1     Running   0          3m48s
```

---

## 3. Kubernetes Version (`kubectl version`)
```text
Client Version: v1.37.2
Kustomize Version: v5.8.1
Server Version: v1.37.1-eks-91f89a9
```

---

## 4. EKS Cluster Details (`aws eks describe-cluster --name eks-platform`)
```json
{
    "version": "1.37",
    "platformVersion": "eks.9",
    "status": "ACTIVE",
    "endpointPublicAccess": true,
    "logging": [
        [
            "api",
            "audit",
            "authenticator"
        ],
        [
            "controllerManager",
            "scheduler"
        ]
    ],
    "createdAt": "2026-11-20T21:18:50.129000+05:30"
}
```

---

## 5. EKS Managed Add-ons (`aws eks describe-addon`)
- **coredns**:
  ```json
  {
      "addonName": "coredns",
      "addonVersion": "v1.14.7-eksbuild.35",
      "status": "ACTIVE"
  }
  ```
- **kube-proxy**:
  ```json
  {
      "addonName": "kube-proxy",
      "addonVersion": "v1.37.0-eksbuild.39",
      "status": "ACTIVE"
  }
  ```
- **vpc-cni**:
  ```json
  {
      "addonName": "vpc-cni",
      "addonVersion": "v1.23.3-eksbuild.2",
      "status": "ACTIVE"
  }
  ```
- **eks-pod-identity-agent**:
  ```json
  {
      "addonName": "eks-pod-identity-agent",
      "addonVersion": "v1.5.0-eksbuild.3",
      "status": "ACTIVE"
  }
  ```

---

## 6. EKS Managed Node Group (`aws eks describe-nodegroup`)
```json
{
    "nodegroupName": "default-20261120155759138000000013",
    "createdAt": "2026-11-20T21:28:02.531000+05:30",
    "instanceTypes": [
        "t3.large"
    ],
    "capacityType": "SPOT",
    "status": "ACTIVE"
}
```
