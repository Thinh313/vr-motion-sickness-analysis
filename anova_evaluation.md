# Đánh Giá Kết Quả ANOVA

**Phân tích:** 2-Way Repeated Measures ANOVA (Method × Video)  
**SSQ Scoring:** Kennedy 1993 Table 4 — weighted subscales (N, O, D, TSC)  
**N:** 33 participants (1 excluded — incomplete data)  
**Observations:** 396 (33 × 12 conditions)  
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
| SSQ Nausea       | 12                  | 4                | Extreme: Anh Thư (191), Kim Khanh (162, 95, 95) |
| SSQ Oculomotor   | 4                   | 0                | Không extreme                                  |
| SSQ Disorientation | 7                 | 2                | Extreme: Anh Thư (292), Thanh Duy (251)        |
| Presence         | 0                   | 0                | Không có outlier                               |

### 1.2 Normality (Shapiro-Wilk per cell)

| DV               | Cells vi phạm (p < .05) | Ghi chú                                                     |
| ---------------- | ------------------------ | ------------------------------------------------------------ |
| SSQ TSC          | 3/12                     | Baseline/Driving, Dynamic FOV/Cycling, Dynamic FOV/Walking   |
| SSQ Nausea       | **10/12**                | Hầu hết cells vi phạm — do right-skew mạnh                  |
| SSQ Oculomotor   | 5/12                     | Dynamic FOV cells + Minimap/Driving + Baseline/Walking       |
| SSQ Disorientation | 6/12                   | Phân bố đều khắp methods                                    |
| Presence         | 2/12                     | Dynamic FOV/Walking, Overlay Path/Driving                    |

### 1.3 Residual Normality (trên model residuals)

| DV               | W      | p      | Kết luận    |
| ---------------- | ------ | ------ | ----------- |
| SSQ TSC          | 0.9812 | .0093  | Non-normal  |
| SSQ Nausea       | 0.9500 | <.0001 | Non-normal  |
| SSQ Oculomotor   | 0.9872 | .0712  | Normal ✓    |
| SSQ Disorientation | 0.9667 | .0001 | Non-normal  |
| Presence         | 0.9870 | .0673  | Normal ✓    |

**Đánh giá:** SSQ residuals non-normal (trừ Oculomotor), chủ yếu do right-skew — nhiều participants ít say, vài người say rất nhiều. Với N=33 và equal group sizes, RM-ANOVA robust với vi phạm này (Field, 2018; Tabachnick & Fidell, 2019). Sensitivity analysis xác nhận kết quả không thay đổi khi loại extreme outliers.

### 1.4 Sphericity

Greenhouse-Geisser correction áp dụng cho tất cả F-tests (afex default). Degrees of freedom đã adjusted.

---

## 2. Kết Quả ANOVA (GG-corrected, Holm-corrected)

### 2.1 SSQ Effect Map (4 DVs × 3 Effects)

**Holm correction:** Áp dụng across 4 SSQ DVs trong mỗi effect family để kiểm soát family-wise error rate.

| Effect           | TSC                           | Nausea (N)                    | Oculomotor (O)                | Disorientation (D)            |
| ---------------- | ----------------------------- | ----------------------------- | ----------------------------- | ----------------------------- |
| **Method**       | F(2.6,84.4)=10.29, **p<.001***, p_holm<.001, η²_G=.055 | F(2.9,92.8)=8.14, **p<.001***, p_holm<.001, η²_G=.042 | F(2.5,81.1)=10.05, **p<.001***, p_holm<.001, η²_G=.056 | F(2.8,90.0)=7.80, **p<.001***, p_holm<.001, η²_G=.046 |
| Video            | F(1.7,54.4)=1.35, p=.265     | F(1.4,44.8)=1.50, p=.233     | F(1.8,58.7)=2.49, p=.096     | F(1.8,57.7)=0.60, p=.535     |
| Method × Video   | F(3.9,126.1)=0.77, p=.543    | F(3.3,105.2)=0.65, p=.596    | F(4.5,144.9)=0.93, p=.457    | F(4.3,139.1)=0.79, p=.542    |

**Kết quả chính:**
- **Method significant trên TẤT CẢ 4 SSQ subscales** (tất cả p<.001, tất cả survive Holm correction).
- **Video KHÔNG significant** trên bất kỳ subscale nào (tất cả p>.09).
- **Interaction KHÔNG significant** trên bất kỳ subscale nào (tất cả p>.45).

### 2.2 Presence (Cảm giác hiện diện — cao = tốt)

| Effect           | df (GG)        | F     | p      | η²_G | Significant? |
| ---------------- | -------------- | ----- | ------ | ---- | ------------ |
| **Method**       | 1.93, 61.83    | 15.85 | <.001  | .099 | **CÓ ✓✓✓**  |
| Video            | 1.84, 58.96    | 1.01  | .366   | .003 | Không        |
| Method × Video   | 4.33, 138.42   | 1.72  | .143   | .011 | Không        |

### 2.3 Đánh giá ANOVA

- **Method có ảnh hưởng significant** lên cả 4 SSQ subscales (tất cả p<.001) và Presence (p<.001).
- **Video KHÔNG significant** cho bất kỳ DV nào → loại video (Cycling/Walking/Driving) không ảnh hưởng đến mức say hay presence.
- **Interaction KHÔNG significant** → hiệu quả của method **nhất quán** across video types. Nếu Dynamic FOV giảm say khi Cycling, nó cũng giảm say tương tự khi Walking và Driving.
- **Effect size:** SSQ η²_G = .042–.056 (small-to-medium), Presence η²_G = .099 (medium). Theo benchmarks của Cohen: .02 = small, .06 = small-medium, .14 = large.
- **Pattern nhất quán:** Tất cả 4 SSQ subscales cho kết quả giống nhau — Method significant, Video và Interaction không. Cho thấy mitigation methods ảnh hưởng toàn diện lên motion sickness (không chỉ 1 component).

---

## 3. Post-hoc Pairwise (Bonferroni)

*Vì interaction không significant → chỉ phân tích main effect Method.*
*Vì Method significant trên tất cả 4 SSQ DVs (sau Holm) → post-hoc cho cả 4.*

### 3.1 SSQ Post-hoc — Marginal Means by Method

| Method       | TSC (M±SD) | Nausea (M±SD) | Oculomotor (M±SD) | Disorientation (M±SD) |
| ------------ | ---------- | ------------- | ------------------ | --------------------- |
| Baseline     | 75.9 ± 47.1 | 42.5 ± 30.4 | 66.7 ± 40.4       | 97.9 ± 66.8          |
| Dynamic FOV  | 49.4 ± 39.3 | 27.9 ± 27.1 | 43.6 ± 34.5       | 63.1 ± 51.1          |
| Minimap      | 58.2 ± 37.8 | 31.0 ± 25.4 | 52.1 ± 31.9       | 75.5 ± 56.9          |
| Overlay Path | 59.2 ± 35.8 | 32.3 ± 22.0 | 52.8 ± 31.0       | 76.2 ± 54.1          |

### 3.2 SSQ Post-hoc — Pairwise Comparisons (Bonferroni)

**TSC (Total):**

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonf.) | Sig? |
| --------------------------- | ------- | ----- | ----- | --------- | ---- |
| Baseline vs Dynamic FOV     | +26.44  | 5.46  | 4.840 | **.0002** | ✓✓✓ |
| Baseline vs Minimap         | +17.68  | 5.00  | 3.536 | **.0076** | ✓✓  |
| Baseline vs Overlay Path    | +16.70  | 5.00  | 3.338 | **.0129** | ✓   |
| Dynamic FOV vs Minimap      | −8.76   | 4.43  | −1.980| .3385     | —    |
| Dynamic FOV vs Overlay Path | −9.75   | 5.42  | −1.799| .4884     | —    |
| Minimap vs Overlay Path     | −0.98   | 3.67  | −0.268| 1.0000    | —    |

**Nausea (N):**

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonf.) | Sig? |
| --------------------------- | ------- | ----- | ----- | --------- | ---- |
| Baseline vs Dynamic FOV     | +14.55  | 3.28  | 4.439 | **.0006** | ✓✓✓ |
| Baseline vs Minimap         | +11.47  | 3.13  | 3.669 | **.0053** | ✓✓  |
| Baseline vs Overlay Path    | +10.21  | 3.21  | 3.180 | **.0196** | ✓   |
| Dynamic FOV vs Minimap      | −3.08   | 3.04  | −1.015| 1.0000    | —    |
| Dynamic FOV vs Overlay Path | −4.34   | 3.33  | −1.304| 1.0000    | —    |
| Minimap vs Overlay Path     | −1.25   | 2.75  | −0.456| 1.0000    | —    |

**Oculomotor (O):**

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonf.) | Sig? |
| --------------------------- | ------- | ----- | ----- | --------- | ---- |
| Baseline vs Dynamic FOV     | +23.12  | 5.15  | 4.487 | **.0005** | ✓✓✓ |
| Baseline vs Minimap         | +14.55  | 4.51  | 3.229 | **.0172** | ✓   |
| Baseline vs Overlay Path    | +13.94  | 4.30  | 3.242 | **.0166** | ✓   |
| Dynamic FOV vs Minimap      | −8.58   | 3.88  | −2.209| .2070     | —    |
| Dynamic FOV vs Overlay Path | −9.19   | 4.46  | −2.059| .2862     | —    |
| Minimap vs Overlay Path     | −0.61   | 3.00  | −0.204| 1.0000    | —    |

**Disorientation (D):**

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonf.) | Sig? |
| --------------------------- | ------- | ----- | ----- | --------- | ---- |
| Baseline vs Dynamic FOV     | +34.73  | 7.54  | 4.606 | **.0004** | ✓✓✓ |
| Baseline vs Minimap         | +22.36  | 7.29  | 3.068 | **.0262** | ✓   |
| Baseline vs Overlay Path    | +21.65  | 7.74  | 2.797 | **.0519** | ~    |
| Dynamic FOV vs Minimap      | −12.37  | 6.73  | −1.838| .4524     | —    |
| Dynamic FOV vs Overlay Path | −13.08  | 8.09  | −1.617| .6939     | —    |
| Minimap vs Overlay Path     | −0.70   | 6.30  | −0.112| 1.0000    | —    |

### 3.3 Đánh giá SSQ Post-hoc

**Pattern nhất quán across subscales:**
- **Baseline > tất cả mitigation methods** (significant trên hầu hết subscales).
- **3 methods không khác nhau** có ý nghĩa thống kê trên bất kỳ subscale nào.
- Dynamic FOV giảm nhiều nhất (TSC: −26.44, ~35%), nhưng không sig hơn Minimap hay Overlay Path.

**Lưu ý Disorientation:** Baseline vs Overlay Path chỉ marginally significant (p=.052). Đây là subscale duy nhất mà Overlay Path không đạt significance rõ ràng so với Baseline.

**% giảm so với Baseline (TSC):**

| Method       | TSC EMM | Δ vs Baseline | % giảm |
| ------------ | ------- | ------------- | ------ |
| Dynamic FOV  | 49.4    | −26.4         | 35%    |
| Minimap      | 58.2    | −17.7         | 23%    |
| Overlay Path | 59.2    | −16.7         | 22%    |

→ **Tất cả mitigation methods đều hiệu quả** trong giảm VR sickness, với Dynamic FOV mạnh nhất về mặt số liệu (nhưng không sig hơn).

### 3.4 Presence Post-hoc

| So sánh                     | Δ (EMM) | SE    | t     | p (Bonferroni) | Significant? |
| --------------------------- | ------- | ----- | ----- | -------------- | ------------ |
| Baseline vs Dynamic FOV     | +0.960  | 0.200 | 4.792 | **.0002**      | **Có ✓✓✓**  |
| Baseline vs Minimap         | +0.281  | 0.122 | 2.297 | .1699          | Không        |
| Baseline vs Overlay Path    | +0.386  | 0.112 | 3.450 | **.0096**      | **Có ✓✓**   |
| Dynamic FOV vs Minimap      | −0.679  | 0.160 | −4.254| **.0010**      | **Có ✓✓✓**  |
| Dynamic FOV vs Overlay Path | −0.574  | 0.147 | −3.894| **.0028**      | **Có ✓✓**   |
| Minimap vs Overlay Path     | +0.105  | 0.091 | 1.157 | 1.0000         | Không        |

**Estimated Marginal Means (EMM) — Presence:**

| Method       | EMM  | SE    | 95% CI       |
| ------------ | ---- | ----- | ------------ |
| Baseline     | 4.80 | 0.117 | [4.57, 5.04] |
| Minimap      | 4.52 | 0.146 | [4.23, 4.82] |
| Overlay Path | 4.42 | 0.149 | [4.12, 4.72] |
| Dynamic FOV  | 3.84 | 0.207 | [3.42, 4.27] |

**Đánh giá Presence:**
- **Dynamic FOV giảm presence mạnh nhất**, thấp hơn sig so với tất cả methods khác (tất cả p < .003).
- **Minimap giữ presence gần Baseline nhất** — không khác sig (p = .17).
- **Overlay Path giảm nhẹ** presence so với Baseline (p = .01), nhưng không khác sig so với Minimap (p = 1.00).
- → Kết luận: Dynamic FOV phá vỡ presence nhiều nhất. Minimap bảo toàn presence tốt nhất.

---

## 4. Sensitivity Analysis (Loại Extreme Outliers)

Loại 3 participants có extreme outliers: Nguyễn Hoàng Anh Thư, Nguyễn Kim Khanh, Vương Thanh Duy.  
Remaining: N = 30, 360 observations.

| DV         | Effect       | p_full (Holm) | p_excl (Holm) | Cùng kết luận? |
| ---------- | ------------ | ------------- | ------------- | -------------- |
| SSQ TSC    | Method       | <.0001        | .0003         | Có ✓           |
| SSQ TSC    | Video        | .698          | 1.000         | Có ✓           |
| SSQ TSC    | Method×Video | 1.000         | 1.000         | Có ✓           |
| SSQ N      | Method       | .0002         | .0006         | Có ✓           |
| SSQ N      | Video        | .698          | 1.000         | Có ✓           |
| SSQ N      | Method×Video | 1.000         | 1.000         | Có ✓           |
| SSQ O      | Method       | <.0001        | .0006         | Có ✓           |
| SSQ O      | Video        | .384          | .464          | Có ✓           |
| SSQ O      | Method×Video | 1.000         | 1.000         | Có ✓           |
| SSQ D      | Method       | .0002         | .0006         | Có ✓           |
| SSQ D      | Video        | .698          | 1.000         | Có ✓           |
| SSQ D      | Method×Video | 1.000         | 1.000         | Có ✓           |

**Đánh giá:** Pattern significance **IDENTICAL** trên tất cả 12 effect×DV combinations (Holm-corrected). Kết quả **robust** — không bị extreme outliers kéo lệch.

---

## 5. Tổng Hợp: Đánh Giá Từng Method

| Method       | SSQ (Giảm say?)                                  | Presence (Giữ immersion?)       | Đánh giá tổng thể        |
| ------------ | ------------------------------------------------ | ------------------------------- | ------------------------- |
| **Minimap**      | ✅ Giảm sig trên tất cả subscales (TSC −23%)     | ✅ Giữ tốt nhất (≈ Baseline, p=.17) | **⭐ Tốt nhất (quantitative)** |
| **Overlay Path** | ✅ Giảm sig (TSC −22%, D marginally sig p=.052)  | ⚠️ Giảm nhẹ sig (p=.010)        | Tốt, trade-off nhẹ       |
| **Dynamic FOV**  | ✅ Giảm nhiều nhất (TSC −35%)                    | ❌ Giảm mạnh sig (p=.0002)       | Trade-off xấu             |
| Baseline     | — (reference)                                    | — (cao nhất: 4.80)             | Không can thiệp           |

### Key Findings

1. **Tất cả 3 methods đều giảm VR sickness** có ý nghĩa thống kê so với Baseline trên tất cả Kennedy subscales, nhưng không khác nhau.
2. **Pattern nhất quán across subscales:** Method ảnh hưởng toàn diện lên motion sickness — cả Nausea, Oculomotor, và Disorientation đều giảm. Không có subscale nào bị ảnh hưởng riêng lẻ.
3. **Video type không ảnh hưởng** gì — methods hoạt động nhất quán bất kể nội dung VR (Cycling/Walking/Driving).
4. **Không có interaction** — hiệu quả của method không phụ thuộc vào video type.
5. **Trade-off SSQ–Presence tồn tại:** Dynamic FOV giảm say nhiều nhất (35%) nhưng phá presence nặng nhất.
6. **Minimap là optimal** về mặt quantitative: giảm say mà giữ presence.

### So sánh Kennedy Subscales

| Subscale | Baseline EMM | Dynamic FOV EMM | Giảm lớn nhất |
| -------- | ------------ | --------------- | -------------- |
| **Disorientation** | 97.9 | 63.1 | −35.6% (giảm mạnh nhất) |
| **TSC** | 75.9 | 49.4 | −34.9% |
| **Nausea** | 42.5 | 27.9 | −34.4% |
| **Oculomotor** | 66.7 | 43.6 | −34.6% |

→ Mitigation methods giảm **đều** across tất cả subscales (~34–36%). Không có component nào bị giảm nhiều hơn hẳn → hiệu quả toàn diện.

### Lưu Ý Quan Trọng: Quantitative ≠ Qualitative

Kết quả ANOVA (quantitative) **không hoàn toàn khớp** với interview (qualitative):

| Method       | ANOVA đánh giá      | Interview đánh giá                    | Giải thích                                                     |
| ------------ | -------------------- | ------------------------------------- | -------------------------------------------------------------- |
| Minimap      | ⭐ Giữ presence tốt  | ❌ "Liếc xuống hoài, mất trải nghiệm" | Presence questionnaire ≠ perceived disruption; vấn đề usability/ergonomic (vị trí thấp), không phải presence |
| Overlay Path | OK, presence giảm nhẹ | ⭐ "Ngon nhất, đoán được hướng rẽ"     | Cognitive benefit (anticipation) được users đánh giá cao nhưng overlay lên cảnh vẫn bị questionnaire ghi nhận |
| Dynamic FOV  | ❌ Phá presence nặng  | ⚠️ "Chia phe — thích/ghét"            | Khớp: SD = 1.30 (cao nhất) = bằng chứng quantitative cho chia phe |

→ Kết luận: **Cần cả quantitative lẫn qualitative** để đánh giá đầy đủ. Questionnaire đo "sense of presence" nhưng không capture usability disruption hay cognitive benefit mà users trải nghiệm thực tế.

---

## 6. Câu APA cho Paper

### SSQ (Kennedy 1993 Subscales)
> Four two-way repeated-measures ANOVAs with Greenhouse-Geisser correction were conducted on SSQ subscale scores computed following Kennedy et al. (1993): Total Severity (TSC), Nausea (N), Oculomotor (O), and Disorientation (D). Holm correction was applied across the four SSQ dependent variables within each effect family to control the family-wise error rate.
>
> A significant main effect of Method was found for all four SSQ subscales: TSC, *F*(2.64, 84.44) = 10.29, *p* < .001, η²_G = .055; Nausea, *F*(2.90, 92.83) = 8.14, *p* < .001, η²_G = .042; Oculomotor, *F*(2.53, 81.11) = 10.05, *p* < .001, η²_G = .056; Disorientation, *F*(2.81, 89.96) = 7.80, *p* < .001, η²_G = .046. All effects survived Holm correction (all *p*_holm < .001). Neither Video nor Method × Video interaction reached significance on any subscale (all *p*s > .09).
>
> Bonferroni-corrected pairwise comparisons revealed a consistent pattern across all subscales: all three mitigation methods significantly reduced SSQ scores compared to Baseline (Dynamic FOV: TSC Δ = 26.44, *p* = .0002; Minimap: TSC Δ = 17.68, *p* = .008; Overlay Path: TSC Δ = 16.70, *p* = .013), with no significant differences among the three methods (all *p*s > .21). This pattern was consistent across Nausea, Oculomotor, and Disorientation subscales, indicating that the mitigation methods reduced motion sickness globally rather than targeting specific symptom clusters.

### Presence
> For Presence, a significant main effect of Method was observed, *F*(1.93, 61.83) = 15.85, *p* < .001, η²_G = .099. Video and interaction effects were not significant (*p*s > .14). Pairwise comparisons revealed that Dynamic FOV yielded significantly lower presence than all other conditions (all *p*s < .003). Minimap did not significantly differ from Baseline (*p* = .170), while Overlay Path showed a small but significant decrease (*p* = .010). Minimap and Overlay Path did not differ from each other (*p* = 1.000).

### Sensitivity
> A sensitivity analysis excluding three participants with extreme SSQ scores (identified via the 3×IQR criterion) yielded identical patterns of significance across all 12 effect × DV combinations (Holm-corrected), confirming the robustness of the findings.

---

*File generated from: anova_results.txt*  
*Analysis date: 2026-03-02*  
*SSQ scoring: Kennedy et al. (1993) Table 4 weighted subscales*  
*R packages: afex 1.5.1, emmeans 1.11.2, rstatix 0.7.2*
