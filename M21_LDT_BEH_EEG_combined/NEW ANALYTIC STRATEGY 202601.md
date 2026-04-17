# SIMPLIYING ANALYSIS APPROACH

the **analytic structure has grown to exceed the conceptual structure**. The results section is doing far more work than your theory actually requires.

Below I’ll do three things, in order:

1. **Diagnose why the current analyses feel unmanageable**
2. **Reconceptualize the study around a smaller number of defensible questions**
3. **Propose a simplified analytic plan** that preserves your theoretical commitments but dramatically reduces model proliferation and reporting burden


---

## 1. Why the current analysis feels unworkable (diagnosis)

There are four interacting sources of complexity:

### A. You are answering *too many questions simultaneously*

Right now, each analysis varies along all of these dimensions:

* Lexicality: words vs nonwords
* ERP component: N250 vs N400
* Item variables: Base Frequency, Family Size, Complexity
* Individual differences: Orthographic Sensitivity *and* Language Proficiency
* Grouping strategy: median split PCA dimensions
* Dependent measures: RTs, N250 amplitude, N400 amplitude

This yields **dozens of parallel models**, many of which:

* Test interactions that are not theoretically central
* Reproduce the same main effects (e.g., complexity costs for nonwords)
* Differ only trivially (e.g., Family Size vs Base Frequency versions)

Reviewers will not see “thoroughness”—they will see **analytic sprawl**.

---

### B. Orthographic Sensitivity and Language Proficiency are being treated as symmetric—but they are not

Conceptually, your paper argues for **functional dissociation**:

* Orthographic Sensitivity → early form-based processing (RT, N250)
* Language Proficiency → later meaning-based integration (N400)

But analytically, you:

* Run *every* analysis twice
* Give equal weight to null effects for proficiency in RTs
* Chase small three-way interactions that don’t advance the core dissociation

This creates the impression that the theory is weaker than it is.

---

### C. Item-level predictors are over-partitioned

Base Frequency and Family Size:

* Are conceptually related (both proxy lexical familiarity)
* Rarely interact meaningfully
* Generate many marginal or fragile interactions
* Are handled differently across words vs nonwords

This is inflating model count *without increasing interpretability*.

---

### D. The Results section is organized by **models**, not **claims**

Right now the reader has to infer:

* What *question* each analysis answers
* Why a given interaction matters
* How RT and ERP results relate

That cognitive load is what makes the section feel “too complicated,” even though the statistics themselves are sound.

---

## 2. Reframing the study around **three core questions**

Your entire paper can be defended around **three questions**—everything else should be subordinate.

---

### **Core Question 1 (Behavioral):**

> Does Orthographic Sensitivity influence overall efficiency in lexical decision, independent of semantic proficiency?

This question:

* Is *behavioral*
* Is about *speed*, not fine-grained morphology
* Directly motivates RTs

**Implication:**
RT analyses do *not* need to mirror ERP analyses.

---

### **Core Question 2 (Early neural processing):**

> Does Orthographic Sensitivity modulate early morpho-orthographic parsing (N250), particularly for morphologically structured forms?

This is:

* About *early time course*
* About *form-level structure*
* Where Orthographic Sensitivity should matter most

**Implication:**
Language Proficiency effects at N250 are secondary and should not drive the narrative.

---

### **Core Question 3 (Late neural processing):**

> Does Language Proficiency shape how morphological and lexical information is integrated at the semantic level (N400)?

This is:

* Your strongest theoretical contribution
* Where the richest interactions live
* Where reader profiles genuinely diverge

**Implication:**
This is where complexity belongs—and where you should *spend your analytic capital*.

---

## 3. A simplified analytic strategy (what to keep, merge, or drop)

Below is a **conceptually cleaner plan** that still respects your data.

---

## A. Reaction times: simplify aggressively

### Keep:

* **Words:**
  RT ~ Lexical Familiarity + Orthographic Sensitivity
* **Nonwords:**
  RT ~ Complexity + Orthographic Sensitivity

### Drop or de-emphasize:

* Language Proficiency in RTs (report as null, once)
* Parallel Base Frequency vs Family Size models
* Higher-order interactions unless *pre-registered or predicted*

### Conceptual reframing:

* Treat RTs as **indexing efficiency**, not morphology per se
* Collapse Base Frequency + Family Size into a **Lexical Familiarity composite** (or pick one)

> RTs establish *who is faster*, not *how morphology is represented*.

---

## B. N250: focus narrowly on form-based parsing

### Recommended structure:

* **Primary factor:** Orthographic Sensitivity
* **Primary contrast:** Morphological structure (complex vs simple; family size if theoretically justified)
* Analyze words and nonwords **separately but symmetrically**

### What to drop:

* Full factorial Base Frequency × Family Size × Proficiency models
* Language Proficiency as a headline factor at N250

### Interpretive shift:

* N250 effects answer:

  > *Is early morphological parsing more effortful or more efficient depending on orthographic skill?*

You already *have* that story—right now it’s buried under interactions.

---

## C. N400: where complexity is justified

This is where your current analyses actually shine—but need **containment**.

### Keep:

* Family Size × Base Frequency interactions **for words**
* Complexity × Family Size **for nonwords**
* Language Proficiency as a moderator

### Drop:

* Redundant reporting of null main effects
* Overly fine-grained simple-effects unless they support a claim

### Reframe interpretation:

Instead of:

> “Three-way interactions indicate…”

Use:

> “Language proficiency determines whether morphological familiarity amplifies or attenuates semantic processing demands.”

This lets you:

* Emphasize *patterns*
* Reduce numerical overload
* Align directly with the dual-pathway model

---

## 4. What the *new* Results section would look like (outline)

Just to make this concrete:

1. **Behavioral results (brief)**

   * Orthographic Sensitivity predicts faster RTs
   * Language Proficiency does not
   * Item-level effects replicate known frequency/complexity patterns

2. **N250: Early form-based processing**

   * Orthographic Sensitivity modulates responses to morphological structure
   * Effects strongest for nonwords
   * Language Proficiency plays a minimal role

3. **N400: Semantic integration**

   * Language Proficiency strongly modulates family size and frequency effects
   * High-proficiency readers show differentiated integration
   * Low-proficiency readers show amplified or indiscriminate responses

Each section answers *one question*.

---

## 5. Next step (if you want)

If you’d like, I can:

* Propose **exact models to keep vs drop**
* Rewrite the **Results section outline in LaTeX**
* Help you collapse Base Frequency / Family Size cleanly
* Help you decide whether to keep median splits or switch to continuous predictors

But at this stage: you’re not “overthinking”—you’re recognizing that the **analysis no longer matches the theory**, and that’s exactly the right instinct.

---

# how can I collapse Base Frequency / Family Size cleanly? 

You’ve basically got three “clean” options, depending on what you want the collapsed predictor to *mean*. The key is to avoid a Franken-variable that reviewers will (reasonably) think is arbitrary.

## Option 1 (simplest): pick one and demote the other

If your goal is *clarity*, the cleanest collapse is not a composite at all:

* Use **Base Frequency** as the single “lexical familiarity” index.
* Treat **Family Size** as either:

  * a covariate, or
  * a robustness check (“same pattern holds if we swap in Family Size”).

Why this is clean: Base frequency is widely understood, easy to interpret, and lets you tell a simpler story. Family size can be described as “morphological familiarity” and kept for ERP-focused analyses only (often N400).

**Best when:** you don’t need to argue that both carry independent theoretical meaning.

---

## Option 2 (principled composite): standardize then average (a “Lexical Familiarity” index)

If you want to treat them as two indicators of a shared construct (familiarity/availability), do this:

1. Transform as needed (usually log)
2. z-score each across items
3. Average them (or weighted average)

**Definition (item-level):**

* `BFz = z(log(BaseFreq))`
* `FSz = z(log(FamilySize + 1))` (the +1 avoids log(0))
* `LexFam = (BFz + FSz) / 2`

Then use `LexFam` as your single predictor.

Why this is clean:

* It’s transparent
* Keeps units comparable
* Treats each measure as equally informative
* Avoids fishing for which one “works” in which model

**Best when:** you want one predictor to reduce model count and you’re comfortable calling the shared construct “lexical/morphological familiarity.”

**One caution:** if BF and FS are only weakly correlated, reviewers may ask why you’re averaging them. You can answer that by showing their correlation and saying you’re using the composite *for parsimony* while also confirming results are similar when they’re entered separately.

---

## Option 3 (most defensible statistically): PCA on the item predictors

This is the “you can’t accuse me of arbitrariness” route.

Run PCA (or a single-factor model) on *item-level* predictors:

* log(Base Frequency)
* log(Family Size + 1)

If the first component captures most variance and both load positively, use **PC1** as “Familiarity”.

Why it’s clean:

* Data-driven, reproducible
* Automatically handles scaling/weighting
* You can report loadings

**Best when:** you anticipate pushback about composites, or BF/FS have different ranges.

---

# My recommendation for your paper

Given your goals (reduce model sprawl; tighten narrative):

* **RT models:** Option 1 (choose Base Frequency; keep Family Size out of RTs, or put it in as a covariate but don’t foreground it)
* **ERP N400 models:** Option 2 or 3, depending on how reviewer-proof you want to be

  * If you want maximum transparency: **Option 2**
  * If you want maximum defensibility: **Option 3**

This also matches your conceptual framework: RTs index general efficiency (orthography), while N400 is where “morphological/lexical familiarity” as a construct really matters.

---

## Concrete R snippets (pick one)

### Option 2: z-average composite

```r
items <- items %>%
  mutate(
    logBF = log(BaseFreq),
    logFS = log(FamilySize + 1),
    BFz = as.numeric(scale(logBF)),
    FSz = as.numeric(scale(logFS)),
    LexFam = (BFz + FSz) / 2
  )
```

### Option 3: PCA-based composite

```r
X <- items %>%
  transmute(
    logBF = log(BaseFreq),
    logFS = log(FamilySize + 1)
  )

pc <- prcomp(X, center = TRUE, scale. = TRUE)
items$LexFam_PC1 <- pc$x[,1]
summary(pc)      # variance explained
pc$rotation      # loadings
```

---

## Quick “sanity checks” to report (1–2 sentences, not a new section)

* Correlation of logBF and logFS
* Loadings (if PCA)
* Note that results are similar with BF/FS separate (you can confirm in supplement)

---

If you tell me which outcome you care about most for the composite (RT parsimony vs ERP interpretability vs reviewer-proofing), I’ll recommend one and give you a drop-in paragraph for your Methods (“Lexical familiarity index…”) in LaTeX.

---

# Should I use continuous predictors for Orthographic Sensitivity and Language Proficiency or dichotomize them?

Use them as **continuous** predictors in your primary analyses.

Dichotomizing (median split / above–below zero) will almost always make the paper harder to defend because it (a) throws away information, (b) reduces power, (c) can create “interaction-looking” patterns that are partly artifacts of the split, and (d) invites reviewer requests to rerun everything continuously anyway.

### A clean, reviewer-proof compromise

* **Primary models:** continuous Orthographic Sensitivity and Language Proficiency (your PCA scores are perfect for this).
* **Figures / descriptives:** you *can* show “high vs low” groups for visualization only (e.g., ±1 SD or quartiles), explicitly labeled as display choices, not inferential.

That lets you keep the intuitive dual-pathway story without basing inference on an arbitrary cutoff.

---

## How this simplifies your whole paper

Right now you run everything twice (one split by OS, one split by LP). If you go continuous, you can often run **one model** with both predictors:

* Include **both PCA dimensions** simultaneously:

  * OS (Dimension 2) and LP (Dimension 1)
* Test the interactions that map onto your theory:

  * N250: OS × (morphological structure)
  * N400: LP × (semantic/morphological familiarity)

This matches your conceptual framework and reduces the “parallel analyses” problem.

---

## Practical modeling advice (very doable with afex / lme4)

### Keep both continuous predictors in the same model

Example sketch (words, RT or ERP), using your familiarity predictor(s):

```r
dv ~ LexFam * OS + LexFam * LP + (random effects)
```

If you truly expect dissociation:

* N250: OS interactions should be stronger than LP interactions
* N400: LP interactions should be stronger than OS interactions

You can formalize that by directly comparing effect sizes or doing model comparisons (drop LP interactions from N250; drop OS interactions from N400) rather than running two separate “grouped” analyses.

---

## When dichotomizing is defensible (rare)

I’d only dichotomize if **one** of these is true:

1. **Pre-registered** grouping, with a theoretically motivated cutoff (not median split).
2. Your audience absolutely requires categorical groups (e.g., diagnosed impairment vs control), which you don’t have here.
3. You have strong evidence of a **nonlinear / threshold** effect and you model it appropriately (even then, better to use splines or polynomial terms than a hard split).

Otherwise, treat dichotomized analyses as **supplemental robustness checks** at most.

---

## One important note about your current PCA grouping rule

“Above vs below 0” on PCA scores is essentially a sign split, not a principled threshold. Reviewers will clock that immediately. If you keep any grouping for plots, use:

* **±1 SD** (clear meaning), or
* **top vs bottom quartile** (more separation), and say it’s for visualization.

---

### Recommendation for your manuscript

* Rewrite Methods to say: *“Orthographic Sensitivity and Language Proficiency were entered as continuous PCA scores.”*
* Move any median-split/group results to **supplement** (or drop entirely unless a key figure depends on it).

If you want, paste one representative model (e.g., N400 words) and I’ll show you exactly how I’d re-express it with **both** continuous predictors + a collapsed familiarity term, while keeping your random-effects structure comparable.

---

# I have trial level data (continous Base frequency and family size) for response times but not for ERPs

This is a *very* important realization—and it actually **rescues** your original analytic instincts rather than undermining them. You were not being sloppy or old-fashioned; you were responding to a real constraint of ERP data structure.

Let me walk you through this carefully, because there *is* a clean, principled way forward that preserves signal quality **and** simplifies the paper.

---

## 1. You did the right thing for ERPs — but the interpretation drifted

You are absolutely right:

* **ERP amplitudes are not trial-level observations in the same sense as RTs**
* Averaging across trials/items is standard and often necessary
* Once you average across items, you no longer *have* continuous item-level predictors at the observation level

So the question is not:

> “Should I have used continuous predictors for ERPs?”

but rather:

> “How should I align my ERP analyses with the level at which the data actually exist?”

This reframing is key.

---

## 2. What this means conceptually: level of analysis mismatch

You currently have:

| Measure | Data level         | Predictors         |
| ------- | ------------------ | ------------------ |
| RT      | trial/item level   | continuous BF, FS  |
| ERP     | condition-averaged | categorical BF, FS |

That is **not a problem**—*as long as you acknowledge and exploit the distinction rather than fighting it.*

Where things went off the rails is that the **ERP analyses were made to look parallel to RT analyses**, even though the data structure is fundamentally different.

---

## 3. Why dichotomizing BF / FS is defensible *for ERPs specifically*

For ERPs, you are not estimating a slope of BF → amplitude. You are estimating:

> “Does neural activity differ between conditions that differ in average familiarity?”

That is a **categorical contrast**, not a regression.

So:

* Dichotomizing BF and FS at the *item selection / averaging stage* is legitimate
* Especially when the goal is SNR, not fine-grained psychometric modeling

Many classic ERP papers do exactly this, even if they don’t spell it out.

---

## 4. The real problem was not dichotomization — it was *over-conditioning*

You did *too many* categorical splits:

* BF × FS × Complexity × Proficiency × Lexicality × Component

That creates cells with:

* Fewer trials
* More noise
* Harder interpretation

The fix is **not** “make everything continuous,” but:

> **Reduce the number of ERP conditions to those that answer your theoretical questions.**

---

## 5. A clean ERP strategy that respects averaging

Here is what I recommend **specifically for ERPs**, given your data structure.

---

### A. Treat ERP predictors as *condition-level factors*, not item-level variables

For ERPs:

* BF and FS are **design factors**, not covariates
* OS and LP are **subject-level continuous predictors**
* ERP amplitude is a **summary measure**, not a trial outcome

This justifies **mixed models with categorical predictors**, or even repeated-measures ANOVA–style logic, *without apology*.

---

### B. Collapse BF and FS *at the ERP level*

Instead of treating BF and FS as separate factors everywhere, do one of the following:

#### Option 1 (strongly recommended): choose **one** familiarity manipulation per ERP analysis

* **Words:** use **Family Size** (morphological richness)
* **Nonwords:** use **Complexity** (structural parsing load)

Base Frequency can be:

* Dropped from ERPs entirely, or
* Mentioned as part of stimulus matching

This is the **single biggest simplification** you can make.

---

#### Option 2 (if you must keep both): collapse BF and FS into a *single ERP factor*

Define:

* High familiarity vs Low familiarity conditions
* Based on the *mean* BF/FS of items contributing to each ERP average

Then ERP models look like:

> Amplitude ~ Familiarity × Proficiency

This aligns perfectly with your dual-pathway model.

---

### C. Stop mirroring RT and ERP analyses

This is crucial.

RTs answer:

> “How efficiently is the decision made?”

ERPs answer:

> “How is information represented over time?”

They **should not have isomorphic models**.

Once you accept that, a lot of pressure disappears.

---

## 6. What I would do *concretely* with your existing ERP data

### N250

* Words:

  * Family Size (high vs low)
  * Orthographic Sensitivity (continuous)
* Nonwords:

  * Complexity (simple vs complex)
  * Orthographic Sensitivity

Language Proficiency included, but not foregrounded.

---

### N400

* Words:

  * Family Size (or Familiarity composite)
  * Language Proficiency (continuous)
* Nonwords:

  * Complexity × Familiarity (if you keep it)
  * Language Proficiency

This retains your strongest effects and eliminates fragile high-order interactions.

---

## 7. How to justify this cleanly in the paper (1–2 sentences)

You can say something like:

> “Because ERP amplitudes were computed from condition-averaged waveforms to improve signal-to-noise ratio, item-level predictors such as base frequency and family size were operationalized as categorical condition factors rather than continuous trial-level covariates. Reaction time analyses, by contrast, were conducted at the trial level and therefore modeled lexical variables continuously.”

This completely defuses reviewer concerns.

---

## 8. Where this leaves your earlier question about continuous predictors

| Predictor                | RT         | ERP                      |
| ------------------------ | ---------- | ------------------------ |
| Base Frequency           | continuous | categorical or dropped   |
| Family Size              | continuous | categorical or collapsed |
| Orthographic Sensitivity | continuous | continuous               |
| Language Proficiency     | continuous | continuous               |

That asymmetry is **methodologically correct**, not a flaw.

---

## 9. Next step (very concrete)

If you want, next we can:

* Redesign your ERP condition structure explicitly (how many bins, which contrasts)
* Rewrite your ERP Methods section to reflect this logic cleanly
* Decide exactly which ERP interactions to keep vs cut
* Align your Results narrative so reviewers see *intentional design*, not analytic drift

You caught something important here—and it actually gives you permission to simplify rather than complicate.
