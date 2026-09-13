# Study 2 — Diễn giải kết quả phân tích SSQ trước/sau mỗi trial

Tài liệu này tóm tắt và diễn giải kết quả của Study 2. Số liệu thống kê đầy đủ nằm ở
`study2_results.txt`; báo cáo chi tiết bằng tiếng Anh ở `study2_report.md`; kiểm tra dữ liệu
ở `study2_data_validation.md`.

**Thiết kế:** 36 người tham gia × 3 phương pháp (Reverse Optical Flow, Minimap, Path Overlay)
× 3 loại video (Walking, Cycling, Driving), within-subject hoàn toàn. SSQ 16 mục được đo
**ngay trước** và **ngay sau** mỗi trial — 324 trial, 648 lần đo SSQ.

---

## Kết luận chính

> Xem video 360° **làm tăng đáng kể và ổn định** mức say chuyển động: điểm SSQ Total Severity
> **tăng gần gấp đôi** từ trước sang sau (+8,4 điểm, +88%, *d*z = 0,90).
>
> **Dùng phương pháp giảm say nào không tạo ra khác biệt đo được** đối với mức tăng đó.
> Tương tác Time × Method — hiệu ứng chính của Study 2 — không có ý nghĩa thống kê trên cả
> bốn thang SSQ (mọi *F* ≤ 0,78; mọi *p* ≥ 0,44; η²_G ≤ 0,001).
>
> **Điều thực sự tạo khác biệt là loại video.** Video Walking gây mức tăng triệu chứng
> **gấp khoảng 2,4 lần** video Driving (Time × Video, *p*_holm = 0,004). Đây là **phát hiện mới:
> Study 1 hoàn toàn không tìm thấy ảnh hưởng của loại video.**
>
> Một phát hiện quan trọng khác cho thiết kế quy trình thí nghiệm: **triệu chứng không hồi phục
> hết giữa các trial.** Điểm POST của trial trước dự đoán mạnh điểm PRE của trial sau
> (*b* = 0,39; *p* < 0,001), và mức say trước trial tăng đều từ trial 2 đến trial 9.

---

## 1. Chất lượng dữ liệu

Tất cả các kiểm tra đều đạt: 324 dòng ở mỗi file, đúng **36 người × 9 trial**, ghép PRE↔POST
được 324/324, không có giá trị thiếu, không trùng lặp, thang điểm mục SSQ đúng 0–3.

Nhưng điểm cần lưu y:

1. **Nhãn phương pháp khác nhau giữa hai file** (`Path overlay` và `Overlay`); một bản ghi video
   có ghi chú *"lúc đầu quên điền"*. Đây chỉ là khác biệt nhãn, không phải khác biệt thiết kế.
2. **Một người nhập sai nhãn POST.** P13 có hai trial ghi Driving và không có Walking trong cả
   khối ROF lẫn Path. File before ghi đúng thiết kế đầy đủ và thứ tự thời gian trong buổi là rõ
   ràng, nên hai trial này được ghép theo thời gian và lấy nhãn từ bản ghi PRE.

## 2. Thống kê mô tả

### Bảng 1 — Thay đổi tổng thể trước → sau (trung bình theo người, n = 36)

| Thang đo | PRE TB (SD) | POST TB (SD) | Δ TB (SD) | KTC 95% của Δ | *p*_holm | *d*z | Mức tăng |
|---|---|---|---|---|---|---|---|
| **TSC** | 9,55 (15,92) | 17,98 (19,86) | **+8,44** (9,38) | [5,27; 11,61] | <0,001 | 0,90 | +88% |
| Nausea | 5,27 (9,32) | 8,54 (9,88) | +3,27 (5,89) | [1,28; 5,26] | 0,004 | 0,55 | +62% |
| Oculomotor | 8,70 (14,36) | 16,45 (19,28) | +7,74 (9,49) | [4,53; 10,95] | <0,001 | 0,82 | +89% |
| Disorientation | 11,86 (21,90) | 24,27 (26,88) | +12,42 (13,92) | [7,71; 17,13] | <0,001 | 0,89 | +105% |

Kiểm định Wilcoxon cho kết quả trùng khớp ở mọi dòng. **Câu hỏi đầu tiên đã có câu trả lời rõ
ràng: điểm SSQ tăng từ PRE sang POST.**

### Bảng 2 — Theo phương pháp (gộp các loại video)

| Phương pháp | PRE TSC | POST TSC | **Δ TSC** | KTC 95% |
|---|---|---|---|---|
| ROF | 9,90 (18,65) | 18,91 (21,18) | **+9,00** (9,56) | [5,77; 12,24] |
| Minimap | 9,38 (15,02) | 18,46 (20,51) | **+9,07** (11,39) | [5,22; 12,93] |
| Path Overlay | 9,35 (19,45) | 16,59 (21,59) | **+7,24** (12,60) | [2,98; 11,50] |

Ba phương pháp xuất phát từ mức PRE gần như giống hệt nhau (9,9 / 9,4 / 9,4). Vì vậy — khác với
trường hợp cảnh báo trong đề bài — thứ tự điểm POST ở đây **không** phải do khác biệt nền.

### Bảng 3 — Theo loại video (gộp các phương pháp)

| Video | PRE TSC | POST TSC | **Δ TSC** | KTC 95% |
|---|---|---|---|---|
| **Walking** | 9,04 (15,11) | 22,13 (21,00) | **+13,09** (11,88) | [9,07; 17,11] |
| Cycling | 9,70 (17,73) | 16,48 (21,01) | +6,79 (12,11) | [2,69; 10,89] |
| Driving | 9,90 (17,94) | 15,34 (19,38) | +5,44 (11,46) | [1,56; 9,31] |

## 3. Phân tích trạng thái trước trial (baseline)

**Mức triệu chứng trước trial không khác nhau theo phương pháp hay theo video.** RM-ANOVA 3 × 3
chỉ trên điểm PRE không cho kết quả nào gần mức ý nghĩa (Method: mọi *p* ≥ 0,77; Video: mọi
*p* ≥ 0,62; Method × Video: mọi *p* ≥ 0,62; mọi η²_G ≤ 0,003).

Đây là cơ sở quan trọng cho toàn bộ phần còn lại: vì người tham gia bước vào các trial ROF,
Minimap và Path với mức triệu chứng như nhau, khác biệt ở điểm POST có thể đọc trực tiếp là
khác biệt do trial gây ra.

## 4. Phân tích chính — RM-ANOVA 2 (Time) × 3 (Method) × 3 (Video)

Hiệu chỉnh Greenhouse–Geisser; η² tổng quát; hiệu chỉnh Holm trên 4 biến phụ thuộc SSQ.

| Hiệu ứng | Thang đo | *F* | df | *p*_holm | η²_G |
|---|---|---|---|---|---|
| **Time** | TSC | **29,15** | 1; 35 | **<0,001** | 0,036 |
| | Nausea | **11,08** | 1; 35 | **0,002** | 0,015 |
| | Oculomotor | **23,97** | 1; 35 | **<0,001** | 0,036 |
| | Disorientation | **28,64** | 1; 35 | **<0,001** | 0,041 |
| **Time × Method** | TSC | 0,67 | 1,48; 51,97 | 1,000 | 0,000 |
| *(hiệu ứng chính)* | Nausea | 0,42 | 1,72; 60,36 | 1,000 | 0,000 |
| | Oculomotor | 0,78 | 1,66; 58,08 | 1,000 | 0,001 |
| | Disorientation | 0,61 | 1,74; 60,88 | 1,000 | 0,000 |
| **Time × Video** | TSC | **7,73** | 1,79; 62,72 | **0,004** | 0,006 |
| | Nausea | 2,93 | 1,99; 69,73 | 0,060 | 0,005 |
| | Oculomotor | **9,61** | 1,91; 66,75 | **0,001** | 0,006 |
| | Disorientation | **6,91** | 1,59; 55,56 | **0,008** | 0,005 |
| **Time × Method × Video** | cả 4 thang | ≤ 0,99 | — | 1,000 | ≤ 0,002 |

**Hiệu ứng đơn của Time trong từng phương pháp:** cả ba đều làm điểm tăng có ý nghĩa —
ROF +9,00; Minimap +9,07; Path +7,24. **Không phương pháp nào giữ được mức say không đổi.**

### Phân tích trên điểm thay đổi (Δ)

RM-ANOVA 3 × 3 trên điểm Δ tái tạo **chính xác** các tương tác Time của mô hình chính — mọi giá
trị *F* trùng khớp đến 4 chữ số thập phân. Với thiết kế within-subject cân bằng đầy đủ thì đây
là **cùng một kiểm định**, nên hai phân tích không thể mâu thuẫn; cách trình bày theo Δ chỉ dễ
diễn giải hơn.

## 5. So sánh từng cặp

### Theo phương pháp — không có hiệu ứng tổng thể nên chỉ mang tính mô tả

| Cặp so sánh | Chênh lệch Δ | KTC 95% | *d*z | *p* (Bonferroni) |
|---|---|---|---|---|
| ROF − Minimap | −0,07 | [−3,24; 3,10] | −0,01 | 1,000 |
| ROF − Path | +1,77 | [−1,19; 4,72] | +0,20 | 0,699 |
| Minimap − Path | +1,84 | [−2,75; 6,42] | +0,14 | 1,000 |

### Theo video — đây mới là hiệu ứng cho phép hậu kiểm

| Cặp so sánh | Chênh lệch Δ TSC | KTC 95% | *d*z | *p* (Bonferroni) |
|---|---|---|---|---|
| **Walking − Cycling** | **+6,30** | [2,00; 10,61] | 0,61 | **0,002** |
| **Walking − Driving** | **+7,65** | [2,27; 13,04] | 0,60 | **0,003** |
| Cycling − Driving | +1,35 | [−4,51; 7,22] | 0,10 | 1,000 |

**Walking là trường hợp khác biệt; Cycling và Driving không phân biệt được với nhau.**

### Kết quả "không có khác biệt" này đáng tin đến mức nào?

Với n = 36, nghiên cứu có lực 80% để phát hiện chênh lệch **4,2–6,5 điểm TSC** giữa các phương
pháp. Kiểm định tương đương (TOST): với biên ±5 TSC, ROF ≡ Minimap (*p* = 0,002) và ROF ≡ Path
(*p* = 0,016); với biên ±15 TSC — tức bằng mức giảm mà Study 1 tìm thấy giữa phương pháp và
Baseline — **cả ba cặp đều tương đương (*p* < 0,001)**.

**Nghĩa là:** dữ liệu **loại trừ** được khác biệt lớn cỡ Study 1 từng báo cáo, nhưng **không**
chứng minh được các phương pháp tương đương tuyệt đối; vẫn không loại trừ được chênh lệch
khoảng 2–6 điểm TSC.

## 6. Thứ tự trial và hiệu ứng tồn dư (carryover)

Cân bằng thứ tự **hoàn hảo**: 6 thứ tự phương pháp × 6 người; 6 thứ tự video × 18 khối; mỗi
phương pháp xuất hiện 12 lần ở mỗi vị trí khối và mỗi video 36 lần ở mỗi vị trí trong khối.

Điều đó chống nhiễu hệ thống — nhưng **không** chứng minh rằng không có carryover. Và thực tế
là **có**.

| Trial | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| PRE TSC trung bình | 20,78 | 4,68 | 7,27 | 6,86 | 7,27 | 9,14 | 9,35 | 9,56 | 11,01 |

RM-ANOVA một chiều: *F*(2,72; 95,24) = 4,07; *p* = 0,011; η²_G = 0,044.

Hình dạng **không** phải một đường tăng đơn giản. Trial 1 cao vượt trội vì **8 trong 36 người
đã có triệu chứng sẵn trước khi tiếp xúc VR** (PRE TSC cao nhất = 157); với vài người trong số
đó, Δ ở trial 1 còn **âm** — họ thấy đỡ hơn sau khi xem. Do đó xu hướng tuyến tính tổng thể
không có ý nghĩa (*p* = 0,543) trong khi thành phần bậc hai thì có (*p* = 0,006).

**Từ trial 2 trở đi, mức tăng là đều đặn: 4,68 → 11,01, tức gấp 2,4 lần.**

### Kiểm định trực tiếp triệu chứng tồn dư

Điểm POST ở trial *t*−1 có dự đoán điểm PRE ở trial *t* không? (288 cặp liên tiếp, hệ số chặn
ngẫu nhiên theo người):

| Mô hình | PrevPost_TSC *b* (SE) | TrialNumber *b* (SE) | Thời gian nghỉ *b* (SE) |
|---|---|---|---|
| `Pre ~ PrevPost` | **0,389 (0,038)**, *p* < 0,001 | — | — |
| `+ TrialNumber` | **0,399 (0,037)**, *p* < 0,001 | **+0,973 (0,233)**, *p* < 0,001 | — |
| `+ RecoveryMinutes` | **0,399 (0,037)**, *p* < 0,001 | **+0,978 (0,238)**, *p* < 0,001 | −0,015 (0,142), *p* = 0,916 |

**Khoảng 40% mức say khi kết thúc một trial vẫn còn khi bắt đầu trial kế tiếp**, cộng thêm
khoảng 1 điểm TSC tích luỹ mỗi trial. Khoảng nghỉ trung vị là 6,3 phút (IQR 5,1–7,3) và — điều
đáng chú ý — **nghỉ lâu hơn không giúp giảm điểm PRE** trong phạm vi đã dùng.

Vị trí khối (*p* = 0,343) và nhóm thứ tự phương pháp (*p* = 0,624) không ảnh hưởng đến PRE TSC,
và đưa chúng vào mô hình cũng không làm thay đổi kết luận về Method.

## 7. Mô hình hỗn hợp và kiểm tra độ bền vững

`Post_X ~ Pre_X + Method × Video + TrialNumber + (1 | Participant)`.

Cấu trúc hiệu ứng ngẫu nhiên: hệ số dốc ngẫu nhiên cho Method bị **suy biến (singular)** và
không được ủng hộ (LRT *p* = 0,835); hệ số dốc cho TrialNumber chỉ được AIC ưu tiên nhẹ nhưng
BIC và LRT thì không (*p* = 0,052). Vì vậy **giữ mô hình chỉ có hệ số chặn ngẫu nhiên**.
ICC theo người: 0,50–0,65.

| Thang đo | Điểm PRE | Method | Video | TrialNumber |
|---|---|---|---|---|
| TSC | *F* = 30,65; **<0,001** | 0,99; 0,373 | 10,13; **<0,001** | 4,16; 0,042 |
| Nausea | 4,24; **0,040** | 1,15; 0,317 | 5,58; **0,004** | 0,26; 0,614 |
| Oculomotor | 38,49; **<0,001** | 1,22; 0,298 | 11,26; **<0,001** | 6,13; 0,014 |
| Disorientation | 50,25; **<0,001** | 0,46; 0,635 | 6,40; **0,002** | 4,13; 0,043 |

**Kết luận về Method không đổi** sau khi hiệu chỉnh cho mức triệu chứng trước trial, tiến trình
trial và phân cụm theo người.

### Kiểm tra giả định

Phân phối Δ có nhiều giá trị 0 (36–60%) và đuôi nặng; phần dư bị bác bỏ chuẩn tính
(Shapiro–Wilk *p* < 0,001). Vì vậy kết luận được kiểm chứng lại bằng **bốn cách độc lập**:

| Cách kiểm tra | Hiệu ứng Method | Hiệu ứng Video |
|---|---|---|
| RM-ANOVA chính | *F* = 0,67; *p* = 0,473 | *F* = 7,73; **p = 0,001** |
| RM-ANOVA trên hạng (xếp hạng trong từng người) | *F* = 0,83; *p* = 0,438 | *F* = 13,38; **p < 0,001** |
| Friedman | χ²(2) = 3,66; *p* = 0,160 | χ²(2) = 13,39; **p = 0,001** |
| Mô hình hỗn hợp, loại ngoại lai | *F* = 0,81; *p* = 0,444 | *F* = 7,12; **p < 0,001** |

**Không xoá giá trị ngoại lai.** 5/324 trial (1,5%) nằm ngoài hàng rào 3×IQR; loại bỏ chúng
không làm thay đổi kết luận nào.

## 8. Bổ sung — Presence

Thang Presence 5 mục (Cronbach's α = 0,784) **không khác biệt giữa các phương pháp**:
ROF 5,10; Minimap 5,12; Path 5,04; *F*(1,84; 64,48) = 0,25; *p* = 0,758. Presence không tương
quan với mức tăng triệu chứng (*r* = −0,04; *p* = 0,825).

Điều này quan trọng đối với mạch chuyện của Study 1: đánh đổi trung tâm của Study 1 là
**Dynamic FOV** giảm TSC nhiều nhất nhưng làm giảm Presence có ý nghĩa. **Study 2 không có điều
kiện Dynamic FOV, và không phương pháp nào trong ba phương pháp này phải trả giá về Presence.**

## 9. So sánh với Study 1

| | Study 1 | Study 2 |
|---|---|---|
| Điều kiện | 4 phương pháp (có Baseline) × 3 video | 3 phương pháp (**không có Baseline**) × 3 video |
| Thời điểm đo SSQ | chỉ sau trial | **trước *và* sau mỗi trial** |
| Hiệu ứng Method | **có ý nghĩa**, *F* = 9,02; *p* < 0,001; η²_G = 0,043 | **không**, *F* = 0,67; *p* = 0,473 |
| Hiệu ứng Video | không, *F* = 1,51; *p* = 0,230 | **có ý nghĩa**, *p*_holm = 0,004 |
| Method × Video | không | không (trùng khớp) |
| Presence | **khác nhau theo phương pháp** | **không khác nhau** (đều ≈ 5,1) |
| Mức POST TSC tuyệt đối | 42–78 | **15–26** |

Ba khác biệt cần nói rõ thay vì làm mờ đi:

1. **Hiệu ứng Method đảo chiều — nhưng hai nghiên cứu thực ra nhất quán.** Hiệu ứng có ý nghĩa
   ở Study 1 hoàn toàn do so sánh *phương pháp với Baseline*; hậu kiểm của chính Study 1 **không
   tìm thấy khác biệt giữa Dynamic FOV, Minimap và Overlay Path**. Study 2 bỏ Baseline và chỉ so
   sánh các phương pháp giảm say với nhau — và không tìm thấy gì. **Cả hai đều nói: các phương
   pháp giảm say không khác nhau.** Study 2 bổ sung rằng điều này đúng cho *mức thay đổi do
   trial gây ra*, chứ không chỉ cho mức sau phơi nhiễm, và bổ sung thêm ROF vào nhóm so sánh.

2. **Hiệu ứng Video đảo chiều — và đây là phát hiện mới thực sự.** Study 1 không thấy ảnh hưởng
   của loại video (*p* = 0,230), dù Walking cao nhất về mặt số học ở điều kiện Baseline
   (78 so với 68/68). Study 2 phát hiện rõ ràng. Lý do nhiều khả năng nằm ở **cách đo, không
   phải ở mẫu**: trừ đi điểm PRE của chính trial đó loại bỏ một nguồn nhiễu lớn giữa các trial
   (sự trôi trạng thái của người tham gia trong buổi kéo dài ~90 phút), khiến điểm thay đổi
   nhạy hơn nhiều so với chỉ dùng điểm POST. **Chính thiết kế đo trước/sau đã làm lộ ra hiệu
   ứng video.**

3. **Mức say tuyệt đối ở Study 2 thấp hơn 3–4 lần** (POST TSC 15–26 so với 42–78). Khoảng cách
   này quá lớn để là nhiễu lấy mẫu và chỉ ra khác biệt về quy trình — video ngắn hơn hoặc ít gây
   say hơn, phần cứng khác, hoặc hướng dẫn khác. Điều này ảnh hưởng trực tiếp đến diễn giải:
   **hiệu ứng sàn (floor effect) là một cách giải thích thay thế hợp lý cho kết quả null của
   Method.** Khi mức say vốn đã nhẹ, các phương pháp có thể đơn giản là không còn nhiều việc
   để làm.

## 10. Hạn chế

1. **Không có điều kiện Baseline.** Đây là hạn chế quan trọng nhất — không thể đo hiệu quả
   tuyệt đối, chỉ so sánh tương đối giữa ba phương pháp.
2. **Có thể có hiệu ứng sàn.** POST TSC 15–26 là mức nhẹ và thấp hơn nhiều so với Study 1.
3. **Carryover đáng kể.** ~40% trạng thái cuối trial còn lại sang trial sau, cộng ~1 điểm TSC
   tích luỹ mỗi trial; nghỉ lâu hơn (trong khoảng 5–7 phút đã dùng) không giúp ích. Cân bằng
   thứ tự phân phối đều ảnh hưởng này nên **không gây lệch** cho so sánh Method, nhưng làm tăng
   phương sai sai số và giảm lực thống kê.
4. **Trial 1 không phải baseline sạch.** 8/36 người đã có triệu chứng từ trước.
5. **Phần dư không chuẩn, nhiều giá trị 0.** Đã bù bằng bốn kiểm tra độ bền vững đồng thuận,
   nhưng không nên đọc giá trị *p* tham số đến 3 chữ số thập phân.
6. **Danh tính người tham gia dựa trên họ tên tự do.** Việc tái lập là rõ ràng và được kiểm
   chứng độc lập bằng cấu trúc thiết kế, nhưng một trường mã người tham gia sẽ loại bỏ hoàn toàn
   nhu cầu phán đoán.
7. **Thứ tự trial được tái lập từ timestamp của form**, không phải ghi log trực tiếp. Ba người
   nộp một số form POST không đúng thứ tự và một người nộp form POST muộn 35 ngày (vẫn giữ lại
   theo yêu cầu; loại bỏ cũng không thay đổi kết quả).
8. **Một người nhập sai nhãn video ở form POST**, đã sửa theo bản ghi PRE.
9. **Không có dữ liệu xếp hạng ưu tiên hay dữ liệu định tính**, nên không thể xem lại các chủ đề
   phỏng vấn của Study 1.

## 11. Kết luận

1. Xem các video 360° này làm **điểm SSQ Total Severity tăng gần gấp đôi** (+8,4 điểm; +88%;
   *d*z = 0,90), có ý nghĩa trên cả bốn thang SSQ.
2. **Giả thuyết chính không được ủng hộ.** ROF, Minimap và Path Overlay tạo ra mức tăng
   trước→sau **không phân biệt được** về mặt thống kê (Time × Method null trên cả bốn thang,
   η²_G ≤ 0,001). Dữ liệu loại trừ khác biệt lớn hơn khoảng 5–7 điểm TSC.
3. **Loại video quan trọng hơn phương pháp.** Walking gây mức tăng gấp ~2,4 lần Driving
   (*p*_holm = 0,004); Cycling và Driving không phân biệt được. Hiệu ứng này không thấy được ở
   Study 1 và chỉ lộ ra nhờ thiết kế đo trước/sau.
4. **Không phương pháp nào phù hợp riêng cho loại video nào** (tương tác ba chiều null).
5. **Triệu chứng không hồi phục hết giữa các trial** (*b* = 0,39; *p* < 0,001), cộng ~1 điểm TSC
   tích luỹ mỗi trial và nghỉ lâu hơn không giúp ích. **Các quy trình tiếp theo nên kéo dài hoặc
   kiểm tra chủ động thời gian hồi phục, và nên tiếp tục đo SSQ trước mỗi trial.**
6. **Presence không bị ảnh hưởng bởi phương pháp** (đều ≈ 5,1/7), nên đánh đổi giữa mức say và
   Presence mà Study 1 tìm thấy ở Dynamic FOV **không xuất hiện** ở ba phương pháp này.
7. Vì Study 2 không có Baseline, **khuyến nghị thực tiễn là việc chọn giữa ba kỹ thuật này có
   thể dựa trên tiêu chí khác** — chi phí triển khai, thẩm mỹ, mức phù hợp với tác vụ — bởi
   không kỹ thuật nào nổi trội về mức tăng triệu chứng. Muốn biết kỹ thuật nào thực sự tốt hơn
   video không xử lý thì **cần một nghiên cứu có điều kiện Baseline**.

---

## Lưu ý quan trọng khi viết bài

**Không được viết** những câu như *"ROF giảm say chuyển động so với VR không xử lý"* — Study 2
**không có** điều kiện Baseline nên không có bằng chứng cho loại phát biểu này.

**Nên viết** những câu như:

- *"ROF tạo ra mức tăng SSQ trước→sau không khác biệt có ý nghĩa so với Minimap và Path Overlay."*
- *"Video Walking gây mức tăng triệu chứng lớn hơn đáng kể so với Cycling và Driving."*
- *"Không tìm thấy bằng chứng cho thấy hiệu quả của phương pháp phụ thuộc vào loại chuyển động camera."*
