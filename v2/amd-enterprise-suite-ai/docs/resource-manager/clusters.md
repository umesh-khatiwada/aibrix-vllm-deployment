# Clusters

A **cluster** is a group of AMD GPU nodes managed by the platform. The Resource Manager shows you the health, capacity, and utilization of all connected clusters.

---

## Clusters Overview

Go to **Resource Manager → Clusters** to see:

- Connected clusters and their status (healthy / degraded / offline)
- Node count and GPU types (e.g., MI300X, MI250)
- Total and available GPU resources
- Kubernetes namespace assignments per project

---

## Accessing a Cluster

Advanced users can access the cluster directly via `kubectl` for debugging or manual workload management.

Go to **Resource Manager → Workloads → Accessing the Cluster** for instructions on setting up `kubeconfig`.

---

## Monitoring Utilization

The Resource Manager dashboard shows real-time GPU, CPU, and memory utilization. For a detailed tutorial, see:

 [Resource Utilization Tutorial](https://enterprise-ai.docs.amd.com/en/latest/resource-manager/tutorials/resource-utilization.html)

---

## Official Reference

 [Clusters Docs](https://enterprise-ai.docs.amd.com/en/latest/resource-manager/clusters/overview.html)
