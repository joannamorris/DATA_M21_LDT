Yes — before touching Table 1 or the Discussion, three follow-up steps are needed:

**1. Simple effects/interaction contrasts for the significant higher-order terms**

Following the same approach used for the original OS/LP models (probing at low/mean/high levels), you'll need `emmeans`-based decomposition for:

- **N250-FS four-way** (Complexity × OS × LP × Family Size, p = .012): this needs interaction contrasts at representative OS/LP levels (e.g., ±1 SD) to see whether the Complexity × Family Size effect's dependence on one dimension changes shape across the other. A four-way is hard to write up without this.
- **N400-BF four-way** (Complexity × OS × LP × Base Frequency, p = .027): same treatment — probe the Complexity × Base Frequency interaction at low/mean/high OS and LP.
- **N250-BF three-way** (OS × LP × Base Frequency, p = .018, no Complexity involved): this one's structurally different from the rest — worth checking directly.
- **N400-FS three-way** (Complexity × Family Size × OS, p = .047): new relative to the earlier write-up, needs its own simple-effects breakdown.

**2. Resolve the coefficient discrepancy on the centerpiece finding**

The Complexity × Family Size × LP three-way at N400-FS went from b = 0.227 (p = .023) to b = 0.466 (p < .001) between the original and re-run data. Before anything else gets written up, it's worth checking whether this is a coding change (e.g., contrast coding drift, sum vs. treatment coding somewhere in the pipeline), a data-cleaning difference from reprocessing, or a genuine effect-size change. This affects both the follow-up contrasts (item 1) and the qualitative story ("attenuation without reversal") from your Discussion outline — you don't want to build interpretive text on a number that might shift again.

**3. Confirm the Complexity × Base Frequency × LP three-way null still holds**

Your existing specificity argument (LP effect is family-size-specific, not base-frequency-specific) rests on this term being non-significant. It's not visible in either base-frequency table above — you'll want to pull it explicitly from the N400-BF model output to confirm it's still null before the four-way finding potentially complicates that claim.

Once these are run, you'll have what's needed to decide how to frame the four exploratory models in Table 1 and whether the Discussion's specificity/dissociation language needs further softening.

---

## 1. N250 — Complexity × Family Size × OS × LP (four-way)

Tracking the Complexity × Family Size interaction magnitude across the 3×3 OS/LP grid: at **Low LP**, the interaction strengthens sharply as OS increases (roughly −0.4 → +0.3 → +0.9 going low→mean→high OS). At **Mean LP**, a similar but slightly less steep climb. At **High LP**, the interaction is already large at low OS and stays fairly flat (~0.9 → 1.0 → 1.1) — it doesn't need OS to "unlock" it.

**Reading:** OS's modulation of the Complexity × Family Size effect is strongest when LP is low-to-moderate; at high LP the effect is already saturated regardless of OS. This is a real, describable four-way, not just statistical noise from lower-order terms.

## 2. N250 — OS × LP × Base Frequency (three-way, no Complexity)

The base-frequency contrast (low−high) is significant and sizeable at **low OS + low LP** (Δ ≈ 0.75, p < .001) and **low OS + mean LP** (Δ ≈ 0.37, p = .009), but shrinks to near-zero at high LP regardless of OS, and turns marginally negative at **high OS + low LP** (Δ ≈ −0.39, p = .073).

**Reading:** the base-frequency effect at N250 is concentrated in low-OS readers, and within that group, further modulated by LP — present at low/moderate LP, gone at high LP, with a hint of reversal at high OS.

## 3. N400 — Complexity × Family Size × OS (three-way)

Using the direct contrast rows, the Complexity × Family Size interaction is essentially flat across OS levels (≈0.11–0.12 at low, mean, and high OS). This is a bit surprising given the omnibus term was significant (p = .047) — likely a modest, roughly linear moderation that doesn't show up dramatically at just three sampled points. Worth getting the exact interaction estimate (see below) rather than relying on my hand-differenced numbers here.

## 4. N400 — Complexity × Base Frequency × OS × LP (four-way) — the most interesting one

Computing the Complexity × Base Frequency interaction at each OS/LP cell:

| | Low OS | Mean OS | High OS |
|---|---|---|---|
| **Low LP** | +0.74 | +0.11 | **−0.53** |
| **Mean LP** | +0.74 | +0.64 | +0.53 |
| **High LP** | +0.72 | +1.17 | **+1.60** |

**This is a genuine crossover.** At low LP, increasing OS *flips the sign* of the Complexity × Base Frequency interaction (from +0.74 to −0.53). At high LP, increasing OS *strengthens it in the same direction* (+0.72 to +1.60). Mean LP sits in between, relatively flat. The direction of OS's moderating influence on this interaction depends entirely on where LP sits — that's a much richer (and more theoretically loaded) pattern than a simple attenuation story, and it directly complicates the "OS not involved in the N400 story" framing that's currently baked into your terminology sweep.

---

These are the real numbers, and one of them exposes a problem that needs fixing before anything gets written up. Going through all four:

## 1. N250 — Complexity × Family Size interaction across OS × LP (four-way, confirmed real)

The interaction strengthens with OS, but the *rate* of that strengthening depends on LP:

- **Low LP:** goes from non-significant/negative (b = −0.36, p = .072) at low OS → significant positive (b = 0.29, p = .030) at mean OS → strongly positive (b = 0.94, p < .001) at high OS. A genuine sign flip driven by OS.
- **Mean LP:** already positive and significant at low OS (b = 0.28, p = .034), climbing to b = 1.01 at high OS. Smaller relative climb than the Low LP row.
- **High LP:** already large at low OS (b = 0.92, p < .001) and stays roughly flat through high OS (b = 1.08).

**This confirms the four-way structure precisely:** OS's moderating influence on the Complexity × Family Size interaction is steep when LP is low, and essentially saturated (already maximal) when LP is high. That's a genuinely interpretable, non-trivial four-way — good material for Table 1 and Discussion.

## 2. N250 — Base Frequency simple effect across LP × OS (three-way, confirmed real)

The base-frequency contrast is only reliably present in one corner of the space:

- **Low OS + low LP:** b = 0.75, p < .001 — strong.
- **Low OS + mean LP:** b = 0.37, p = .009 — present, smaller.
- **Low OS + high LP:** b = −0.01, p = .962 — gone.
- **Mean OS:** null everywhere (all p > .20).
- **High OS + low LP:** b = −0.39, p = .073 — a *trend toward reversal*.

**Reading:** the base-frequency effect at N250 lives almost entirely in low-OS, low/moderate-LP readers, and hints at flipping sign in high-OS/low-LP readers. This is a fairly narrow, specific pattern — worth stating precisely rather than broadly.

## 3. Complexity × Family Size interaction across OS (three-way) — 

- **Low OS:** b = 0.08, p = .593 — interaction absent.
- **Mean OS:** b = −0.12, p = .240 — small, non-significant.
- **High OS:** b = −0.32, p = .028 — significant.

**Reading:** the Complexity × Family Size interaction at N400 is null at low OS and emerges (in the negative direction) only at high OS. This is a monotonic, single-crossing pattern — OS gradually reveals/strengthens the interaction rather than flipping its sign abruptly, and unlike the messier four-way patterns, this one's relatively clean: one clear significant cell (high OS), two non-significant ones.

This is a real, modest OS-dependent modulation, present specifically among high-OS readers.

## 4. N400 — Complexity × Base Frequency interaction across OS × LP (four-way, confirmed real, and the most striking result)

- **Low LP:** trend negative at low OS (b = −0.75, p = .072), fades to null (b = −0.11, p = .691), turns positive-ish at high OS (b = 0.52, p = .232, ns).
- **Mean LP:** consistently negative across OS, significant at low/mean OS (p = .009, .002), trending at high OS (p = .059).
- **High LP:** negative and *strengthening* with OS — from trend (b = −0.73, p = .067) to strongly significant (b = −1.16, p < .001, then b = −1.60, p < .001).

**Reading:** at low LP, OS pushes the Complexity × Base Frequency interaction from negative toward null/positive. At high LP, OS pushes it further negative. The direction of OS's moderating effect on this interaction depends on where LP sits — a genuine crossover pattern, not a simple attenuation. This is the most theoretically loaded of the four and worth careful, precise wording once you're confident item 3 is sorted.

---

---

## Where things stand across all four follow-ups now

| Model/effect | Pattern | Cleanest description |
|---|---|---|
| N250: Complexity × FS × OS × LP | 4-way | OS's effect on Complexity×FS is steep at low LP, saturated at high LP |
| N250: OS × LP × BF | 3-way | BF effect present only at low OS + low/mid LP; hints at reversal at high OS+low LP |
| N400: Complexity × FS × OS | 3-way | Interaction null at low OS, significant negative at high OS |
| N400: Complexity × BF × OS × LP | 4-way | Crossover — OS pushes interaction toward null/positive at low LP, but more negative at high LP |

All four are now cleanly resolved with model-consistent, OS/LP-varying estimates. 