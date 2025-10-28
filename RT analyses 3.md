## Reaction Time Results

### Overview

Response times (RTs) from the lexical decision task were analyzed separately for words and nonwords.  
For **real words**, both lexical variables—**Base Frequency** and **Morphological Family Size**—were included simultaneously within each model, with participants divided by **Orthographic** or **Semantic Sensitivity** (two models total).  

For **nonwords**, because stimuli were either grouped by **Family Size** or by **Base Frequency**, separate models were fit for each grouping variable and for each participant sensitivity measure (four models total).  

All models included by-subject random intercepts and slopes for within-subject predictors and random intercepts for items (or strings). Degrees of freedom were estimated using the Satterthwaite approximation.  

---

### 1. Word Analyses

#### 1.1 Effects of Orthographic Sensitivity  
*(Model: response_time ~ Base_Frequency * Family_Size * Orthographic_Sensitivity + (1 ¦ SubjID) + (1 ¦ STRING))*

Significant main effects were found for both Base Frequency, *F*(1, 92.45) = 10.29, *p* = .002, η²ₚ = .10 [.03, .18], and Family Size, *F*(1, 92.44) = 9.41, *p* = .003, η²ₚ = .09 [.02, .17].  
High-frequency words were recognized faster (*M* = 602 ms, 95% CI [583, 622]) than low-frequency words (*M* = 622 ms, 95% CI [603, 641]; *d* = 0.42 [0.15, 0.68]).  
Similarly, words from large morphological families were recognized faster (*M* = 603 ms, 95% CI [584, 622]) than those from small families (*M* = 622 ms, 95% CI [602, 641]; *d* = 0.40 [0.13, 0.66]).  

The main effect of Orthographic Sensitivity was marginal, *F*(1, 64.87) = 3.83, *p* = .055, η²ₚ = .06 [.00, .13], indicating a trend toward faster responses among participants with higher orthographic sensitivity.  
No interactions among predictors were significant (*F*s < 1.1).  
Model fit: *R*²₍conditional₎ = .36, *R*²₍marginal₎ = .03.

---

#### 1.2 Effects of Semantic Sensitivity  
*(Model: response_time ~ Base_Frequency * Family_Size * Semantic_Sensitivity + (1 ¦ SubjID) + (1 ¦ STRING))*

Replacing Orthographic with Semantic Sensitivity yielded the same lexical pattern.  
Base Frequency, *F*(1, 92.29) = 10.15, *p* = .002, η²ₚ = .10 [.03, .18], and Family Size, *F*(1, 92.30) = 9.28, *p* = .003, η²ₚ = .09 [.02, .17], both facilitated recognition.  
High-frequency and large-family words were recognized faster (≈602 ms) than low-frequency and small-family words (≈621 ms; *d*s ≈ 0.40–0.42).  
No effects involving Semantic Sensitivity were significant (*F*s < 1.1).  
Model fit: *R*²₍conditional₎ = .36, *R*²₍marginal₎ = .01.

---

### 2. Nonword Analyses

For nonwords, each model included **Morphological Complexity** (simple vs. complex) and either **Family Size** or **Base Frequency** as an item-level factor.  
Participants were divided by Orthographic or Semantic Sensitivity, yielding four models.

---

#### 2.1 Participants Divided by Orthographic Sensitivity

##### 2.1.1 Effects of Family Size  
*(Model: response_time ~ Complexity * Family_Size * Orthographic_Sensitivity + (1 ¦ SubjID) + (1 ¦ ItemID))*

A robust main effect of Complexity emerged, *F*(1, 4529) = 124.76, *p* < .001, η²ₚ = .12 [.09, .15]: complex nonwords (*M* = 737 ms, *SE* = 11) were slower than simple ones (*M* = 701 ms, *SE* = 11; *d* = 0.44 [0.34, 0.54]).  
Orthographic Sensitivity also affected overall speed, *F*(1, 64) = 5.37, *p* = .024, η²ₚ = .08 [.01, .17], with low-sensitivity participants responding more slowly.  
No other main effects or interactions were significant (*F*s < 1.1, *p*s > .29).  
Model fit: *R*²₍conditional₎ = .39, *R*²₍marginal₎ = .05.

---

##### 2.1.2 Effects of Base Frequency  
*(Model: response_time ~ Complexity * Base_Frequency * Orthographic_Sensitivity + (1 ¦ SubjID) + (1 ¦ ItemID))*

The model again revealed a strong main effect of Complexity, *F*(1, 4534) = 127.54, *p* < .001, η²ₚ = .12 [.09, .15].  
Base Frequency also mattered, *F*(1, 96) = 12.99, *p* < .001, η²ₚ = .11 [.03, .20]: nonwords derived from **high-frequency bases** (“high-frequency nonwords”) elicited longer response times (*M* = 728 ms, 95% CI [710, 746]) than those from low-frequency bases (*M* = 714 ms, 95% CI [696, 732]; *d* = 0.31 [0.12, 0.50]).  
Orthographic Sensitivity remained significant, *F*(1, 64) = 5.32, *p* = .024, η²ₚ = .08 [.01, .17].  

A *Complexity × Base Frequency* interaction, *F*(1, 4536) = 4.26, *p* = .039, η²ₚ = .01 [.00, .03], indicated that the complexity cost was larger for high-frequency nonwords (Δ = 42 ms, *d* = 0.41 [0.27, 0.54], 95% CI [32, 50]) than for low-frequency ones (Δ = 29 ms, *d* = 0.29 [0.16, 0.42], 95% CI [21, 37]).  
Model fit: *R*²₍conditional₎ = .41, *R*²₍marginal₎ = .04.

---

#### 2.2 Participants Divided by Semantic Sensitivity

##### 2.2.1 Effects of Family Size  
*(Model: response_time ~ Complexity * Family_Size * Semantic_Sensitivity + (1 ¦ SubjID) + (1 ¦ ItemID))*

A strong main effect of Complexity was observed, *F*(1, 4528) = 122.09, *p* < .001, η²ₚ = .12 [.09, .15], with complex nonwords slower than simple ones (*d* = 0.44 [0.34, 0.54]).  
No main effects of Family Size or Semantic Sensitivity were found (*F*s < 1).  

However, a significant three-way *Complexity × Family Size × Semantic Sensitivity* interaction, *F*(1, 4443) = 4.84, *p* = .028, η²ₚ = .01 [.00, .03], indicated that participants with high semantic sensitivity showed a larger complexity effect for large-family nonwords (45 ms, *d* = 0.44 [0.31, 0.57], 95% CI [33, 56]) than for small-family nonwords (27 ms, *d* = 0.26 [0.14, 0.39], 95% CI [16, 38]).  
Low-sensitivity participants showed little or no difference across family sizes.  
Model fit: *R*²₍conditional₎ = .40, *R*²₍marginal₎ = .05.

---

##### 2.2.2 Effects of Base Frequency  
*(Model: response_time ~ Complexity * Base_Frequency * Semantic_Sensitivity + (1 ¦ SubjID) + (1 ¦ ItemID))*

Complex nonwords were again slower than simple ones, *F*(1, 4533) = 125.15, *p* < .001, η²ₚ = .12 [.09, .15].  
Nonwords derived from low-frequency bases elicited slower responses than those from high-frequency bases, *F*(1, 95) = 12.70, *p* < .001, η²ₚ = .11 [.03, .20].  

A *Complexity × Base Frequency* interaction, *F*(1, 4535) = 3.92, *p* = .048, η²ₚ = .01 [.00, .03], showed that the complexity cost was larger for high-frequency (41 ms, *d* = 0.41 [0.27, 0.54], 95% CI [32, 50]) than for low-frequency bases (29 ms, *d* = 0.28 [0.15, 0.41], 95% CI [21, 37]).  
No effects involving Semantic Sensitivity approached significance (*F*s < 1.2).  
Model fit: *R*²₍conditional₎ = .41, *R*²₍marginal₎ = .04.

---

### 3. Summary and Transition

Response times showed complementary yet opposing influences of lexical and morphological structure across lexicalities.  
For **real words**, responses were faster for items derived from **high-frequency bases** and **large morphological families**, reflecting facilitated access to familiar and morphologically connected lexical representations (*d*s ≈ 0.4).  
For **nonwords**, these same lexical properties generally **slowed responses**, particularly for **morphologically complex** items derived from **high-frequency** or **large-family** bases (*η²ₚ*s ≈ .10–.12, *d*s ≈ 0.3–0.4), indicating that more wordlike pseudowords were harder to reject.  

Individual differences further modulated nonword—but not word—processing: participants with higher orthographic or semantic sensitivity exhibited larger complexity effects and stronger influences of morphological structure. This suggests that linguistic experience enhances morphological decomposition and lexical activation when evaluating unfamiliar forms.  

Together, these behavioral findings reveal how lexical familiarity and individual differences jointly shape morphological processing during visual word recognition.  
They provide a foundation for the ERP analyses that follow, which examine whether analogous patterns of lexicality-dependent and experience-related effects emerge in the N250 and N400 time windows.
