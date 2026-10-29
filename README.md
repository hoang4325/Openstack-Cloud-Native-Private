# OpenStack Cloud-Native Private Infrastructure Lab

> **OpenStack · Terraform · Ansible · Kubernetes · Calico · Cinder CSI · Argo CD · Jenkins · Prometheus · Grafana · MongoDB · NFS**

Hệ thống **Private Cloud Lab** được xây dựng trên **OpenStack All-in-One (Kolla-Ansible)**, cung cấp hạ tầng máy ảo cho cụm **Kubernetes 4 node**. Các tài nguyên cloud được quản lý bằng Terraform; Ansible đảm nhiệm cấu hình node và nền tảng Kubernetes; Argo CD đồng bộ ứng dụng theo GitOps. Hệ thống tích hợp ứng dụng Student Management, lưu trữ Cinder CSI, giám sát tập trung và sao lưu MongoDB sang NFS Server bên ngoài OpenStack.

## 1. Sơ đồ kiến trúc tổng thể

![Kiến trúc tổng thể OpenStack Cloud-Native Private Lab](docs/architecture/Ki%E1%BA%BFn%20tr%C3%BAc%20t%E1%BB%95ng%20th%E1%BB%83%20h%E1%BB%87%20th%E1%BB%91ng%20.png)

Kiến trúc kết hợp các lớp **Infrastructure as Code → Kubernetes Platform → GitOps & Applications → Observability → Backup & Recovery**.

## 2. Các lớp kiến trúc

| Lớp | Thành phần | Vai trò |
|---|---|---|
| Private Cloud | OpenStack Kolla-Ansible AIO | Cung cấp compute, network, image và block storage |
| Infrastructure as Code | Terraform | Quản lý image, flavor, keypair, Neutron network, router, security group, port, VM và floating IP |
| Configuration Management | Ansible | Cấu hình Ubuntu, containerd, Kubernetes, Calico và các dịch vụ nền tảng |
| Container Orchestration | Kubernetes (kubeadm) | Điều phối container trên bốn node |
| Container Networking | Calico CNI | Cung cấp kết nối mạng giữa các Pod |
| Ingress | Traefik | Định tuyến HTTP đến ứng dụng thông qua Ingress và NodePort |
| GitOps | Argo CD, Kustomize, Helm | Quản lý cấu hình ứng dụng và thành phần monitoring từ Git |
| Application | React, Spring Boot, MongoDB | Ứng dụng Student Management và cơ sở dữ liệu |
| Persistent Storage | OpenStack Cinder CSI | Cấp phát PersistentVolume cho workload Kubernetes |
| Observability | Prometheus, Grafana, Alertmanager | Thu thập metrics, trực quan hóa và gửi cảnh báo |
| Backup & Recovery | Kubernetes CronJob, Tailscale, NFS | Sao lưu MongoDB định kỳ đến máy chủ độc lập với OpenStack |

## 3. OpenStack và hạ tầng mạng

OpenStack được triển khai theo mô hình **All-in-One**, sử dụng các dịch vụ chính:

- **Keystone:** quản lý xác thực và định danh.
- **Nova:** quản lý vòng đời máy ảo Kubernetes.
- **Neutron:** quản lý tenant network, subnet, router, security group và floating IP.
- **Glance:** quản lý image Ubuntu dành cho VM.
- **Cinder:** cung cấp block volume cho Kubernetes thông qua Cinder CSI.

Terraform chia thành hai environment: `foundation` quản lý tài nguyên nền tảng; `k8s-cluster` quản lý tenant network và các VM Kubernetes. Ansible sử dụng inventory được tạo từ Terraform outputs để cấu hình các node.

| Mạng | CIDR | Mục đích |
|---|---|---|
| Tenant network | `10.20.0.0/24` | Giao tiếp giữa các VM Kubernetes |
| External/provider network | `172.30.0.0/24` | Floating IP và truy cập từ ngoài tenant network |
| Kubernetes Pod CIDR | `192.168.0.0/16` | Mạng Pod do Calico quản lý |
| Kubernetes Service CIDR | `10.96.0.0/12` | Địa chỉ ảo của Kubernetes Services |

## 4. Kubernetes Cluster — 4 nodes

Cụm Kubernetes chạy trên bốn máy ảo Ubuntu do OpenStack cấp phát, sử dụng **containerd**, **kubeadm** và **Calico CNI**.

| Node | Fixed IP | Vai trò chính |
|---|---|---|
| `k8s-control-01` | `10.20.0.10` | Control plane: API Server, Scheduler, Controller Manager và etcd |
| `k8s-worker-01` | `10.20.0.11` | Worker cho các thành phần nền tảng và dịch vụ Kubernetes |
| `k8s-monitoring-01` | `10.20.0.12` | Worker dành cho Prometheus, Grafana, Alertmanager và MongoDB Exporter |
| `k8s-deploy-01` | `10.20.0.13` | Worker chạy Student Management, MongoDB và Backup Job |

Các workload được phân bố qua **labels/nodeSelector**, trong đó ứng dụng Student Management sử dụng node có nhãn `workload=student-app`.

## 5. Ứng dụng Student Management

Ứng dụng nằm trong namespace **`student`**, gồm các workload và Kubernetes Services:

| Thành phần | Công nghệ | Kubernetes resource / Service | Chức năng |
|---|---|---|---|
| Frontend | React | `Deployment/student-web`, `Service/web:80` | Giao diện người dùng |
| Backend | Spring Boot | `Deployment/student-api`, `Service/api:8080` | Xử lý API và nghiệp vụ |
| Database | MongoDB | `StatefulSet/mongodb`, `Service/mongodb:27017` | Lưu trữ dữ liệu ứng dụng |
| Metrics Exporter | Percona MongoDB Exporter | `Deployment/mongodb-exporter`, `Service/mongodb-exporter:9216` | Xuất metrics MongoDB cho Prometheus |

**Luồng truy cập:** `Browser → Traefik Ingress (student.lab.test) → student-web` và các yêu cầu API được backend `student-api` xử lý; backend kết nối tới MongoDB thông qua Service nội bộ.

Traefik là Ingress Controller của cluster, sử dụng HTTP NodePort **`30080`**. Các thành phần nội bộ giao tiếp bằng Kubernetes Service/DNS thay vì kết nối trực tiếp đến Pod IP.

## 6. CI/CD và GitOps

Kiến trúc tách riêng quá trình **build và phát hành image** và quá trình **đồng bộ trạng thái ứng dụng lên cluster**:

1. Developer thay đổi mã nguồn hoặc manifest trên GitHub.
2. **GitHub Actions** kiểm tra cấu hình Terraform, Ansible và Helm của repository hạ tầng.
3. **Jenkins** phục vụ pipeline ứng dụng: build frontend/backend, đẩy container image và cập nhật manifest thông qua quy trình Git/PR.
4. **Argo CD** theo dõi desired state từ GitHub hoặc Helm chart và đồng bộ Kubernetes resources bằng quy trình **Sync có kiểm soát**.

Các Argo CD Applications của hệ thống:

| Application | Nguồn cấu hình | Đối tượng quản lý |
|---|---|---|
| `student-management` | `kubernetes/apps/student-management/` | React frontend, Spring Boot backend, Ingress, ServiceMonitor và API alerts |
| `student-mongodb` | `kubernetes/databases/student-mongodb/` | MongoDB StatefulSet, Exporter, Backup CronJob và MongoDB alerts |
| `monitoring` | Helm chart `kube-prometheus-stack` | Prometheus Operator, Prometheus, Grafana, Alertmanager và thành phần giám sát |

## 7. Persistent Storage — OpenStack Cinder CSI

**Cinder CSI** kết nối Kubernetes với block storage của OpenStack. Các PVC được cấp phát từ StorageClass **`cinder-lvm`**, sử dụng provisioner `cinder.csi.openstack.org` và chính sách `reclaimPolicy: Retain`.

Luồng lưu trữ: `Kubernetes PVC → Cinder CSI → OpenStack Cinder Volume → Mount vào Pod`.

PersistentVolume được sử dụng cho **MongoDB** (`mongo-data-mongodb-0`, yêu cầu `5Gi`) và các dịch vụ có trạng thái như **Prometheus, Grafana, Alertmanager**.

## 8. Observability — Metrics, Dashboards và Alerts

Hệ thống monitoring được triển khai bằng **kube-prometheus-stack**, tập trung trên `k8s-monitoring-01`:

- **Prometheus:** thu thập metrics của node, Pod, Kubernetes và các ứng dụng.
- **kube-state-metrics / node-exporter:** cung cấp thông tin trạng thái Kubernetes và tài nguyên node.
- **Spring Boot Actuator + Micrometer:** xuất metrics API qua `/actuator/prometheus` và health qua `/actuator/health`.
- **MongoDB Exporter:** xuất metrics kết nối và hoạt động của MongoDB qua `/metrics`.
- **ServiceMonitor / PrometheusRule:** định nghĩa mục tiêu thu thập và các quy tắc cảnh báo.
- **Grafana:** truy vấn Prometheus và hiển thị dashboard.
- **Alertmanager:** định tuyến cảnh báo đến **Telegram** qua `AlertmanagerConfig`.

**Luồng giám sát:** `Kubernetes / Spring Boot / MongoDB Exporter → Prometheus → Grafana`; với cảnh báo: `PrometheusRule → Alertmanager → Telegram`.

Các hostname nội bộ dành cho monitoring gồm `grafana.lab.internal` và `prometheus.lab.internal`.

## 9. MongoDB Backup & Disaster Recovery

MongoDB được sao lưu bằng **Kubernetes CronJob `mongodb-daily-backup`** vào một **NFS Server chạy trên Ubuntu VM của VMware**, nằm ngoài OpenStack AIO.

- **Lịch:** `0 2 * * *` — **02:00 mỗi ngày**, timezone `Asia/Ho_Chi_Minh`.
- **Backup worker:** `k8s-deploy-01`, kết nối NFS qua Tailscale.
- **NFS Server:** `100.127.56.99`.
- **NFS export:** `/srv/nfs/mongodb-backups`.
- **Định dạng:** `mongodump --archive --gzip`, kèm file **SHA-256**.
- **Lưu trữ:** retention khoảng **30 ngày**, thực thi sau khi tạo backup mới.
- **Giám sát:** `MongoDBBackupJobFailed` và `MongoDBBackupStale` qua Prometheus/Alertmanager/Telegram.

**Luồng backup:** `MongoDB → Backup CronJob → NFS mount trên k8s-deploy-01 → Tailscale → NFS Server ngoài OpenStack`.

---

**Repository:** [hoang4325/Openstack-Cloud-Native-Private](https://github.com/hoang4325/Openstack-Cloud-Native-Private)
