# Danh mục ticket (không chứa root cause)

| Ticket | Chế độ | Mô tả sự cố ban đầu |
|---|---|---|
| [INC-01](tickets/01.md) | INJECT | Một dịch vụ web mới triển khai không có replica nào phục vụ được request; build của ứng dụng đã báo thành công. |
| [INC-02](tickets/02.md) | INJECT | Một Pod thử nghiệm lúc xuất hiện trên cluster nhưng không duy trì trạng thái phục vụ ổn định; ứng dụng liên tục gián đoạn. |
| [INC-03](tickets/03.md) | INJECT | Sau khi tạo workload mới, nhiều phút trôi qua nhưng Pod không được đưa lên node nào. |
| [INC-04](tickets/04.md) | INJECT | Một container cứ chạy ngắn rồi biến mất; hệ thống ghi nhận nhiều lần restart. |
| [INC-05](tickets/05.md) | INJECT | Pod hiển thị Running, nhưng phía client không nhận được response qua Service. |
| [INC-06](tickets/06.md) | INJECT | Phiên bản mới không thể bắt đầu quá trình khởi tạo container dù Pod đã được tạo. |
| [INC-07](tickets/07.md) | INJECT | Một workload gồm nhiều giai đoạn startup không bao giờ đến bước chạy ứng dụng chính. |
| [INC-08](tickets/08.md) | INJECT | Số replica phục vụ thấp hơn yêu cầu trong Deployment, dù các pod cũ vẫn ổn. |
| [INC-09](tickets/09.md) | RUNBOOK | Một ứng dụng biến mất khỏi node trong lúc workload tăng cao; kiểm tra tác động và tìm bằng chứng sau sự cố. |
| [INC-10](tickets/10.md) | INJECT | Request xử lý trong Pod bị chậm rõ rệt khi có tải, dù container không crash. |
| [INC-11](tickets/11.md) | INJECT | Client resolve được tên Service nhưng không nhận phản hồi ứng dụng. |
| [INC-12](tickets/12.md) | QUERY | Một kỹ sư báo cáo không tìm thấy tên dịch vụ qua DNS từ Pod debug; hãy điều tra giả định này bằng các kiểm tra phù hợp. |
| [INC-13](tickets/13.md) | INJECT | Tên Service vẫn phân giải được, nhưng lưu lượng từ Pod client tới một backend bị timeout. |
| [INC-14](tickets/14.md) | INJECT | Hai ứng dụng trong cùng namespace có kết nối không đối xứng; bên gửi không giao tiếp được với một đích cụ thể. |
| [INC-15](tickets/15.md) | INJECT | Đã có backend Healthy, nhưng gửi HTTP qua Service lại không trả response. |
| [INC-16](tickets/16.md) | INJECT | Request đi vào ingress được trả về trang không tìm thấy, trong khi backend trực tiếp trả nội dung đúng. |
| [INC-17](tickets/17.md) | RUNBOOK | Một người dùng báo lỗi 502 qua reverse proxy; dịch vụ có thể vẫn chạy nếu gọi nội bộ. |
| [INC-18](tickets/18.md) | INJECT | Cổng ingress nhận kết nối nhưng request tới hostname của ứng dụng trả 5xx. |
| [INC-19](tickets/19.md) | INJECT | Cùng một URL: có lần trả thành công, có lần thất bại. Không có lỗi DNS rõ ràng. |
| [INC-20](tickets/20.md) | INJECT | Một Pod có thể liên lạc nội bộ nhưng không lấy được dữ liệu từ dịch vụ bên ngoài. |
| [INC-21](tickets/21.md) | RUNBOOK | Một node trước đó Ready hiện không đáp ứng; một số workload có dấu hiệu bị ảnh hưởng. |
| [INC-22](tickets/22.md) | RUNBOOK | Kubelet tại một worker không còn báo trạng thái bình thường; API vẫn truy vấn được các node khác. |
| [INC-23](tickets/23.md) | RUNBOOK | Node liên tục báo áp lực bộ nhớ; một số workload bắt đầu mất ổn định. |
| [INC-24](tickets/24.md) | RUNBOOK | Node gặp cảnh báo về dung lượng filesystem và Pod có thể không được tạo thêm. |
| [INC-25](tickets/25.md) | RUNBOOK | Khởi tạo process mới trên một node thường xuyên thất bại dù còn tài nguyên CPU/RAM. |
| [INC-26](tickets/26.md) | INJECT | Deployment thiếu Pod sau khi thay đổi điều kiện hạ tầng; các node khác vẫn hoạt động. |
| [INC-27](tickets/27.md) | RUNBOOK | Pod chạy ở các node khác nhau không giao tiếp ổn định; một số route nội bộ không hoạt động. |
| [INC-28](tickets/28.md) | RUNBOOK | Lệnh kubectl phản hồi chậm hoặc timeout trong những khoảng thời gian nhất định. |
| [INC-29](tickets/29.md) | RUNBOOK | Các Pod hoạt động nhưng lệnh xem mức sử dụng tài nguyên trực tiếp không trả số liệu. |
| [INC-30](tickets/30.md) | INJECT | Pod chưa được schedule dù báo cáo sử dụng tài nguyên thực tế trên node có vẻ thấp. |
| [INC-31](tickets/31.md) | INJECT | Trong dashboard giám sát, một endpoint vừa thêm không cung cấp mẫu dữ liệu như kỳ vọng. |
| [INC-32](tickets/32.md) | INJECT | Một thành phần được cho là đã bị scrape, nhưng dashboard metric nghiệp vụ không hiện dữ liệu. |
| [INC-33](tickets/33.md) | INJECT | Đã khai báo nguồn metrics mới, tuy nhiên tìm trong Target list không thấy nguồn mong đợi. |
| [INC-34](tickets/34.md) | QUERY | Grafana hiển thị No data cho một biểu đồ mà người dùng tin rằng phải có số liệu. |
| [INC-35](tickets/35.md) | RUNBOOK | Một node thiếu khỏi bảng thống kê toàn cluster, hai node khác vẫn hiển thị. |
| [INC-36](tickets/36.md) | RUNBOOK | Hệ thống thu thập metrics gặp vấn đề về ổn định khi tải lớn và lịch sử dữ liệu có khoảng trống. |
| [INC-37](tickets/37.md) | RUNBOOK | Một dashboard không thể xem lại dữ liệu tuần trước dù hiện tại biểu đồ vẫn cập nhật. |
| [INC-38](tickets/38.md) | INJECT | Người vận hành tạo một rule nhưng không tìm thấy kết quả đánh giá tương ứng. |
| [INC-39](tickets/39.md) | INJECT | Một cảnh báo luôn ở trạng thái chưa kích hoạt hoàn toàn dù chỉ số kiểm tra đã thỏa mãn điều kiện quan sát. |
| [INC-40](tickets/40.md) | RUNBOOK | Một cảnh báo hiển thị trong Prometheus nhưng người trực ca không nhận được thông báo nào. |
| [INC-41](tickets/41.md) | RUNBOOK | GitOps hiển thị trạng thái khác nhau giữa manifest trên Git và tài nguyên đang chạy. |
| [INC-42](tickets/42.md) | RUNBOOK | Một Argo CD Application báo sức khỏe không tốt sau khi sync. |
| [INC-43](tickets/43.md) | RUNBOOK | Code đã merge, pipeline báo thành công, nhưng thay đổi chưa xuất hiện trong cluster. |
| [INC-44](tickets/44.md) | RUNBOOK | Thay đổi values dẫn đến pipeline hoặc bước dựng manifest thất bại trước khi deploy. |
| [INC-45](tickets/45.md) | RUNBOOK | Người trực ca sửa trực tiếp một đối tượng Kubernetes nhưng vài phút sau thay đổi biến mất. |
| [INC-46](tickets/46.md) | RUNBOOK | Manifest một tài nguyên đã bị xóa khỏi Git nhưng tài nguyên vẫn tồn tại trong cluster. |
| [INC-47](tickets/47.md) | RUNBOOK | Một loại custom resource không thể được đồng bộ dù file YAML đã có trong Git. |
| [INC-48](tickets/48.md) | INJECT | Sau rollout, phiên bản mới không trở thành phiên bản đang phục vụ. |
| [INC-49](tickets/49.md) | RUNBOOK | VM OpenStack đang được báo là ACTIVE nhưng không thể SSH tới từ mạng quản trị. |
| [INC-50](tickets/50.md) | RUNBOOK | VM có IP private nhưng không thể truy cập dịch vụ ngoài Internet. |
| [INC-51](tickets/51.md) | RUNBOOK | Một VM tạo qua Nova không vào trạng thái ACTIVE, request tạo máy thất bại. |
| [INC-52](tickets/52.md) | RUNBOOK | Ứng dụng Pending vì thiếu tài nguyên trên node; hypervisor lại có vẻ còn dư. |
| [INC-53](tickets/53.md) | RUNBOOK | Một yêu cầu PersistentVolumeClaim không nhận được volume sau nhiều phút. |
| [INC-54](tickets/54.md) | RUNBOOK | Volume đã tồn tại nhưng Pod gắn volume không thể vào Running. |
| [INC-55](tickets/55.md) | RUNBOOK | Một volume trên OpenStack tiếp tục hiển thị đang sử dụng sau khi VM/Pod đã thay đổi. |
| [INC-56](tickets/56.md) | RUNBOOK | Quá trình IaC dừng giữa chừng; tài nguyên trên OpenStack và danh sách Terraform quản lý không khớp. |
| [INC-57](tickets/57.md) | INJECT | Tự động hóa chạy không báo lỗi, nhưng sau deploy dịch vụ vẫn không tiếp nhận traffic. |
| [INC-58](tickets/58.md) | INJECT | Pipeline publish artifact báo thành công nhưng workload chưa phục vụ được phiên bản mới. |
| [INC-59](tickets/59.md) | RUNBOOK | Release mới đã được thực hiện nhưng client vẫn nhận giao diện hoặc API version cũ. |
| [INC-60](tickets/60.md) | INJECT | Website vẫn trả HTTP 200 và Pod Running, nhưng latency tăng bất thường. |
