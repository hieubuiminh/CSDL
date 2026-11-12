# Các điểm cần hoàn thiện nếu mở rộng sang nghiệp vụ thực tế

Đây là ghi chú thiết kế trước lần đối chiếu PDF ngày 09/11/2026. SQL và backend đã được sửa tiếp theo báo cáo; tình trạng mới nhất xem [bản đối chiếu](DOI_CHIEU_BAO_CAO_SQL.md). CSDL Docker đang chạy chưa thay đổi. Các đề xuất mở rộng ngoài báo cáo dưới đây chưa được tự động áp dụng đầy đủ.

## Ràng buộc và xử lý dữ liệu nên ưu tiên

| Điểm cần kiểm soát | Hiện trạng | Đề xuất |
|---|---|---|
| Ngày sinh, ngày mất và ngày an táng | Backend đã kiểm tra sinh người mất ≤ mất, sinh người khai ≤ đăng ký, an táng ≥ mất. SQL gốc chưa kiểm tra các quan hệ này. | Bảo đảm cả khi thêm và sửa ở các bảng liên quan. Không bắt ngày an táng phải sau ngày đăng ký, vì hồ sơ có thể được đăng ký sau an táng. |
| Thời gian tương lai | Backend chưa chặn ngày mất, cấp giấy và đăng ký ở tương lai. | Với dữ liệu thực tế đã xảy ra, đối chiếu thời điểm hiện tại theo giờ Việt Nam. Tách ngày dự kiến nếu hệ thống cần ghi kế hoạch. |
| Công dân đã có trong hệ thống | Đã bỏ `INSERT IGNORE`; tái sử dụng công dân có CCCD mà không ghi đè thông tin. Việc đối chiếu mâu thuẫn thông tin vẫn cần hoàn thiện. | Đọc bản ghi hiện có và kiểm tra thông tin mâu thuẫn; dùng ngày sinh đã xác minh khi kiểm tra hồ sơ. Không âm thầm bỏ qua xung đột họ tên/ngày sinh. |
| Giấy báo tử đúng người | SQL mới có UNIQUE số giấy trong hồ sơ; `Giay_Bao_Tu` vẫn chưa liên kết trực tiếp với công dân. | UNIQUE ngăn dùng lại giấy cho hai hồ sơ. Nếu quản lý riêng việc cấp giấy trước đăng ký, cần liên kết giấy với người mất ngay khi cấp; nếu quản lý lịch sử, cần mô hình linh hoạt hơn. |
| Giá trị danh mục và chuỗi rỗng | Một số cột là VARCHAR/NOT NULL, vẫn có thể nhận chuỗi rỗng hoặc giá trị tùy ý. | Chuẩn hóa trạng thái, giới tính, hình thức an táng theo danh mục đã thống nhất; kiểm tra tên/mã không chỉ gồm khoảng trắng, độ dài theo cột. |
| Trạng thái và thời điểm công nhận | Bản theo PDF dùng Chờ xử lý/Đã duyệt/Từ chối; chỉ hồ sơ không từ chối mới cập nhật công dân Đã mất. Chưa có quy trình chuyển trạng thái có lịch sử. | Chốt luồng tiếp nhận → xử lý → duyệt/từ chối và quyền duyệt. Nếu cho nộp lại sau từ chối, phân biệt hồ sơ yêu cầu với bản ghi khai tử hợp lệ thay vì cấm mọi lần nộp bằng UNIQUE người mất. |
| Trách nhiệm cán bộ | `App_User` chưa gắn với `Can_Bo`; API nhận mã cán bộ do biểu mẫu gửi lên. | Nếu cần xác định người thao tác, gắn tài khoản với cán bộ và ghi nhật ký người tạo, sửa, duyệt. |
| UBND tiếp nhận trong quá khứ | Giao diện suy ra UBND qua đơn vị công tác hiện tại của cán bộ. | Lưu đơn vị tiếp nhận tại thời điểm lập hồ sơ hoặc lịch sử công tác; chuyển đơn vị cán bộ không được làm đổi UBND trên hồ sơ cũ. |
| Xóa dữ liệu | API xóa hồ sơ có thể xóa luôn công dân không còn được hồ sơ khác sử dụng, dù công dân tồn tại từ trước. | Với dữ liệu dùng lâu dài, giữ thông tin công dân và lịch sử xử lý; dùng trạng thái hủy/thu hồi theo quy trình thay cho xóa toàn bộ. |

Không nên thêm giới hạn tuổi tối thiểu của người đi khai hoặc ép chỉ người thân mới được khai nếu chưa xác định căn cứ và phạm vi nghiệp vụ. Nếu kiểm tra người khai còn sống, phải đối chiếu thời điểm đăng ký của hồ sơ lịch sử, không chỉ nhìn trạng thái hiện tại.

## Những chỗ mô hình đang quá chặt so với hồ sơ thực tế

Theo Điều 4 khoản 2 của [văn bản hợp nhất Nghị định 123/2015/NĐ-CP, cập nhật 2025](https://datafiles.chinhphu.vn/cpp/files/vbpq/2025/3/1069-vbhn-btp.pdf), thông tin định danh người chết được ghi khi có; căn cứ khai tử có thể là giấy báo tử hoặc giấy tờ thay thế, với nhiều loại cơ quan cấp.

Từ đó, đề xuất thiết kế:

- Không dùng CCCD bắt buộc làm định danh nội bộ duy nhất cho mọi trường hợp; cân nhắc mã người riêng và định danh/giấy tờ tùy từng trường hợp.
- Không bắt mọi hồ sơ phải có cơ sở y tế. Bổ sung loại giấy tờ và cơ quan cấp, giữ cơ sở y tế khi phù hợp.
- Hỗ trợ mức độ đầy đủ của ngày sinh để tránh buộc nhập ngày/tháng giả khi chỉ biết năm sinh.

Đây là suy luận thiết kế từ yêu cầu hồ sơ, không phải danh sách đầy đủ quy định pháp lý. [Hướng dẫn đăng ký khai tử của Báo Chính phủ](https://thanglong.baochinhphu.vn/huong-dan-cong-dan-thuc-hien-thu-tuc-dang-ky-khai-tu-truc-tuyen-tren-cong-dich-vu-cong-quoc-gia-103251224172050895.htm) cũng đề cập chứng cứ về sự kiện chết trong trường hợp đã chết lâu mà không có giấy báo tử.

Với phạm vi đồ án hiện tại, ưu tiên hoàn thiện ba quy tắc đã nêu, đối chiếu công dân có sẵn, liên kết giấy báo tử đúng người và giữ lịch sử hồ sơ. Các thay đổi mô hình lớn cần thống nhất trước khi sửa SQL gốc.
