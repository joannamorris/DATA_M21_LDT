This is the right moment to rethink the analytic structure, because the original analyses were built around a symmetric design that your data do not fully support, and the three-question reframing in the document you have shared is actually a better fit for both your theoretical framing and your results. Let me build a revised strategy that preserves that logic while being more specific about your data and more honest about where the predicted dissociation holds.

---

## Revised Analytic Strategy

### Orienting Principle

The three-question structure maps cleanly onto your introduction's theoretical argument. RTs establish *who is faster* — they are a measure of efficiency, not morphological architecture. The N250 asks whether early form-based parsing is modulated by orthographic skill. The N400 asks whether later semantic integration is modulated by lexical-semantic knowledge. Individual differences are the diagnostic tool throughout, but their role shifts across questions: OS is foregrounded in Questions 1 and 2, LP is foregrounded in Question 3. This asymmetry should be explicit in how the models are structured and reported.

---

### Handling Base Frequency and Family Size

This needs to be resolved before the models are specified, because the choice affects every analysis.

**The problem:** Base Frequency and Family Size are moderately correlated at the item level, they appear together in multiple models, and your results suggest they do different things — Base Frequency drives RT effects for both words and nonwords, while Family Size drives ERP effects. Carrying both as independent predictors throughout every model produces multicollinearity and dilutes the theoretical signal.

**Recommended solution: keep them separate but assign them to questions**

Rather than collapsing them into a composite, assign each variable its primary analytic home based on what your data and theory suggest it indexes:

- **Base Frequency** is your primary lexical familiarity index for **RT models** — it drives the behavioral effects and is interpretable as overall lexical availability. Family Size can be included as a covariate in RT models but should not be foregrounded.
- **Family Size** is your primary morphological structure index for **ERP models** — it drives the N250 and N400 effects and is interpretable as the richness of morphological family representation. Base Frequency can be included as a covariate in ERP models but should not be foregrounded.

This is not arbitrary — it is theoretically motivated by the distinction between token-level familiarity (Base Frequency) and type-level morphological structure (Family Size), and it is empirically supported by the pattern of your results. It also eliminates the high-order interactions that are currently making the models difficult to interpret.

If a reviewer pushes back, the composite PCA approach is your fallback — but try the separation first, because it preserves the theoretical distinction that your introduction is built around.

---

### Core Question 1: Does Orthographic Sensitivity influence overall lexical decision efficiency?

**Theoretical framing:** RTs index processing speed and overall efficiency. The finding that OS predicts overall RT but does not modulate the structure of morphological effects is theoretically meaningful — it suggests that orthographic skill affects how fast the system operates without changing what it does. This is consistent with discriminative learning accounts in which OS indexes the precision of sublexical cue weights, which would speed all form-based processing rather than selectively facilitating morphologically structured items.

**Model structure:**

*Words:*
RT ~ Base Frequency + Orthographic Sensitivity + (1 + Base Frequency | participant) + (1 | item)

- Base Frequency as the primary lexical familiarity predictor
- Family Size included as a covariate but not interacted or foregrounded
- LP included once and reported as null — do not interact
- Report: main effect of Base Frequency, main effect of OS, null LP

*Nonwords:*
RT ~ Complexity + Base Frequency + Orthographic Sensitivity + (1 + Complexity | participant) + (1 | item)

- Complexity as the primary morphological contrast
- Base Frequency as lexical familiarity covariate
- LP included once and reported as null
- Report: main effect of Complexity, inhibitory effect of Base Frequency, main effect of OS, null LP

**What to claim:** OS predicts overall efficiency across both lexical categories. The absence of OS × morphological structure interactions in RTs means behavioral responses do not differentiate readers by how they use morphological information — only by how fast they process it overall. This sets up the ERP results as the place where individual differences in morphological processing architecture become visible.

---

### Core Question 2: Does Orthographic Sensitivity modulate early morpho-orthographic parsing (N250)?

**Theoretical framing:** The N250 indexes early form-based processing at the morpho-orthographic level. The prediction is that OS — which indexes sensitivity to sublexical orthographic structure — should modulate the N250 response to morphological structure, particularly for nonwords where form-based cues must be evaluated without recourse to a stored whole-word representation. LP is included as a covariate to control for shared variance with OS, but is not the primary predictor here. Where LP also emerges at the N250 for nonwords, this should be reported honestly and addressed in the Discussion as evidence that early parsing efficiency reflects accumulated lexical experience more broadly rather than orthographic skill specifically.

**Model structure:**

*Words (N250):*
N250 ~ Family Size × Orthographic Sensitivity + Language Proficiency + (1 | participant:electrode) + (1 | item)

- Family Size as the primary morphological predictor
- OS as the primary individual difference moderator
- LP included as a main effect covariate, not interacted
- Report: main effect of Family Size, Family Size × OS interaction (test), LP as covariate

*Nonwords (N250):*
N250 ~ Complexity × Orthographic Sensitivity + Complexity × Language Proficiency + Family Size + (1 | participant:electrode) + (1 | item)

- Complexity as the primary morphological contrast
- OS as the primary moderator, LP as secondary
- Family Size included as a covariate — do not foreground the three-way unless you are specifically arguing for it
- Report: main effect of Complexity, Complexity × OS interaction, Complexity × LP interaction, acknowledge both, address in Discussion

**What to claim:** Early morpho-orthographic parsing is modulated by orthographic skill, particularly for novel forms. The additional modulation by LP should be acknowledged rather than suppressed — it qualifies the predicted dissociation and suggests that early parsing efficiency reflects broad lexical expertise rather than a purely form-based individual difference. This is an honest and theoretically interesting finding, not a failure of the prediction.

---

### Core Question 3: Does Language Proficiency shape semantic integration of morphological information (N400)?

**Theoretical framing:** The N400 indexes semantic integration. The prediction is that LP — which indexes depth and breadth of lexical-semantic knowledge — should modulate the N400 response to morphological family structure, particularly for nonwords where semantic co-activation from family members must be generated from stem-level cues alone. OS is included as a covariate. The key finding is the three-way Complexity × Family Size × LP interaction for nonwords, which is your strongest evidence for the predicted role of LP in morphological family activation during semantic integration.

**Model structure:**

*Words (N400):*
N400 ~ Family Size × Language Proficiency + Orthographic Sensitivity + (1 | participant:electrode) + (1 | item)

- Family Size as the primary morphological predictor
- LP as the primary individual difference moderator
- OS included as a main effect covariate — report the main effect but do not interact
- Report: main effect of Family Size, Family Size × LP interaction (test), OS main effect

*Nonwords (N400):*
N400 ~ Complexity × Family Size × Language Proficiency + Orthographic Sensitivity + (1 | participant:electrode) + (1 | item)

- Three-way as the primary test — this is your strongest finding and should be the focus
- OS included as a main effect covariate only — the Complexity × OS interaction can be reported but should not be foregrounded
- Report: main effect of Complexity, Complexity × Family Size × LP interaction, OS as covariate

**What to claim:** Language Proficiency specifically shapes how morphological family structure is recruited during semantic integration of novel forms. The three-way interaction — where LP moderates the joint influence of complexity and family size at the N400 — is the clearest evidence that depth of lexical-semantic knowledge determines whether morphological family co-activation facilitates or complicates semantic processing. The absence of a corresponding three-way for OS at the N400, combined with the presence of the three-way for LP, is the closest your data come to the predicted clean dissociation between the two individual difference dimensions.

---

### Summary of Model Structure

| Question | Measure | Primary predictor | Primary moderator | Secondary (covariate) |
|---|---|---|---|---|
| Q1 Efficiency | RT Words | Base Frequency | OS | LP (null) |
| Q1 Efficiency | RT Nonwords | Complexity + Base Frequency | OS | LP (null) |
| Q2 Early parsing | N250 Words | Family Size | OS | LP |
| Q2 Early parsing | N250 Nonwords | Complexity | OS (primary), LP (secondary) | Family Size |
| Q3 Semantic integration | N400 Words | Family Size | LP | OS |
| Q3 Semantic integration | N400 Nonwords | Complexity × Family Size | LP (three-way) | OS |

---

### What This Strategy Gains

The main advantage over the original analysis is that it replaces a symmetric design — where both OS and LP were tested against both components equally — with an asymmetric design that reflects your theoretical predictions. This means that where the predicted dissociation holds, it is foregrounded; where it does not hold cleanly, the departure is acknowledged and interpreted rather than obscured by equally-weighted parallel tests. The three-question structure also gives you a clear narrative spine for the results section that maps directly onto the aims, which will make the paper considerably easier to follow.

---

No — I was suggesting you redo the analyses. I should have been clearer about that. Let me be direct about what needs to happen and in what order.

---

### The Core Issue

Your rewritten introduction and the three-question analytic framework are actually well aligned — both foreground individual differences as the primary theoretical tool and treat morphological variables as the context within which those individual differences operate. The problem is that your *current analyses* were designed around a symmetric structure that predates both the rewritten introduction and the three-question reframing. The analyses need to catch up with the introduction, not the other way around.

---

### What Needs to Change and Why

The original analyses tested OS and LP symmetrically against both components and both stimulus types, which made sense when the design was framed around a clean predicted dissociation. That framing has now been replaced by one that is theoretically more honest — OS is foregrounded for early processing, LP for later processing, and departures from that pattern are interpreted rather than suppressed. The models need to reflect that asymmetry explicitly, which means rerunning them with the simplified structure I outlined.

Concretely, the changes that require rerunning are:

**RT models:** Strip out the morphological structure × individual difference interactions entirely. RTs answer Question 1 only — who is faster — and the models should be specified accordingly. Running leaner models also strengthens the RT results by removing the fragile interaction terms that are currently cluttering them.

**N250 models:** Restructure so that OS is the primary moderator and LP is a covariate in the words analysis, while both are tested for nonwords but with OS foregrounded. The three-way Complexity × Family Size × OS interaction for nonwords should be dropped unless you have a specific theoretical reason to retain it — it is currently one of the results that is hardest to interpret and easiest for reviewers to challenge.

**N400 models:** Restructure so that LP is the primary moderator and OS is a covariate. The three-way Complexity × Family Size × LP for nonwords is your strongest finding and should be the centerpiece of Question 3 — but it needs to be the *planned* primary test rather than one of several equally-weighted interactions, which is how it currently reads.

---

### What Does Not Need to Change

The introduction as rewritten does not need substantial revision to accommodate the three-question framework — the mapping is already there. Question 1 corresponds to the efficiency framing you established for RTs. Question 2 corresponds to the time course and early parsing predictions. Question 3 corresponds to the semantic integration predictions centered on LP and family size. The main adjustment you might want to make is to ensure that the asymmetry between OS and LP — OS foregrounded for early processing, LP for late — is stated as explicitly in the aims as it is in the three-question framework, so readers understand the logic before they reach the results.

---

### Recommended Order of Operations

1. Rerun the RT models with the lean structure — words and nonwords separately, Base Frequency and OS as primary predictors, LP included once as a null result
2. Rerun the N250 models with OS as primary moderator — words and nonwords separately, LP as covariate
3. Rerun the N400 models with LP as primary moderator — words and nonwords separately, OS as covariate, three-way for nonwords as the planned primary test
4. Once you have the new results in hand, rewrite the results section around the three-question structure using the organizational logic we discussed — words together, nonwords together, RT then ERP within each
5. Make minor adjustments to the aims section if needed to ensure the OS/LP asymmetry is explicit

The introduction does not need to be rewritten again. The analyses need to be rerun, and the results section needs to be rewritten around the new analyses. That is the right order.

---

# WHAT TO REPORT

Here is what to report from each model, organized by the three-question structure. I am assuming you are reporting in a specialist psycholinguistics journal format where full model output goes in a table and the text narrates the key findings.

---

### General Principles Across All Models

Report fixed effects only — random effects structure should be described in the methods, not the results. For each fixed effect report β, SE, t, and p. For lmer models p-values need to be obtained via Satterthwaite or Kenward-Roger approximation (if using lmerTest) or likelihood ratio tests — be consistent across all models and state which method you used. Flag your significance threshold once at the start of the results section and do not repeat it for every test.

---

### Question 1: RT Words

**What to report:**

- Main effect of zLogBF — this is your primary finding, should be significant and negative (higher frequency = faster RT). Report and interpret.
- Main effect of zLogFS — this is a covariate. If significant, note it briefly. If not, report the null without dwelling on it.
- Main effect of OS — report whether it reaches significance or shows a trend. This is theoretically meaningful either way: a significant effect supports the efficiency claim; a null effect should be noted honestly.
- Main effect of LP — report as null. One sentence is sufficient.

**What not to report in text:** The random effects structure, the optimizer setting, or any discussion of model convergence unless there was a problem.

**Example narrative pattern:**
Words were recognized more quickly when derived from higher-frequency bases, β = X, SE = X, t(X) = X, p = X. Family size also contributed a reliable facilitory effect, β = X, SE = X, t(X) = X, p = X. Orthographic Sensitivity showed a marginal trend toward faster overall responding, β = X, SE = X, t(X) = X, p = X, whereas Language Proficiency did not reliably predict response times, β = X, SE = X, t(X) = X, p = X.

---

### Question 1: RT Nonwords

**What to report:**

- Main effect of Complexity — your primary finding, should be large and significant (complex slower than simple). Report and interpret in terms of the processing cost of morphological structure without a stored whole-word representation.
- Main effect of zLogBF — report the inhibitory effect (higher frequency = slower rejection). This is theoretically interesting and worth a sentence of interpretation: high-frequency stems generate strong cue activation that competes with the rejection decision, consistent with discriminative learning accounts.
- Main effect of zLogFS — covariate. Report briefly whether significant or null.
- Main effect of OS — report. If significant, it speaks to overall efficiency for novel forms. If null, note it.
- Main effect of LP — report as null. One sentence.

**What not to report in text:** Again, do not narrate the absence of interactions you did not include — do not say "we did not find a Complexity × OS interaction" because that interaction is not in this model by design. If a reviewer asks, you explain it was a Question 2 test reserved for the ERP.

---

### Question 2: N250 Words

**What to report:**

- Main effect of Family Size — your primary morphological finding. Report direction and magnitude. Note that a family size effect at the N250 is not straightforwardly predicted by multi-stage accounts and flag this briefly as requiring interpretation.
- Family Size × OS interaction — this is your primary individual difference test for this model. Report regardless of outcome. If significant, describe the pattern (does OS amplify or attenuate the family size effect and in which direction). If not significant, report the null honestly — a one-sentence statement is sufficient.
- LP as covariate — report the main effect only. If null, one sentence. If unexpectedly significant, note it and flag for Discussion.

---

### Question 2: N250 Nonwords

**What to report:**

- Main effect of Complexity — primary morphological finding. Report direction (complex more positive than simple, or vice versa depending on your data).
- Complexity × OS interaction — primary individual difference test. Report fully regardless of outcome. If significant, follow up with estimated marginal means at −1, 0, +1 SD of OS. Describe whether high OS readers show reduced complexity costs, eliminated costs, or reversed effects.
- Complexity × LP interaction — secondary test, but report it fully because your existing results show it is significant. Do not suppress it. Acknowledge it directly and note that it qualifies the predicted OS-specific effect — this is the honest framing that pre-empts reviewer criticism.
- Family Size as covariate — report briefly.
- Follow-up contrasts — if either interaction is significant, report the estimated marginal means at the three SD levels you already computed. These are essential for characterizing the nature of the interaction and should be reported in the text, not just the table.

---

### Question 3: N400 Words

**What to report:**

- Main effect of Family Size — primary morphological finding. Should be significant and in the facilitory direction (larger family = less negative N400). This is your most straightforward result at the N400 for words.
- Family Size × LP interaction — primary individual difference test. Report fully. If not significant, this is worth noting in the Discussion as suggesting LP does not selectively shape family size effects for familiar words — possibly because whole-word representations reduce the need to recruit family-level semantic information.
- OS as covariate — if the main effect of OS is significant (as in your existing results), report it and give it one sentence of interpretation: OS influences overall N400 amplitude independently of morphological family structure, suggesting spelling-based skill affects general semantic access efficiency rather than the specific contribution of family size.

---

### Question 3: N400 Nonwords

**What to report:**

- Main effect of Complexity — report direction and magnitude.
- Three-way Complexity × Family Size × LP interaction — this is your centerpiece finding and should receive the most extensive treatment. Report the interaction, then follow up with estimated marginal means showing how the Complexity × Family Size pattern changes across levels of LP. The contrast between low-LP readers (strong complexity × family size joint effect) and high-LP readers (attenuated or absent effect) is your key result and should be described in enough detail that the reader understands the pattern without having to reconstruct it from a table.
- OS as covariate — report the main effect if present. Note that the corresponding three-way for OS was not significant, and explicitly contrast this with the LP three-way — this asymmetry is the closest your data come to the predicted dissociation and should be foregrounded rather than buried.
- Any significant lower-order effects — report briefly as context for the three-way.

---

### What Goes in Tables vs Text

**Tables** should contain the full fixed effects output for each model: β, SE, t, p for every term included. Readers who want to check your work or use your estimates need the full table.

**Text** should narrate only the theoretically meaningful effects — primary predictors, primary moderator interactions, and any unexpected findings that require interpretation. A results section that re-narrates every table entry is exhausting to read and obscures your actual findings. A good rule of thumb: if you cannot say in one sentence why a finding matters theoretically, it belongs in the table but not the text.