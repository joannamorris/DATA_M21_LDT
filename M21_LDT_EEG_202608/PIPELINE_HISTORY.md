# ERP_pipeline.m — Development & Debugging History

This document is for whoever maintains, extends, or debugs this pipeline
next — including a future version of whoever is reading this now. It
records *why* the code looks the way it does in places that aren't
self-explanatory, and captures several bugs that were genuinely difficult
to find, so they don't need to be rediscovered from scratch.

This is not a user guide. For how to run the pipeline, see `README.md`.

---

## Timeline (brief orientation)

1. Pipeline crashed at the interpolation step (Stage 5) with an array-bounds
   error.
2. Root cause traced to a channel (`HEOG`) created during re-referencing
   that was never accounted for in the original 32-channel montage
   definition.
3. Fixing that surfaced a deeper design problem: `pop_clean_rawdata` was
   being run on *all* channels, including non-scalp reference channels it
   can't meaningfully evaluate.
4. Splitting scalp from non-scalp channels before cleaning surfaced a
   second bug: one scalp channel (`Pz`) was silently losing its 3D
   coordinates during re-referencing.
5. The fix for that bug introduced a new bug (a duplicate re-reference
   call) that went undetected for several sessions because it happened to
   be mathematically harmless for this specific montage — but would not
   have been harmless for a different one.
6. A third, more serious bug was found: the pipeline's channel-restoration
   logic was trusting stale metadata rather than checking what was
   actually removed, risking silent corruption of real EOG/mastoid data.
7. The pipeline was generalized to support a second recording site
   (Providence College), which required working out which fixes were
   genuinely general and which were specific to the first site's
   properties.
8. Several workflow features were added on top of a stable pipeline:
   run-time tracking, a checkpoint/skip system to avoid redundant ICA
   computation across multi-pass studies, timestamped output folders, and
   an optional bin-structure label.

---

## Part 1 — Bugs found and fixed

### 1.1 The original crash: array-bounds error at interpolation

**Symptom:** `EEG.data = EEG.data(reorder, :);` failed with `Index in
position 1 exceeds array bounds. Index must not exceed 32.`

**Diagnosis:** Adding a debug print of `EEG.chanlocs` right before the
crash showed **33** channels, not the expected 32 — including a channel
labeled `HEOG` that didn't appear anywhere in the canonical 32-channel
montage list (`HC_create_chan_locs.m`).

**Root cause:** `HEOG` is a *derived* channel, created by the
re-referencing formula file
(`reref_eq_brainvision_hampshire.txt`, line: `nch33 = ((ch30+ch31)/2)
Label HEOG`) — it doesn't exist in the raw recording, only after
re-referencing. The original montage definition was built before this
channel existed in the pipeline's design and was never updated to include
it. `pop_clean_rawdata` flagged this channel as bad (it has no scalp
location) and removed it; `eeg_interp` then correctly tried to restore it
— but the bookkeeping code restoring channel order still expected exactly
32 channels.

**Fix:** Confirmed `HEOG` is a real, intentional channel (not a bug in the
`.ced` file or reref formula) and updated the channel-order restoration
logic to work from the actual post-re-reference channel list rather than
an assumption of "32 channels."

---

### 1.2 `pop_clean_rawdata` cannot meaningfully evaluate non-scalp channels

**The deeper problem 1.1 pointed to:** `pop_clean_rawdata`/`clean_artifacts`
has **no parameter to restrict which channels it evaluates** (confirmed via
`help clean_artifacts` — no `'channels'`, no exclusion option of any kind).
Its channel-quality criteria (`ChannelCriterion`, correlation with
neighbors, etc.) assume scalp EEG statistics; running it on mastoid/EOG
reference channels is meaningless at best, and interpolating a "bad"
channel that has no scalp location afterward is not well-defined at all.

**Fix:** Split the dataset into scalp (`EEG_scalp`) and non-scalp
(`EEG_nonscalp`) channel subsets *before* calling `pop_clean_rawdata`, run
cleaning only on the scalp subset, then recombine.

**Implementation note:** `pop_mergechan` does not exist in this EEGLAB
installation. Channels were recombined manually:
```matlab
EEG.data     = [EEG_scalp.data; EEG_nonscalp.data];
EEG.chanlocs = [EEG_scalp.chanlocs, EEG_nonscalp.chanlocs];
```
This is only safe because `BurstCriterion` and `WindowCriterion` are set to
`'off'` in the `pop_clean_rawdata` call — meaning no *time segments* are
ever removed, only channels, so `EEG_scalp` and `EEG_nonscalp` are
guaranteed to have identical sample counts. **If those criteria are ever
turned on, this manual concatenation would silently break** (mismatched
sample counts), and would need a real merge function or a redesign.

---

### 1.3 A scalp channel (`Pz`) silently losing its coordinates

**Symptom:** After splitting scalp/non-scalp (fix 1.2), *all 27* scalp
channels were being flagged as bad and removed — clearly wrong.

**Diagnosis:** Printing `EEG_scalp.chanlocs.X` for all channels showed 26
valid numeric values and one empty (`Pz`). `pop_clean_rawdata`'s
channel-correlation criterion apparently cannot compute anything sensible
once even one channel in the set has no coordinates, and ends up rejecting
everything.

**Two hypotheses that were checked and ruled out** before finding the real
cause — worth recording since both looked plausible at first:
- *Case mismatch (`Pz` vs `PZ`)* — checked the actual `.ced` file
  (`M21_Hampshire_32ch.ced`): `Pz`'s row had entirely correct, valid data.
  Not the source.
- *Formatting difference in the reref formula file* — checked
  `reref_eq_brainvision_hampshire.txt`: every line, including `Pz`'s, had
  identical syntax to all the working channels. Not the source.

**Actual cause, found by bisection:** printed `EEG.chanlocs(11).X`
immediately after the channel-locations lookup (`pop_chanedit(...,
'lookup', ...)`) and again immediately after re-referencing
(`pop_eegchanoperator`). `Pz`'s coordinate was correct after the lookup and
gone after re-referencing. Conclusion: `pop_eegchanoperator` does not
reliably preserve `chanlocs` geometry for every formula-created output
channel — `Pz` happened to be the one channel affected in this montage,
for reasons not fully understood (likely an internal quirk of how ERPLAB's
channel operator propagates geometry for non-recursive formula
evaluation).

**Fix:** Re-run the coordinate lookup a second time, immediately after
re-referencing:
```matlab
EEG = pop_eegchanoperator(EEG, reref_file, 'Saveas', 'off');
...
EEG = pop_chanedit(EEG, 'lookup', chan_locs_file);
```
This restores geometry from the same known-good `.ced` file without
touching the actual signal data.

---

### 1.4 A duplicate re-reference call (introduced while fixing 1.3, self-inflicted)

**What happened:** The fix for 1.3 was given as a two-line snippet, but the
snippet mistakenly included *both* a re-run of `pop_eegchanoperator` (the
re-reference step itself) *and* the `pop_chanedit` lookup — when only the
lookup should have been repeated. The re-reference formula was being
applied to the data **twice**.

**Why this went unnoticed for a while:** Hampshire's re-reference formula
subtracts the *average* of two mastoid channels:
```
nch_i = ch_i − (ch28 + ch29) / 2
```
After one application, `nch29 = −nch28` exactly (this can be shown
algebraically from the formula itself), so `nch28 + nch29 = 0` identically
— for every subject, every timepoint. A **second** application of the
formula therefore subtracts exactly zero: it's a mathematical no-op for
this specific montage. The duplicate call produced no visible symptom
because there was nothing to see.

**Why it mattered anyway:** Providence College's re-reference formula
subtracts *half of one single channel*:
```
nch_i = ch_i − ch10 / 2
```
This is **not** idempotent. After one pass, `nch10 = ch10/2`; a second pass
would subtract `nch10/2 = ch10/4`, giving `ch_i − (3/4)·ch10` — a
different, wrong result. Had this duplicate call been carried into a
Providence run unnoticed, it would have **silently corrupted every
channel's data**, with no symptom visible in any of the coordinate-based
diagnostics used to catch 1.3 (`chanlocs.X` is spatial metadata, entirely
separate from the actual voltage samples in `EEG.data`).

**Fix:** Removed the redundant `pop_eegchanoperator` call, keeping only the
coordinate re-lookup.

**Lesson:** A fix that "looks like it worked" on one montage may be relying
on a mathematical coincidence specific to that montage's reference scheme.
Before trusting behavior generalizes across sites, work out whether it's
actually guaranteed or just observed.

---

### 1.5 Stale metadata causing real channel data to be overwritten (the most serious bug)

**Symptom:** Even after 1.2–1.4 were fixed and confirmed working (a
diagnostic check showed `pop_clean_rawdata` had found **zero** bad
channels — `EEG_scalp.etc.clean_channel_mask` didn't even exist, meaning
nothing was flagged), Stage 5 still reported *"Interpolating 6 removed
channel(s)"* and proceeded to spherically interpolate all six non-scalp
channels (`Mastoid R/L`, `HEOG R/L`, `VEOG L`, `HEOG`) — channels that were
never given to `pop_clean_rawdata` in the first place, since they'd been
split off into `EEG_nonscalp` and never touched.

**Root cause:** `EEG.chaninfo.removedchans` was not a record of what
`pop_clean_rawdata` actually removed. It appears to be populated instead by
the `pop_chanedit(..., 'lookup', ...)` step — logging channels for which no
scalp location could be found (confirmed by the console message *"Channel
lookup: no location for HEOG"* appearing at the lookup step, long before
cleaning). This stale list then survived unchanged through `pop_select`
(which doesn't touch `chaninfo`) and the manual scalp/non-scalp
recombination, all the way to Stage 5 — where the interpolation code was
trusting it as ground truth.

**Why this was serious:** `eeg_interp` was being called on six channels
that were fully present with real, recorded voltage data. Spherically
"interpolating" a channel that has no scalp location produces a
meaningless value derived from nearby scalp channels — this was at risk of
silently overwriting genuine EOG/mastoid signal with fabricated data, with
no error raised anywhere.

**Fix:** Replaced the `chaninfo.removedchans`-based check with a direct
before/after label comparison around the `pop_clean_rawdata` call:
```matlab
scalp_labels_before = {EEG_scalp.chanlocs.labels};
EEG_scalp = pop_clean_rawdata(EEG_scalp, ...);
scalp_labels_after = {EEG_scalp.chanlocs.labels};
true_removed_scalp_labels = setdiff(scalp_labels_before, scalp_labels_after, 'stable');
```
`true_removed_scalp_labels` is now the single source of truth used by
Stage 5's interpolation step. `EEG.chaninfo.removedchans` is explicitly
cleared (`= []`) after cleaning so it can't confuse anything downstream
(including `eeg_checkset`, which may otherwise treat the stale field as
inconsistent with the actual channel list).

**Consequence for existing data:** Every `.erp` file produced before this
fix should be considered untrustworthy specifically for the non-scalp
channels, and reprocessed.

---

### 1.6 ICA reporting fewer components than channels — investigated, found to be correct behavior

**Symptom:** After all of the above fixes, the console showed *"Data rank
(31) is smaller than the number of channels (33)"* — initially flagged as
a possible fourth missing-channel mystery.

**Resolution:** This is expected, not a bug. Hampshire's mastoid-average
reference formula (see 1.4) forces `nch29 = −nch28` exactly — a hard
linear dependency baked into the data by construction, regardless of data
quality. 33 channels with one exact linear dependency between two of them
can have rank at most 31. EEGLAB's ICA correctly detects this via PCA and
fits exactly 31 components rather than attempting a mathematically
impossible 33. Nothing is missing from `EEG.data` at any point —
`pop_subcomp` afterward reconstructs the full 33-channel dataset with the
flagged components' contribution removed.

**Generalization caveat (important for Providence data):** This "N−2"
pattern is a property of Hampshire's specific *average-of-two-channels*
reference scheme. Providence's *single-channel half-subtraction* scheme
(`nch_i = ch_i − ch10/2`) is mathematically full-rank — its transform
matrix has nonzero determinant (0.5), meaning it's invertible and forces no
such dependency. **A Providence subject showing full-rank (31/31) ICA
output is the correct, expected result — not a discrepancy from
Hampshire's behavior.** If a Providence subject *does* show reduced rank,
that reflects something genuinely notable about that subject's actual data
(e.g. a bridged or flat channel), not the reference scheme, and is worth
investigating rather than dismissing.

---

### 1.7 Providence's re-reference file had inconsistent label syntax

**Found while generalizing to the second site.** `reref_eq_pchpl.txt` used
`LabelFp1` (no space) for channels 1–9 and `Label TP9` (correct spacing)
for channels 10–31 — almost certainly a copy-paste or find-replace
artifact. Not yet confirmed whether `pop_eegchanoperator` actually fails to
parse the fused form, but given how much time the equally-subtle Pz bug
(1.3) cost, this was fixed proactively rather than tested destructively:
spacing was added uniformly, and a `diff` confirmed *only* the spacing
changed — no formula or channel-number edits.

---

## Part 2 — Deliberate design decisions (not bugs, but worth understanding)

### 2.1 Generalizing scalp/non-scalp handling for two sites

The original split logic (1.2) hardcoded `scalp_idx = 1:27` and
`nonscalp_idx = 28:...` directly inside Stage 3. This was fine for
Hampshire but wrong for Providence — Providence has no non-scalp channels
at all (confirmed from `PC_create_chan_locs.m`: all 31 channels are
genuine 10-10-system electrodes with real coordinates), so treating
channels 28–31 as if they were mastoid/EOG channels would have incorrectly
excluded legitimate scalp data from bad-channel detection.

Fixed by moving `scalp_idx`/`nonscalp_idx` into the per-site config block
(alongside `chan_locs_file`, `reref_file`, `chan_num`), with Providence
setting `nonscalp_idx = []`. Stage 3 now branches on `isempty(nonscalp_idx)`
rather than hardcoding values, so it automatically does the right thing
for either site.

### 2.2 The checkpoint system (Stages 2–5 vs. Stage 6 onward)

Some studies need the same subjects binned more than one way (e.g. by
family size in one pass, base frequency in another). Filtering, resampling,
re-referencing, bad-channel removal, ICA, and interpolation don't depend on
which bin descriptor file is used — only bin assignment and everything
downstream does.

Rather than restructuring into a single script invocation that
automatically loops over multiple bin structures (which would have required
dialog changes and splitting the trial-counts output by bin structure,
since different bin structures produce different columns), the simpler
choice was made: keep running the script once per bin structure, but save
a checkpoint file after Stage 5 (`..._CLN_ICA_INT.set`) and check for its
existence at the start of each subject's processing. If found, Stages 2–5
are skipped entirely and the checkpoint is loaded directly. This avoids
redundant ICA computation (the slowest stage) and redundant disk usage
(each subject's continuous data can be several hundred MB) across passes,
with a comparatively small, contained code change.

### 2.3 Timestamped output folders instead of merge-on-write

An earlier concern: running the pipeline twice under the same study/task/
bin-structure label would overwrite the aggregate log/CSV/summary files,
since they were opened in `'w'` (truncate) mode and sized to the *current*
subject list. Re-running a subset of subjects (e.g. 3 problem subjects out
of 35) would silently discard the other 32 subjects' data from those files.

Two designs were considered: (a) merge-by-subject-ID logic that upserts
rows into existing CSVs, or (b) giving each run's outputs their own
timestamped folder, so collisions can't happen structurally. Option (b)
was chosen — it's simpler and avoids the "different bin structures have
different columns" complication that a general merge function would need
to handle. The tradeoff, made consciously: there's no single always-current
file showing every subject ever processed under a given label; getting a
combined view across multiple runs requires manually opening each run's
folder and reconciling — considered an acceptable manual cost given how
rarely it comes up in practice.

### 2.4 Making the bin-structure label optional

Most studies only ever use one bin descriptor file and have no need to
distinguish multiple passes. The `binID` field was made genuinely optional
(no longer a required, error-if-blank field), with an `append_tag()` helper
introduced so every place that conditionally appends `binID` to a filename
or string (`output_base`, `ERP.erpname`, `study_tag`, the output folder
name) does so without producing a stray leading or trailing underscore when
it's left blank.

---

## Part 3 — General lessons for future debugging on this pipeline

- **A fix that appears to work on Hampshire data is not automatically safe
  for Providence data, or vice versa.** Several of the bugs above (1.4,
  1.6) only became apparent — or only became *dangerous* — when the two
  sites' different reference schemes were compared mathematically rather
  than assumed to behave the same way. When touching anything related to
  re-referencing, channel counts, or rank, work out the relevant algebra
  for both `reref_eq_brainvision_hampshire.txt` and `reref_eq_pchpl.txt`
  before trusting a result observed on only one.
- **Coordinate/geometry bugs (`chanlocs`) and data bugs (`EEG.data`) are
  invisible to each other's diagnostics.** A debug print of `chanlocs.X`
  will never reveal a corruption of the actual voltage samples, and vice
  versa. Bug 1.4 specifically slipped through for a while for exactly this
  reason — a coordinate check looked fine while the underlying signal
  transformation was never actually being verified.
- **Don't trust EEGLAB/ERPLAB metadata fields as ground truth for what
  actually happened** — `chaninfo.removedchans` (bug 1.5) turned out to
  reflect something else entirely (channels lacking a scalp location at
  lookup time) rather than what its name suggests. When a metadata field's
  behavior matters for a downstream decision, verify it directly (e.g. via
  a before/after diff) rather than assuming it means what it appears to
  mean.
- **When a log message looks alarming (e.g. "rank deficient", "N channels
  smaller than M"), work out whether it's a symptom of a bug or an expected
  mathematical consequence of the current configuration** before treating
  it as something to fix (see 1.6). Not every unusual-looking console
  message indicates a problem.
