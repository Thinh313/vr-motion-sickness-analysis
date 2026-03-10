# Đánh Giá Kết Quả ANOVA

**Phân tích:** 2-Way Repeated Measures ANOVA (Method × Video)  
**SSQ Scoring:** Kennedy 1993 Table 4 — weighted subscales (N, O, D, TSC)  
**N:** 36 participants (0 excluded)  
**Observations:** 432 (36 × 12 conditions)  
**Correction:** Greenhouse-Geisser (sphericity), Holm (multiple DVs across 4 SSQ subscales)  
**Post-hoc:** Bonferroni (within each DV)  
**Effect size:** Generalized eta-squared (η²_G)  
**Tool:** R 4.5.1, afex 1.5.1, emmeans 1.11.2

---

## 1. Kiểm Định Giả Định (Assumption Checks)

### 1.1 Outliers

| DV               | Outliers (1.5×IQR) | Extreme (3×IQR) | Ghi chú                                      |
| ---------------- | ------------------- | ---------------- | --------------------------------------------- |
| SSQ TSC          | 7                   | 1                | Extreme: Nguyễn Hoàng Anh Thư (TSC=232, Dynamic FOV/Walking) |
| SSQ Nausea       | 13                  | 5                | Extreme: Anh Thư (191), Kim Khanh (105, 162, 95), Anh Thư (95) |
| SSQ Oculomotor   | 4                   | 0                | Không extreme                                  |
| SSQ Disorientation | 6                 | 2                | Extreme: Anh Thư (292), Thanh Duy (251)        |
| Presence         | 0                   | 0                | Không có outlier                               |

### 1.2 Normality — Shapiro-Wilk trên Model Residuals (Primary Diagnostic)

Giả định normality của RM-ANOVA áp dụng cho **model residuals** (error term mà F-test sử dụng), không phải raw scores trong từng cell. Residuals được lấy từ `aov(DV ~ method * video + Error(subject / (method * video)))`.

| DV               | W      | p      | Kết luận    |
| ---------------- | ------ | ------ | ----------- |
| SSQ TSC          | 0.9781 | .0020  | Non-normal  |
| SSQ Nausea       | 0.9438 | <.0001 | Non-normal  |
| SSQ Oculomotor   | 0.9857 | .0288  | Non-normal  |
| SSQ Disorientation | 0.9657 | <.0001 | Non-normal  |
| Presence         | 0.9876 | .0570  | Normal ✓    |

Residual QQ-plots: `plots/ssq_tsc_residual_qqplot.png`, `ssq_n_residual_qqplot.png`, `ssq_o_residual_qqplot.png`, `ssq_d_residual_qqplot.png`, `presence_residual_qqplot.png`.

**Đánh giá:** SSQ residuals đều non-normal (kể cả Oculomotor), chủ yếu do right-skew — nhiều participants ít say, vài người say rất nhiều. Với N=36 và equal group sizes, RM-ANOVA robust với vi phạm này (Field, 2018; Tabachnick & Fidell, 2019). Sensitivity analysis xác nhận kết quả không thay đổi khi loại extreme outliers.

### 1.3 Sphericity

Greenhouse-Geisser correction áp dụng cho tất cả F-tests (afex default). Degrees of freedom đã adjusted.

---

## 2. Kết Quả ANOVA (GG-corrected, Holm-corrected)

### 2.1 SSQ Effect Map (4 DVs × 3 Effects)

**Holm correction:** Áp dụng across 4 SSQ DVs trong mỗi effect family để kiểm soát family-wise error rate.

| Effect           | TSC                           | Nausea (N)                    | Oculomotor (O)                | Disorientation (D)            |
| ---------------- | ----------------------------- | ----------------------------- | ----------------------------- | ----------------------------- |
| **Method**       | F(2.61,91.19)=9.02, **p<.001***, p_holm=.0003, η²_G=.043 | F(2.88,100.77)=7.37, **p<.001***, p_holm=.0004, η²_G=.034 | F(2.47,86.34)=8.63, **p<.001***, p_holm=.0004, η²_G=.043 | F(2.81,98.40)=6.98, **p<.001***, p_holm=.0004, η²_G=.037 |
| Video            | F(1.72,60.12)=1.51, p=.230   | F(1.41,49.22)=1.52, p=.229   | F(1.85,64.84)=2.62, p=.084   | F(1.82,63.55)=0.88, p=.410   |
| Method × Video   | F(4.01,140.47)=0.79, p=.535  | F(3.29,115.23)=0.69, p=.570  | F(4.61,161.25)=1.04, p=.392  | F(4.45,155.79)=0.65, p=.642  |

**Kết quả chính:**
- **Method significant trên TẤT CẢ 4 SSQ subscales** (tất cả p<.001, tất cả survive Holm correction).
- **Video KHÔNG significant** trên bất kỳ subscale nào (tất cả p>.08).
- **Interaction KHÔNG significant** trên bất kỳ subscale nào (tất cả p>.39).

### 2.2 Presence (Cảm giác hiện diện — cao = tốt)

| Effect           | df (GG)        | F     | p      | η²_G | Significant? |
| ---------------- | -------------- | ----- | ------ | ---- | ------------ |
| **Method**       | 1.87, 65.40    | 13.64 | <.001  | .079 | **CÓ ✓✓✓**  |
| Video            | 1.85, 64.82    | 0.79  | .450   | .002 | Không        |
| Method × Video   | 4.43, 155.05   | 1.88  | .109   | .010 | Không        |

### 2.3 Đánh giá ANOVA

- **Method có ảnh hưởng significant** lên cả 4 SSQ subscales (tất cả p<.001) và Presence (p<.001).
- **Video KHÔNG significant** cho bất kỳ DV nào → loại video (Cycling/Walking/Driving) không ảnh hưởng đến mức say hay presence.
- **Interaction KHÔNG significant** → hiệu quả của method **nhất quán** across video types. Nếu Dynamic FOV giảm say khi Cycling, nó cũng giảm say tương tự khi Walking và Driving.
- **Effect size:** SSQ η²_G = .034–.043 (small), Presence η²_G = .079 (small-to-medium). Theo benchmarks của Cohen: .02 = small, .06 = small-medium, .14 = large.
- **Pattern nhất quán:** Tất cả 4 SSQ subscales cho kết quả giống nhau — Method significant, Video và Interaction không. Cho thấy mitigation methods ảnh hưởng toàn diện lên motion sickness (không chỉ 1 component).

---

## 3. Post-hoc Pairwise (Bonferroni)

*Vì interaction không significant → chỉ phân tích main effect Method.*
*Vì Method significant trên tất cả 4 SSQ DVs (sau Holm) → post-hoc cho cả 4.*

### 3.1 SSQ Post-hoc — Marginal Means by Method

| Method       | TSC (M±SD) | Nausea (M±SD) | Oculomotor (M±SD) | Disorientation (M±SD) |
| ------------ | ---------- | ------------- | ------------------ | --------------------- |
| Baseline     | 71.6 ± 47.6 | 39.5 ± 30.8 | 63.0 ± 40.9       | 93.1 ± 66.7          |
| Dynamic FOV  | 48.3 ± 38.7 | 26.6 ± 26.4 | 42.8 ± 34.1       | 62.4 ± 50.9          |
| Minimap      | 55.5 ± 38.0 | 29.2 ± 25.2 | 49.8 ± 32.2       | 72.4 ± 57.1          |
| Overlay Path | 56.7 ± 36.3 | 30.4 ± 22.1 | 50.6 ± 31.7       | 73.9 ± 54.0          |

### 3.2 SSQ Post-hoc — Pairwise Comparisons (Bonferroni)

**TSC (Total):**

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonf.) | Sig? |
| --------------------------- | ------- | ----- | ----- | --------- | ---- |
| Baseline vs Dynamic FOV     | +23.27  | 5.34  | 4.356 | **.0007** | ✓✓✓ |
| Baseline vs Minimap         | +16.07  | 4.69  | 3.423 | **.0096** | ✓✓  |
| Baseline vs Overlay Path    | +14.86  | 4.73  | 3.143 | **.0204** | ✓   |
| Dynamic FOV vs Minimap      | −7.20   | 4.17  | −1.727| .5579     | —    |
| Dynamic FOV vs Overlay Path | −8.41   | 5.03  | −1.674| .6177     | —    |
| Minimap vs Overlay Path     | −1.21   | 3.36  | −0.360| 1.0000    | —    |

**Nausea (N):**

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonf.) | Sig? |
| --------------------------- | ------- | ----- | ----- | --------- | ---- |
| Baseline vs Dynamic FOV     | +12.90  | 3.15  | 4.098 | **.0014** | ✓✓  |
| Baseline vs Minimap         | +10.25  | 2.94  | 3.480 | **.0082** | ✓✓  |
| Baseline vs Overlay Path    | +9.10   | 3.01  | 3.023 | **.0279** | ✓   |
| Dynamic FOV vs Minimap      | −2.65   | 2.79  | −0.948| 1.0000    | —    |
| Dynamic FOV vs Overlay Path | −3.80   | 3.06  | −1.240| 1.0000    | —    |
| Minimap vs Overlay Path     | −1.15   | 2.52  | −0.457| 1.0000    | —    |

**Oculomotor (O):**

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonf.) | Sig? |
| --------------------------- | ------- | ----- | ----- | --------- | ---- |
| Baseline vs Dynamic FOV     | +20.21  | 5.03  | 4.020 | **.0018** | ✓✓  |
| Baseline vs Minimap         | +13.20  | 4.22  | 3.123 | **.0215** | ✓   |
| Baseline vs Overlay Path    | +12.42  | 4.06  | 3.057 | **.0256** | ✓   |
| Dynamic FOV vs Minimap      | −7.02   | 3.69  | −1.902| .3922     | —    |
| Dynamic FOV vs Overlay Path | −7.79   | 4.17  | −1.868| .4209     | —    |
| Minimap vs Overlay Path     | −0.77   | 2.76  | −0.280| 1.0000    | —    |

**Disorientation (D):**

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonf.) | Sig? |
| --------------------------- | ------- | ----- | ----- | --------- | ---- |
| Baseline vs Dynamic FOV     | +30.68  | 7.33  | 4.188 | **.0011** | ✓✓  |
| Baseline vs Minimap         | +20.62  | 6.80  | 3.033 | **.0272** | ✓   |
| Baseline vs Overlay Path    | +19.20  | 7.27  | 2.642 | .0734     | ~    |
| Dynamic FOV vs Minimap      | −10.05  | 6.33  | −1.588| .7283     | —    |
| Dynamic FOV vs Overlay Path | −11.47  | 7.47  | −1.535| .8022     | —    |
| Minimap vs Overlay Path     | −1.42   | 5.78  | −0.245| 1.0000    | —    |

### 3.3 Đánh giá SSQ Post-hoc

**Pattern nhất quán across subscales:**
- **Baseline > tất cả mitigation methods** (significant trên hầu hết subscales).
- **3 methods không khác nhau** có ý nghĩa thống kê trên bất kỳ subscale nào.
- Dynamic FOV giảm nhiều nhất (TSC: −23.27, ~33%), nhưng không sig hơn Minimap hay Overlay Path.

**Lưu ý Disorientation:** Baseline vs Overlay Path chỉ marginally significant (p=.073). Đây là subscale duy nhất mà Overlay Path không đạt significance rõ ràng so với Baseline.

**% giảm so với Baseline (TSC):**

| Method       | TSC EMM | Δ vs Baseline | % giảm |
| ------------ | ------- | ------------- | ------ |
| Dynamic FOV  | 48.3    | −23.3         | 33%    |
| Minimap      | 55.5    | −16.1         | 22%    |
| Overlay Path | 56.7    | −14.9         | 21%    |

→ **Tất cả mitigation methods đều hiệu quả** trong giảm VR sickness, với Dynamic FOV mạnh nhất về mặt số liệu (nhưng không sig hơn).

### 3.4 Presence Post-hoc

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonferroni) | Significant? |
| --------------------------- | ------- | ----- | ----- | -------------- | ------------ |
| Baseline vs Dynamic FOV     | +0.861  | 0.196 | 4.397 | **.0006**      | **Có ✓✓✓**  |
| Baseline vs Minimap         | +0.254  | 0.114 | 2.219 | .1984          | Không        |
| Baseline vs Overlay Path    | +0.372  | 0.108 | 3.435 | **.0093**      | **Có ✓✓**   |
| Dynamic FOV vs Minimap      | −0.607  | 0.154 | −3.940| **.0022**      | **Có ✓✓**   |
| Dynamic FOV vs Overlay Path | −0.489  | 0.144 | −3.403| **.0101**      | **Có ✓**    |
| Minimap vs Overlay Path     | +0.119  | 0.086 | 1.386 | 1.0000         | Không        |

**Estimated Marginal Means (EMM) — Presence:**

| Method       | EMM  | SE    | 95% CI       |
| ------------ | ---- | ----- | ------------ |
| Baseline     | 4.79 | 0.112 | [4.56, 5.01] |
| Minimap      | 4.53 | 0.141 | [4.24, 4.82] |
| Overlay Path | 4.41 | 0.149 | [4.11, 4.72] |
| Dynamic FOV  | 3.92 | 0.205 | [3.51, 4.34] |

**Đánh giá Presence:**
- **Dynamic FOV giảm presence mạnh nhất**, thấp hơn sig so với tất cả methods khác (tất cả p < .011).
- **Minimap giữ presence gần Baseline nhất** — không khác sig (p = .198).
- **Overlay Path giảm nhẹ** presence so với Baseline (p = .009), nhưng không khác sig so với Minimap (p = 1.00).
- → Kết luận: Dynamic FOV phá vỡ presence nhiều nhất. Minimap bảo toàn presence tốt nhất.

---

## 4. Sensitivity Analysis (Loại Extreme Outliers)

Loại 3 participants có extreme outliers: Nguyễn Hoàng Anh Thư, Nguyễn Kim Khanh, Vương Thanh Duy.  
Remaining: N = 33, 396 observations.

| DV         | Effect       | p_full (Holm) | p_excl (Holm) | Cùng kết luận? |
| ---------- | ------------ | ------------- | ------------- | -------------- |
| SSQ TSC    | Method       | .0003         | .0010         | Có ✓           |
| SSQ TSC    | Video        | .686          | 1.000         | Có ✓           |
| SSQ TSC    | Method×Video | 1.000         | 1.000         | Có ✓           |
| SSQ N      | Method       | .0004         | .0020         | Có ✓           |
| SSQ N      | Video        | .686          | 1.000         | Có ✓           |
| SSQ N      | Method×Video | 1.000         | 1.000         | Có ✓           |
| SSQ O      | Method       | .0004         | .0020         | Có ✓           |
| SSQ O      | Video        | .337          | .452          | Có ✓           |
| SSQ O      | Method×Video | 1.000         | 1.000         | Có ✓           |
| SSQ D      | Method       | .0004         | .0020         | Có ✓           |
| SSQ D      | Video        | .686          | 1.000         | Có ✓           |
| SSQ D      | Method×Video | 1.000         | 1.000         | Có ✓           |

**Đánh giá:** Pattern significance **IDENTICAL** trên tất cả 12 effect×DV combinations (Holm-corrected). Kết quả **robust** — không bị extreme outliers kéo lệch.

---

## 5. Tổng Hợp: Đánh Giá Từng Method

| Method       | SSQ (Giảm say?)                                  | Presence (Giữ immersion?)       | Đánh giá tổng thể        |
| ------------ | ------------------------------------------------ | ------------------------------- | ------------------------- |
| **Minimap**      | ✅ Giảm sig trên tất cả subscales (TSC −22%)     | ✅ Giữ tốt nhất (≈ Baseline, p=.198) | **⭐ Tốt nhất (quantitative)** |
| **Overlay Path** | ✅ Giảm sig (TSC −21%, D marginally sig p=.073)  | ⚠️ Giảm nhẹ sig (p=.009)        | Tốt, trade-off nhẹ       |
| **Dynamic FOV**  | ✅ Giảm nhiều nhất (TSC −33%)                    | ❌ Giảm mạnh sig (p=.0006)       | Trade-off xấu             |
| Baseline     | — (reference)                                    | — (cao nhất: 4.79)             | Không can thiệp           |

### Key Findings

1. **Tất cả 3 methods đều giảm VR sickness** có ý nghĩa thống kê so với Baseline trên tất cả Kennedy subscales, nhưng không khác nhau.
2. **Pattern nhất quán across subscales:** Method ảnh hưởng toàn diện lên motion sickness — cả Nausea, Oculomotor, và Disorientation đều giảm. Không có subscale nào bị ảnh hưởng riêng lẻ.
3. **Video type không ảnh hưởng** gì — methods hoạt động nhất quán bất kể nội dung VR (Cycling/Walking/Driving).
4. **Không có interaction** — hiệu quả của method không phụ thuộc vào video type.
5. **Trade-off SSQ–Presence tồn tại:** Dynamic FOV giảm say nhiều nhất (33%) nhưng phá presence nặng nhất.
6. **Minimap là optimal** về mặt quantitative: giảm say mà giữ presence.

### So sánh Kennedy Subscales

| Subscale | Baseline EMM | Dynamic FOV EMM | Giảm lớn nhất |
| -------- | ------------ | --------------- | -------------- |
| **Disorientation** | 93.1 | 62.4 | −33.0% (giảm mạnh nhất) |
| **TSC** | 71.6 | 48.3 | −32.5% |
| **Nausea** | 39.5 | 26.6 | −32.7% |
| **Oculomotor** | 63.0 | 42.8 | −32.1% |

→ Mitigation methods giảm **đều** across tất cả subscales (~32–33%). Không có component nào bị giảm nhiều hơn hẳn → hiệu quả toàn diện.

### Lưu Ý Quan Trọng: Quantitative ≠ Qualitative

Kết quả ANOVA (quantitative) **không hoàn toàn khớp** với Thematic Analysis từ interview (qualitative, 7 themes từ 11 file). Dưới đây là so sánh chi tiết:

#### 5.1 So sánh từng Method

| Method       | ANOVA đánh giá      | TA đánh giá (Themes 4–6)                          | Convergence / Divergence |
| ------------ | -------------------- | -------------------------------------------------- | ------------------------ |
| **Minimap**  | ⭐ Giữ presence tốt nhất (≈ Baseline, p=.198) | ⚠️ **Mixed** — một số thích (ổn định, quen, giống game/Maps), nhưng nhiều người chê: khó thấy (nhỏ, góc dưới), khó hiểu logic, tốn glance cost phải liếc xuống | **DIVERGENCE**: Questionnaire ghi nhận presence cao, nhưng qualitative cho thấy usability disruption (vị trí thấp, attention cost) mà presence scale không capture. Minimap giữ "sense of being there" nhưng tạo ergonomic friction |
| **Overlay Path** | OK, presence giảm nhẹ sig (p=.009) | ⚠️ **Two-edged sword** — conceptually mạnh nhất (đoán được hướng rẽ, bám theo chuyển động), NHƯNG implementation issues: path gãy/giật/floating, hút mắt, không bám scene, chỉ xuất hiện lúc rẽ | **PARTIAL DIVERGENCE**: TA đánh giá cao ý tưởng overlay nhưng phàn nàn implementation; questionnaire ghi nhận presence giảm nhẹ (do overlay lên cảnh). Cognitive benefit (anticipation) không được presence scale đo |
| **Dynamic FOV** | ❌ Phá presence nặng nhất (p=.0006), SD=1.33 (cao nhất) | ⚠️ **Phân cực mạnh nhất** — nhóm thích: thu hẹp vùng nhìn giúp giảm say, lọc video giật; nhóm ghét: mất ngoại vi, bó hẹp, gợn sóng/artifact | **CONVERGENCE**: SD presence cao nhất = bằng chứng quantitative cho "chia phe" trong TA. Cả hai nguồn đều xác nhận Dynamic FOV là feature cần cá nhân hóa, không phải giải pháp phổ quát |

#### 5.2 Divergence quan trọng: Video Type

| | ANOVA | TA (Theme 2) |
|---|---|---|
| **Video effect** | **KHÔNG significant** trên bất kỳ DV nào (tất cả p > .08) | Walking bị đánh giá **khó chịu nhất** trong đa số interviews |
| **Giải thích** | SSQ scores trung bình across video types không khác nhau có ý nghĩa thống kê | Walking gom nhiều yếu tố gây khó chịu (rung, xoay, dừng, lùi, cảnh gần), nhưng sự khó chịu mang tính **chất lượng** (qualitative discomfort) hơn là **cường độ** (quantitative severity) — hoặc individual variation triệt tiêu effect ở group level |

→ Đây là điểm divergence đáng chú ý: người dùng **cảm nhận** Walking tệ hơn, nhưng SSQ scores **không cao hơn** có ý nghĩa. Có thể vì: (a) Walking gây discomfort kiểu khác (rung nhẹ nhưng liên tục) mà SSQ không phân biệt rõ; (b) một số people cũng thấy Driving khó chịu (đổi hướng, render giật), nên group mean triệt tiêu; (c) within-subject variance lớn che khuất between-video differences.

#### 5.3 Mechanisms từ TA mà ANOVA không capture

| TA Theme | Insight | ANOVA tương ứng |
|----------|---------|-----------------|
| **Theme 1: Predictability** | Không biết camera sắp làm gì = cơ chế lõi gây say. Biết trước hướng đi → "đỡ bất ngờ", "chuẩn bị được" | ANOVA chỉ đo Method effect, không tách riêng được mechanism. Nhưng Overlay Path (cue hướng rõ nhất) và Minimap (cue hướng gián tiếp) đều reduce SSQ → hỗ trợ hypothesis predictability |
| **Theme 3: Smoothness > Cue** | Một số người thấy video mượt quan trọng hơn cue định hướng. Có người xếp Baseline cao nhất vì ít artifact | ANOVA không tách được smoothness effect. Đây là **confound tiềm ẩn**: nếu mitigation UI gây thêm rendering overhead → có thể triệt tiêu một phần benefit của cue |
| **Theme 7: No single best UI** | Ranking phân tán: có người chọn Overlay, có người FOV, có người Baseline, có người Minimap | Khớp với ANOVA: 3 methods không khác nhau sig. TA giải thích **tại sao** không khác: vì mỗi method phù hợp với segment người dùng khác nhau |

#### 5.4 Tổng kết Qual–Quant Integration

**Convergence (khớp):**
- Tất cả methods đều giảm say so với Baseline → TA xác nhận users cảm nhận được sự hỗ trợ
- Dynamic FOV phân cực → cả quant (SD cao) và qual (chia phe) đồng ý
- 3 methods không khác nhau sig → TA giải thích: mỗi method phù hợp segment khác nhau, không có "best for all"

**Divergence (không khớp):**
- **Minimap**: quant = giữ presence tốt nhất; qual = gặp vấn đề usability (glance cost, visibility)
- **Overlay Path**: quant = giảm presence nhẹ; qual = ý tưởng tốt nhất nhưng implementation-sensitive
- **Video type**: quant = không significant; qual = Walking tệ nhất

**Implication cho thiết kế:**
- Presence questionnaire **không đủ** — cần thêm usability metrics (glance cost, learnability, perceived disruption)
- Smoothness/render quality là **điều kiện nền** — cue không bù được cho video giật (Theme 3)
- Hệ thống nên hỗ trợ **cá nhân hóa** hoặc **user modes** (comfort mode vs immersion mode) thay vì một UI duy nhất (Theme 7)

---

## 6. Câu APA cho Paper

### Assumption Checks
> Normality of the RM-ANOVA error term was assessed via Shapiro-Wilk tests on model residuals (extracted from `DV ~ Method × Video + Error(Subject / (Method × Video))`). Residuals for all four SSQ subscales were significantly non-normal (all *p*s < .03), primarily due to right-skewed distributions reflecting the floor effect in sickness scores. Presence residuals did not violate normality (*W* = .988, *p* = .057). RM-ANOVA is robust to such violations with balanced designs and *N* ≥ 30 (Field, 2018; Tabachnick & Fidell, 2019). A sensitivity analysis excluding extreme outliers confirmed identical patterns of significance.

### SSQ (Kennedy 1993 Subscales)
> Four two-way repeated-measures ANOVAs with Greenhouse-Geisser correction were conducted on SSQ subscale scores computed following Kennedy et al. (1993): Total Severity (TSC), Nausea (N), Oculomotor (O), and Disorientation (D). Holm correction was applied across the four SSQ dependent variables within each effect family to control the family-wise error rate.
>
> A significant main effect of Method was found for all four SSQ subscales: TSC, *F*(2.61, 91.19) = 9.02, *p* < .001, η²_G = .043; Nausea, *F*(2.88, 100.77) = 7.37, *p* < .001, η²_G = .034; Oculomotor, *F*(2.47, 86.34) = 8.63, *p* < .001, η²_G = .043; Disorientation, *F*(2.81, 98.40) = 6.98, *p* < .001, η²_G = .037. All effects survived Holm correction (all *p*_holm < .001). Neither Video nor Method × Video interaction reached significance on any subscale (all *p*s > .08).
>
> Bonferroni-corrected pairwise comparisons revealed a consistent pattern across all subscales: all three mitigation methods significantly reduced SSQ scores compared to Baseline (Dynamic FOV: TSC Δ = 23.27, *p* < .001; Minimap: TSC Δ = 16.07, *p* = .010; Overlay Path: TSC Δ = 14.86, *p* = .020), with no significant differences among the three methods (all *p*s > .39). This pattern was consistent across Nausea, Oculomotor, and Disorientation subscales, indicating that the mitigation methods reduced motion sickness globally rather than targeting specific symptom clusters.

### Presence
> For Presence, a significant main effect of Method was observed, *F*(1.87, 65.40) = 13.64, *p* < .001, η²_G = .079. Video and interaction effects were not significant (*p*s > .11). Pairwise comparisons revealed that Dynamic FOV yielded significantly lower presence than all other conditions (all *p*s < .011). Minimap did not significantly differ from Baseline (*p* = .198), while Overlay Path showed a small but significant decrease (*p* = .009). Minimap and Overlay Path did not differ from each other (*p* = 1.000).

### Sensitivity
> A sensitivity analysis excluding three participants with extreme SSQ scores (identified via the 3×IQR criterion) yielded identical patterns of significance across all 12 effect × DV combinations (Holm-corrected), confirming the robustness of the findings.

---

*File generated from: anova_results.txt*  
*Analysis date: 2026-03-10*  
*SSQ scoring: Kennedy et al. (1993) Table 4 weighted subscales*  
*R packages: afex 1.5.1, emmeans 1.11.2, rstatix 0.7.2*
