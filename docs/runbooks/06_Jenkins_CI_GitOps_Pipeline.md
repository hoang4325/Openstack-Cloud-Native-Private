# RUNBOOK 06 — Jenkins CI/CD → GitHub PR → Argo CD Manual Sync

**Trạng thái:** Có bằng chứng pipeline backend từng chạy `SUCCESS`, tạo branch và PR; không được hiểu là toàn bộ frontend pipeline hoặc GitHub Actions hiện tại đã được kiểm thử xanh.

## 1. Hai repository

1. **Application repo:** `hoang4325/springboot-react-mongo-deploy` (Jenkins Groovy pipeline/backend/frontend và helper script `cicd-using-jenkins/gitops-create-pr.sh`).
2. **Infrastructure GitOps repo:** `hoang4325/Openstack-Cloud-Native-Private`, file triển khai `kubernetes/apps/student-management/backend.yaml` / `frontend.yaml`.

Workflow: Jenkins checkout app → build/test (tùy cấu hình pipeline) → build/push Docker image → helper script tạo PR cập nhật `image:` ở infra repo → review/merge PR → Argo CD manual Sync → rollout Kubernetes.

## 2. Bằng chứng trước đó

- Jenkins pipeline backend chạy script `cicd-using-jenkins/gitops-create-pr.sh backend 9`.
- Nhánh được tạo `ci/jenkins-student-api-9`, commit `a580c60`, PR `#11` trên infra repo; Jenkins job kết thúc `SUCCESS` (đã ghi nhận từ log trước đây).
- Live backend manifest hiện dùng `hoang4325/student-app-api:9`; runtime health/Prometheus metrics đã kiểm chứng.
- **Chưa có đủ log chứng minh frontend pipeline đã làm tương tự và mọi bước test tự động đều pass.**

## 3. Quy trình phát hành

1. Kiểm tra nguồn commit/build ứng dụng, Docker image tag bất biến, kết quả unit/integration tests nếu pipeline có chạy.
2. Xác nhận image đã push registry, truy xuất được từ worker.
3. Kiểm tra PR GitOps chỉ đổi image tag mục tiêu; không đổi PVC/Secret/nodeSelector/trạng thái prune.
4. Merge PR sau code review; trên Argo CD `student-management`: **Hard Refresh → Diff → Sync** thủ công.
5. Theo dõi:

```bash
kubectl -n argocd get application student-management
kubectl -n student rollout status deployment/student-api --timeout=120s
kubectl -n student get pods -l app=student-api -o wide
kubectl -n student get deploy student-api -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl -n student logs deployment/student-api --tail=100
```

6. Xác minh endpoint `/actuator/health` và nghiệp vụ, metrics; lưu commit SHA, image tag, PR và release time trong release notes.

## 4. Secret/security

- Jenkins credential `docker-hub-credentials` dùng cho Docker Registry; `github-gitops-token` là PAT cho GitOps PR (nếu đang dùng đúng SETUP của bundle).
- Không in token trong log, không commit credentials vào repo; giới hạn quyền token chỉ cho repo GitOps, Contents/PR phù hợp.
- `Jenkinsfile` là mã có thể được thực thi trên build agent: hạn chế quyền sửa job/source, kiểm soát pull request từ nguồn không tin cậy.

## 5. Rollback và failure handling

- **Build fail:** kiểm tra console log, test failures, Docker daemon, network registry; không Sync GitOps.
- **PR fail:** kiểm tra GitHub token permissions, ref/branch conflicts, nội dung diff; không chỉnh thẳng cluster để bỏ qua PR.
- **Deployment fail/HTTP 502:** tìm image tag ổn định đã biết, revert PR GitOps thay image, merge + Argo manual Sync và verify.
- Nếu API không kết nối MongoDB vì `MONGO_URL`/Secret sai, kiểm tra reference/permission/endpoint; không xuất giá trị Secret ra terminal.

## 6. GitHub Actions trong infrastructure repo — phân biệt với Jenkins

`.github/workflows/ci.yml` hiện khai báo checks Terraform/Ansible/Helm, **không phải Jenkins deploy pipeline**. Theo Git tree `master` kiểm tra 29/10/2026, workflow có bước tham chiếu `helm/storage/*`, `helm/monitoring/*` nhưng các file này **không xuất hiện trong Git tree**, do đó không khẳng định CI workflow hiện tại hoạt động xanh. Cần sửa workflow cho phù hợp sau refactor, sau đó kiểm tra Actions run thật.

## 7. Checklist release

- [ ] Jenkins build SUCCESS và image push thành công cho *release hiện tại*.
- [ ] PR chỉ đổi image tag, đã review/merge.
- [ ] Argo CD `student-management` Synced/Healthy.
- [ ] API/Frontend health và request nghiệp vụ thành công.
- [ ] Monitoring không có alert nghiêm trọng sau rollout.

**Evidence:** log Jenkins trước đây (`backend 9`, commit `a580c60`, PR `#11`); `jenkins-gitops/SETUP.md` từ bundle chuẩn bị trước đó; manifests GitOps trong infra repo.
