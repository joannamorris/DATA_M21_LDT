

## 1. What is *actually* in your data (verified)

### RT — Words (`rt_words_frq.csv`)

* **Rows:** 6,291 (trial level)
* **Lexicality:** words only (`trial_type = "CW"`)
* **Item-level (continuous):**

  * `LogBF`, `LogFS`
  * `BaseLength`, `WholeFormLength` (available but optional)
* **Subject-level (continuous PCA):**

  * `Dim.2` = Orthographic Sensitivity (OS)
  * `Dim.1` = Language Proficiency (LP)
* **Identifiers:**

  * `SubjID`
  * `target` (word form; good item random effect)
* **No categorical morphology factors** at trial level (correct)

---

### RT — Nonwords (`rt_nwords_frq.csv`)

* **Rows:** 5,010 (trial level)
* **Lexicality:** nonwords only (`trial_type = "NW"`)
* **Morphology:**

  * `complexity`: **SIMP / COMP**
* **Item-level (continuous):**

  * `LogBF`, `LogFS`
* **Subject-level (continuous PCA):**

  * `Dim.2` (OS), `Dim.1` (LP)
* **Identifiers:**

  * `SubjID`, `ItemID`

---

### ERP — Words (`erp_dmg_words.csv`)

* **Rows:** 6,480
* **Averaged amplitudes:** `value`
* **Factors present:**

  * `family_size`: **Large / Small**
  * `time_window`: **N250 / N400**
* **Electrodes:** `chlabel` (27 channels)
* **Subject-level (continuous PCA):**

  * `Dim.2` (OS), `Dim.1` (LP)
* **No base frequency at ERP level** (important and fine)

---

### ERP — Nonwords (`erp_dmg_nonwords.csv`)

* **Rows:** 12,960
* **Averaged amplitudes:** `value`
* **Factors present:**

  * `complexity`: **Simple / Complex**
  * `family_size`: **Large / Small**
  * `time_window`: **N250 / N400**
* **Electrodes:** `chlabel`
* **Subject-level (continuous PCA):**

  * `Dim.2` (OS), `Dim.1` (LP)

---

## 2. Final analytic decisions (now locked to the data)

### Continuous vs categorical — resolved

| Measure | Predictor    | Treatment       | Why                    |
| ------- | ------------ | --------------- | ---------------------- |
| RT      | LogBF, LogFS | **Continuous**  | Trial-level            |
| RT      | OS, LP       | **Continuous**  | Individual differences |
| ERP     | family_size  | **Categorical** | Condition-averaged     |
| ERP     | complexity   | **Categorical** | Condition-averaged     |
| ERP     | OS, LP       | **Continuous**  | Subject-level          |

This is **methodologically correct** and easy to justify.

---

## 3. Exact final models (ready to run)

I’m giving you **one primary model per dataset per component** — no parallel clutter.

---

## A. RT — Words (primary behavioral model)

**Question:**
Does orthographic sensitivity predict efficiency, controlling lexical familiarity?

```{r}
library(lme4)

rt_w <- read.csv("rt_words_frq.csv") %>%
  filter(correct == 1) %>%
  mutate(
    SubjID = factor(SubjID),
    Item   = factor(target),
    logRT  = log(response_time),
    OS     = as.numeric(Dim.2),
    LP     = as.numeric(Dim.1),
    zLogBF = as.numeric(scale(LogBF)),
    zLogFS = as.numeric(scale(LogFS))
  )

m_rt_words <- lmer(
  logRT ~ zLogBF + zLogFS + OS + LP +
    zLogBF:OS + zLogFS:OS +
    (1 + zLogBF + zLogFS | SubjID) +
    (1 | Item),
  data = rt_w,
  control = lmerControl(optimizer = "bobyqa")
)

summary(m_rt_words)
```

**Report:** main effects + OS moderation only.
LP is included but not emphasized.

---

## B. RT — Nonwords (primary behavioral model)

**Question:**
Does morphological complexity slow decisions, and is this cost modulated by OS?

```{r}
rt_nw <- read.csv("rt_nwords_frq.csv") %>%
  filter(correct == 1) %>%
  mutate(
    SubjID = factor(SubjID),
    ItemID = factor(ItemID),
    complexity = factor(complexity),  # SIMP / COMP
    logRT  = log(response_time),
    OS     = as.numeric(Dim.2),
    LP     = as.numeric(Dim.1),
    zLogBF = as.numeric(scale(LogBF)),
    zLogFS = as.numeric(scale(LogFS))
  )

m_rt_nw <- lmer(
  logRT ~ complexity + zLogBF + zLogFS + OS + LP +
    complexity:OS +
    (1 + complexity | SubjID) +
    (1 | ItemID),
  data = rt_nw,
  control = lmerControl(optimizer = "bobyqa")
)

summary(m_rt_nw)
```

---

## C. ERP — Words

Run **separately by time window** (this is important).

### C1. N250 — Words

**Question:**
Does orthographic sensitivity modulate early sensitivity to morphological family structure?

```{r}
erp_w <- read.csv("erp_dmg_words.csv") %>%
  mutate(
    SubjID = factor(SubjID),
    chlabel = factor(chlabel),
    family_size = factor(family_size),
    time_window = factor(time_window),
    OS = as.numeric(Dim.2),
    LP = as.numeric(Dim.1)
  )

m_w_N250 <- lmer(
  value ~ family_size*OS + family_size*LP +
    (1 | SubjID) +
    (1 | SubjID:chlabel),
  data = subset(erp_w, time_window == "N250"),
  control = lmerControl(optimizer = "bobyqa")
)
```

**Follow-up (only if interaction significant):**

```{r}
library(emmeans)
emmeans(m_w_N250, ~ family_size | OS,
        at = list(OS = c(-1, 0, 1)))
```

---

### C2. N400 — Words

**Question:**
Does language proficiency shape semantic integration of family structure?

```{r}
m_w_N400 <- lmer(
  value ~ family_size*LP + family_size*OS +
    (1 | SubjID) +
    (1 | SubjID:chlabel),
  data = subset(erp_w, time_window == "N400"),
  control = lmerControl(optimizer = "bobyqa")
)
```

**Follow-up (core result):**

```{r}
emmeans(m_w_N400, ~ family_size | LP,
        at = list(LP = c(-1, 0, 1)))
```

---

## D. ERP — Nonwords

Again, **separate by time window**.

### D1. N250 — Nonwords

**Question:**
Is early morpho-orthographic parsing sensitive to complexity and family size?

```{r}
erp_nw <- read.csv("erp_dmg_nonwords.csv") %>%
  mutate(
    SubjID = factor(SubjID),
    chlabel = factor(chlabel),
    family_size = factor(family_size),
    complexity = factor(complexity),
    time_window = factor(time_window),
    OS = as.numeric(Dim.2),
    LP = as.numeric(Dim.1)
  )

m_nw_N250 <- lmer(
  value ~ complexity*family_size*OS + complexity*family_size*LP +
    (1 | SubjID) +
    (1 | SubjID:chlabel),
  data = subset(erp_nw, time_window == "N250"),
  control = lmerControl(optimizer = "bobyqa")
)
```

---

### D2. N400 — Nonwords (your strongest ERP result)

**Question:**
Does language proficiency determine how familiarity modulates complexity costs?

```{r}
m_nw_N400 <- lmer(
  value ~ complexity*family_size*LP + complexity*family_size*OS +
    (1 | SubjID) +
    (1 | SubjID:chlabel),
  data = subset(erp_nw, time_window == "N400"),
  control = lmerControl(optimizer = "bobyqa")
)
```

**Critical follow-up:**

```{r}
emmeans(
  m_nw_N400,
  ~ complexity*family_size | LP,
  at = list(LP = c(-1, 0, 1))
)
```

---

## 4. What this buys you (big picture)

* **No dichotomization of individual differences**
* **No fake trial-level ERP regressions**
* **RT and ERP models differ for principled reasons**
* Exactly **6 core models** total:

  * RT words
  * RT nonwords
  * ERP words N250
  * ERP words N400
  * ERP nonwords N250
  * ERP nonwords N400

That is *reviewer-proof and conceptually tight*.

---

## 5. Next step (optional but powerful)

If you want, next I can:

* Help you **rewrite the Results section outline** so each model answers *one question*
* Decide which interactions move to **supplement**
* Draft **Methods text** that explicitly explains the RT vs ERP asymmetry (cleanly, in LaTeX)

But analytically: you’re now fully aligned with your data and theory.
