# Đánh Giá Kết Quả Preference Ranking (Thăm Dò)

**Phân tích:** Preference ranking — xếp hạng chủ quan của người tham gia  
**Thiết kế:** Within-subject, 4 điều kiện, complete ranking (1–4)  
**N:** 13 / 36 người tham gia (36.1% coverage)  
**Framing:** EXPLORATORY — kết quả mang tính mô tả, không xác nhận (confirmatory)  
**Thống kê:** Mean/median rank, Borda score, pairwise exact sign test (Holm), Friedman, Kendall's W  
**Tool:** R 4.5.1, tidyverse 2.0.0, base R binom.test

---

## 1. Giới Hạn Quan Trọng

- Chỉ 13/36 (36.1%) người tham gia cung cấp preference ranking
- Không rõ lý do tại sao 23 người còn lại không cung cấp → có thể gây **selection bias**
- Tất cả p-values và kết luận dưới đây chỉ mang tính **thăm dò (exploratory)**
- Không nên trình bày kết quả này như bằng chứng xác nhận (confirmatory evidence)

---

## 2. Thống Kê Mô Tả

### 2.1 Bảng Tổng Hợp (sắp xếp theo Mean Rank, thấp = ưa thích hơn)

| Phương pháp  | Mean Rank | Median | SD    | Borda Score | First Choice | First % | Last Choice | Last % |
| ------------ | --------- | ------ | ----- | ----------- | ------------ | ------- | ----------- | ------ |
| Overlay Path | 2.038     | 2.0    | 0.877 | 38.5        | 4.0          | 30.8%   | 0.5         | 3.8%   |
| Minimap      | 2.423     | 2.0    | 0.760 | 33.5        | 1.0          | 7.7%    | 1.0         | 7.7%   |
| Dynamic FOV  | 2.731     | 3.5    | 1.452 | 29.5        | 5.0          | 38.5%   | 6.5         | 50.0%  |
| Baseline     | 2.808     | 3.0    | 1.200 | 28.5        | 3.0          | 23.1%   | 5.0         | 38.5%  |

*Ghi chú: First/Last choice count được chia đều khi có tie (ví dụ: nếu 2 phương pháp cùng rank 1, mỗi phương pháp nhận 0.5 first-choice).*

### 2.2 Nhận Xét Mô Tả

- **Overlay Path** có mean rank tốt nhất (2.038) và Borda score cao nhất (38.5). Hầu như không bao giờ bị xếp cuối (0.5 last-choice). Đây là phương pháp **ưa thích nhất một cách nhất quán (consistently preferred)**.

- **Minimap** xếp thứ 2 (mean = 2.423, Borda = 33.5). Ít khi được chọn đầu tiên (7.7%) nhưng cũng rất ít khi bị xếp cuối (7.7%). Đây là phương pháp **an toàn, ít gây tranh cãi (safe middle option)**.

- **Dynamic FOV** là phương pháp **phân cực nhất (most polarizing)**: có nhiều first-choice nhất (5, 38.5%) nhưng cũng nhiều last-choice nhất (6.5, 50%). SD cao nhất (1.452) xác nhận sự phân tán ý kiến.

- **Baseline** xếp cuối về mean rank (2.808) và Borda (28.5). Có một nhóm nhỏ ủng hộ (3 first-choice, 23.1%) nhưng phần lớn xếp thấp.

---

## 3. So Sánh Cặp (Pairwise Preference)

### 3.1 Ma Trận Thắng/Thua

| So sánh                       | A Wins | B Wins | Ties | n (discordant) |
| ----------------------------- | ------ | ------ | ---- | --------------- |
| Baseline vs Overlay Path      | 3      | 9      | 1    | 12              |
| Baseline vs Minimap           | 5      | 7      | 1    | 12              |
| Baseline vs Dynamic FOV       | 6      | 6      | 1    | 12              |
| Overlay Path vs Minimap       | 8      | 5      | 0    | 13              |
| Overlay Path vs Dynamic FOV   | 8      | 5      | 0    | 13              |
| Minimap vs Dynamic FOV        | 8      | 5      | 0    | 13              |

### 3.2 Exact Binomial Sign Tests (Holm-corrected)

| So sánh                       | p (raw) | p (Holm) | Kết luận              |
| ----------------------------- | ------- | -------- | --------------------- |
| Baseline vs Overlay Path      | .1460   | .876     | Không có ý nghĩa      |
| Baseline vs Minimap           | .7744   | 1.000    | Không có ý nghĩa      |
| Baseline vs Dynamic FOV       | 1.0000  | 1.000    | Không có ý nghĩa      |
| Overlay Path vs Minimap       | .5811   | 1.000    | Không có ý nghĩa      |
| Overlay Path vs Dynamic FOV   | .5811   | 1.000    | Không có ý nghĩa      |
| Minimap vs Dynamic FOV        | .5811   | 1.000    | Không có ý nghĩa      |

**Nhận xét:** Không có cặp nào đạt ngưỡng ý nghĩa thống kê (p < .05), kể cả trước khi hiệu chỉnh Holm. Cặp gần nhất là Baseline vs Overlay Path (p = .146), cho thấy xu hướng (trend) Overlay được ưa thích hơn Baseline (9 vs 3 wins), nhưng với n = 12 discordant pairs, statistical power rất thấp.

---

## 4. Kiểm Định Tổng Thể

### 4.1 Friedman Test

| Thống kê       | Giá trị |
| -------------- | ------- |
| Chi-squared    | 2.929   |
| df             | 3       |
| p-value        | .4027   |

→ Không có sự khác biệt tổng thể có ý nghĩa thống kê giữa 4 phương pháp (p = .40).

### 4.2 Kendall's W

| Thống kê    | Giá trị | Giải thích                   |
| ----------- | ------- | ---------------------------- |
| Kendall's W | 0.075   | Weak agreement (gần như không đồng thuận) |

→ W = 0.075 cho thấy 13 người tham gia hầu như **không đồng thuận** về thứ tự ưa thích. Đây là kết quả hợp lý với Dynamic FOV rất phân cực và phần lớn preference không rõ ràng.

---

## 5. Biểu Đồ Tham Khảo

| File                                  | Nội dung                                      |
| ------------------------------------- | --------------------------------------------- |
| `plots/preference_first_choice.png`   | Biểu đồ cột first-choice (chia tie)           |
| `plots/preference_mean_rank.png`      | Biểu đồ mean rank với error bars (SE)         |
| `plots/preference_borda_score.png`    | Biểu đồ Borda score                           |
| `plots/preference_pairwise_heatmap.png` | Heatmap thắng/thua pairwise                 |

---

## 6. Tổng Kết & Hàm Ý

### 6.1 Pattern Chính

1. **Overlay Path là phương pháp được ưa thích nhất tổng thể** — mean rank thấp nhất, Borda cao nhất, gần như không bao giờ bị xếp cuối. Kết quả này **nhất quán** với kết quả ANOVA: Overlay giảm SSQ đáng kể so với Baseline mà vẫn duy trì Presence tương đối cao.

2. **Dynamic FOV gây chia rẽ ý kiến mạnh** — nhiều người rất thích (38.5% first-choice) nhưng cũng nhiều người rất không thích (50% last-choice). Điều này **nhất quán** với SSQ findings: Dynamic FOV giảm SSQ nhiều nhất nhưng cũng giảm Presence nhiều nhất.

3. **Minimap là lựa chọn an toàn** — ít ai chọn đầu tiên nhưng cũng ít ai xếp cuối. SD thấp nhất (0.760). Kết quả **nhất quán** với Presence findings: Minimap bảo toàn Presence tốt nhất.

4. **Baseline bị xếp thấp** — mean rank và Borda thấp nhất, 38.5% last-choice. **Nhất quán** với SSQ: Baseline có SSQ cao nhất (nhiều say nhất).

### 6.2 Tại Sao Không Có Ý Nghĩa Thống Kê?

1. **Sample size nhỏ (n = 13)** — power thấp cho sign test (cần khoảng n ≥ 25 để detect moderate effect)
2. **Dynamic FOV rất phân cực** — phản ánh **genuine heterogeneity** trong preference, không phải noise
3. **Partial coverage (36.1%)** — kết quả có thể không đại diện cho toàn bộ 36 participants

### 6.3 Khuyến Nghị Trình Bày Trong Luận Văn

> Preference rankings (n = 13) were analyzed descriptively. Overlay Path received the best overall ranking (M = 2.04, Borda = 38.5) and was almost never ranked last (3.8%), suggesting consistent preference. Dynamic FOV was the most polarizing method, attracting both the most first-choice selections (38.5%) and the most last-choice selections (50.0%). No pairwise comparisons reached statistical significance (all Holm-adjusted p > .05), and Kendall's W = 0.075 indicated weak inter-rater agreement. Due to partial coverage (13/36), these results should be interpreted as exploratory.

---

*Phân tích thực hiện bằng R 4.5.1 + tidyverse 2.0.0 + base R binom.test.*  
*Xem `preference_results.txt` cho full statistical output.*
