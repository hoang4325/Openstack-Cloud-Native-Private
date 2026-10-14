# Cinder CSI Automation & Operations

## State and ownership

- `kube-system/cinder-csi` remains an **existing Helm-managed** release, chart `cpo/openstack-cinder-csi` 2.36.2.
- Cloud credentials stay in existing Secret `kube-system/cinder-csi-cloud-config`, key `cloud.conf`, and are never committed to GitHub.
- StorageClass `cinder-lvm` is owned by Argo CD Application `storageclass-cinder`.
- `gitops/examples/cinder-csi-application.yaml` is a future ownership migration example. Do **not** sync it against the current Helm-managed release.

## Rerunnable Ansible process

Run on the `devops` Ansible control machine, with working SSH access to `k8s-control-01`:

```bash
ansible-playbook -i ansible/inventory/hosts.ini \
  ansible/playbooks/manage-cinder-csi.yml
```

On an existing release at chart version 2.36.2, the playbook checks the Secret, renders the pinned chart, verifies CSI driver and StorageClass, and **does not perform helm upgrade**. On a new cluster with no release, it installs CSI using the existing Secret. To intentionally change an existing release, after change review and maintenance preparation, use:

```bash
ansible-playbook -i ansible/inventory/hosts.ini \
  ansible/playbooks/manage-cinder-csi.yml -e cinder_csi_allow_upgrade=true
```

The opt-in is not a full change-safety guarantee; compare chart/values with installed release and back up credentials/release state first. This playbook does not create any Secret, physical storage or Cinder LVM loopback pool. Keep their recovery and provisioning managed separately.

## Current monitoring persistence

All three have been confirmed functional in this lab as of 2026-10-14:

| Workload | PVC capacity | Persistence test |
|---|---:|---|
| Grafana | 3Gi | Dashboard retained after Pod recreation |
| Alertmanager | 2Gi | Test silence retained after Pod recreation |
| Prometheus | 10Gi | 11 query samples identical before/after Pod recreation |

The GitOps monitoring Application is manual-sync (`automated.enabled=false`); keep it that way until persistence migrations and changes have been reviewed.

## Verification

```bash
helm -n kube-system status cinder-csi
kubectl get csidriver cinder.csi.openstack.org
kubectl get storageclass cinder-lvm
kubectl -n monitoring get pods,pvc
kubectl -n argocd get applications
kubectl get volumeattachments
```

**Important:** Pod/PVC restarts are not off-host backups. The file-backed LVM thin pool is a single failure domain. Do not run `pvcreate` or `vgcreate` against the existing VG and do not enable HAProxy on the Kolla-AIO VIP without a separate architecture/change plan.

## GitHub Actions

`.github/workflows/infrastructure-validation.yml` runs Terraform format+validate, Ansible syntax check and focused CSI playbook lint, and offline Helm rendering. CI does not deploy, retrieve runtime secrets, run Terraform apply, or require SSH access to the existing cluster.
