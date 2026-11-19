# ERP_pipeline.m — Student Guide

This script takes raw, continuous EEG recordings and turns them into averaged
ERPs (event-related potentials), ready for statistical analysis. It runs in
**MATLAB**, using **EEGLAB** (with the **ERPLAB** and **ICLabel** plug-ins).

It handles filtering, resampling, re-referencing, automated bad-channel
removal, ICA-based artifact correction, channel interpolation, bin
assignment, epoching, artifact rejection, and averaging — all in one pass,
for every subject in your subject list.

---

## 1. Before you run it

You'll need:

- **MATLAB** with **EEGLAB** installed, plus the **ERPLAB** and **ICLabel**
  plug-ins (tested with EEGLAB 2024.x and ERPLAB 10.x).
- Your raw data organized like this:

  ```
  <your project folder>/
  ├── DATA/
  │   ├── S101/
  │   │   ├── S101_LDT.set
  │   │   └── S101_LDT.fdt
  │   ├── S102/
  │   │   ├── S102_LDT.set
  │   │   └── S102_LDT.fdt
  │   └── ...
  ├── reref_eq_brainvision_hampshire.txt   (or reref_eq_pchpl.txt for Providence)
  ├── your_bin_descriptor_file.txt
  └── your_subject_list.txt
  ```

  The `.set`/`.fdt` pair for each subject must be named
  `<subjectID>_<taskID>.set` / `.fdt` and live in its own folder under
  `DATA/`.

- A **subject list file** — a plain text file with one subject ID per line
  (e.g. `S101`, `S102`, ...).
- A **bin descriptor file (BDF)** — the ERPLAB text file that defines your
  experimental conditions (bins) from event codes.
- A **re-reference formula file** — already provided for each site
  (`reref_eq_brainvision_hampshire.txt` for Hampshire College,
  `reref_eq_pchpl.txt` for Providence College). You shouldn't need to touch
  these unless you're setting up a brand-new recording site.
- The montage-specific channel-locations file (`.ced`) for your site,
  already generated and placed in EEGLAB's `sample_locs/` folder. If this is
  missing, the pipeline will stop immediately and tell you so, rather than
  running with wrong channel positions.

You do **not** need to open or edit the MATLAB code to run a normal analysis
— everything is entered through one dialog box when you launch the script.

---

## 2. Running the pipeline

Open `ERP_pipeline.m` in MATLAB and run it. A single dialog box will ask for
everything the pipeline needs:

| Field | What to enter |
|---|---|
| **StudyID** | A short name for your study (e.g. `M21`). Can be left blank. |
| **TaskID** | The task name used in your filenames (e.g. `LDT`). Leave blank if your files aren't tagged with a task name. |
| **Data collection location** | `hc` (Hampshire College montage) or `pc` (Providence College montage). |
| **Subject list file** | The filename of your subject list (see above). |
| **Bin descriptor file (BDF)** | The filename of your bin descriptor file. |
| **Bin structure label** | **Leave this blank** unless your study uses more than one BDF file for the same subjects (see [Section 5](#5-running-more-than-one-bin-structure-per-subject) below). |
| **Downsample to (Hz)** | The sampling rate to downsample to, e.g. `200`. |
| **Epoch window (ms)** | e.g. `-200 1000`. |
| **Artifact-rejection threshold (µV)** | e.g. `100`. |
| **Artifact-rejection window (ms)** | e.g. `-100 600`. |
| **EEGLAB directory** | The folder containing EEGLAB's `sample_locs/` subfolder. |

Once you click OK, the pipeline runs through every subject in your list
automatically — no further input needed. This can take a while (ICA is the
slowest step), so it's normal for a full run to take anywhere from several
minutes to over an hour per subject depending on recording length and your
computer.

---

## 3. What happens, stage by stage

Each subject goes through these steps in order. The pipeline saves an
intermediate `.set` file after most stages, so you can always go back and
inspect the data at any point using EEGLAB's GUI.

| Stage | What it does |
|---|---|
| **1 — Load** | Loads the subject's raw `.set`/`.fdt` file and checks the channel count matches what's expected for the selected site. |
| **2 — Filter / resample / reference / event list** | Band-pass filters (0.1–30 Hz), downsamples, attaches channel locations, re-references according to your site's formula file, and builds the event list. |
| **3 — Bad-channel removal** | Automatically detects and removes clearly bad channels (flatlined, too noisy, or poorly correlated with neighboring channels), evaluated on scalp channels only. |
| **4 — ICA** | Decomposes the data into independent components and automatically flags likely muscle, eye-movement, and line-noise components (using ICLabel, at a 90% confidence threshold) for removal. |
| **5 — Interpolation** | Restores any channels removed in Stage 3 by interpolating them from their neighbors, and puts every channel back in its original order. |
| **6 — Bin assignment** | Applies your bin descriptor file to label each event with its experimental condition. |
| **7 — Epoch / artifact rejection / averaging** | Cuts the continuous data into epochs, flags epochs with amplitude artifacts, and averages the clean epochs into a final ERP for each bin. |

The suffix on each saved `.set` file tells you exactly which stages it's
been through: `_FLT` (filtered) → `_RSP` (resampled) → `_REF`
(re-referenced) → `_ELS` (event list) → `_CLN` (bad channels removed) →
`_ICA` (ICA components removed) → `_INT` (interpolated) → `_BIN` (bins
assigned) → `_EPC` (epoched) → `_ARJ` (artifact-rejected).

---

## 4. The "checkpoint" system

Stages 2–5 (filtering through interpolation) don't depend on which bin
descriptor file you use — they only depend on the raw recording itself. The
pipeline takes advantage of this: after Stage 5 finishes, it saves a
**checkpoint file** (ending in `_CLN_ICA_INT.set`).

The next time you run the pipeline **on the same subject**, it looks for
that checkpoint file first. If it finds one, it loads it directly and skips
straight to bin assignment (Stage 6) — meaning it does **not** redo
filtering, cleaning, or ICA (by far the slowest step). This matters most if
your study needs more than one bin structure per subject (see below); for a
typical single-BDF study, you'll simply see the checkpoint get created once
and reused if you ever need to reprocess.

---

## 5. Running more than one bin structure per subject

Some studies need the *same* subjects binned two different ways — for
example, one pass organizing conditions by family size, another by base
frequency. If that's your situation:

1. Run the pipeline once with your first BDF file, and give it a **Bin
   structure label** (e.g. `FS`).
2. Run it again with your second BDF file, using a **different** label
   (e.g. `BF`).

Because each pass uses a different label, their output files won't overwrite
each other, and the second pass will automatically reuse the checkpoint from
the first pass rather than repeating Stages 2–5.

If you only ever use one BDF file for your study, **leave the bin structure
label blank** — there's no need to label anything, and the filenames stay
simpler.

---

## 6. Where your output files go

**Per-subject files** — every `.set` file created along the way, the final
`.erp` file, the event-list text file, and the artifact-rejection summary —
are saved inside that subject's own folder: `DATA/<subjectID>/`.

**Study-level summary files** — one set per pipeline run — are saved in a
timestamped folder so that separate runs never overwrite each other:

```
Pipeline_Logs/
└── <StudyID>_<TaskID>_<BinLabel>_<timestamp>/
    ├── <tag>_pipeline_log.txt      — detailed per-subject processing log
    ├── <tag>_removed_channels.txt  — which channels were removed, per subject
    ├── <tag>_trial_counts.csv      — accepted trial counts per condition, per subject
    ├── <tag>_ICA_log.csv           — number of ICA components removed, per subject
    └── <tag>_summary_stats.txt     — means/SD/range, ready to paste into a Methods section
```

Each run gets its own folder (named with the date and time it started), so
re-running a subset of subjects — say, to fix one problem subject — never
erases the results from previous runs. The trade-off is that if you want a
combined view across multiple runs, you'll need to open each run's folder
and manually reconcile them; the pipeline doesn't do this automatically.

---

## 7. Hampshire College vs. Providence College — what's different

The pipeline supports two montages, selected by the **Data collection
location** field:

- **Hampshire College (`hc`)**: 27 scalp channels plus 5 non-scalp channels
  (mastoids, EOG). Bad-channel detection is run on the scalp channels only,
  since it can't meaningfully evaluate channels without scalp locations.
- **Providence College (`pc`)**: 31 scalp channels, no non-scalp channels at
  all — bad-channel detection runs on the whole montage directly.

One thing **not** to assume carries over between sites: at Hampshire, ICA
will always report 2 fewer independent components than channels (e.g. 31
components from 33 channels) — this is expected, and comes from a
mathematical property of Hampshire's specific mastoid-averaging reference
formula, not a sign of a problem. Providence's reference formula doesn't
have this property, so a Providence subject should normally show full-rank
ICA output; if a Providence subject *does* show reduced rank, it likely
reflects something real about that subject's data (e.g. a bridged or flat
channel) and is worth a closer look.

---

## 8. Troubleshooting

**"Channel locations file not found" / "Re-reference file not found"** — the
pipeline checks for these before doing anything else. Make sure the
`.ced` file for your site is in EEGLAB's `sample_locs/` folder, and the
re-reference formula file is in your project's main folder.

**"channel-count mismatch"** — the raw `.set` file you're loading doesn't
have the number of channels expected for the site you selected. Double-check
you picked the right location (`hc` vs `pc`) for this subject's data.

**A subject gets skipped with "set file missing"** — the pipeline expects
`DATA/<subjectID>/<subjectID>_<taskID>.set` (and matching `.fdt`) to exist
exactly at that path. Check the subject ID in your subject list matches the
folder and filenames exactly.

**Console shows a lot of `DEBUG:` lines** — these are intentional diagnostic
prints (channel coordinates, counts, which channels were removed) left in
deliberately so problems are easy to trace. They're not errors — only lines
starting with `WARNING` or MATLAB's own `Error:` need your attention.

**A run seems to skip straight to bin assignment with no filtering/ICA
messages** — this is the checkpoint system working as intended (see
[Section 4](#4-the-checkpoint-system)). If you actually want to redo
Stages 2–5 from scratch for a subject (e.g. after changing a filter
setting), delete that subject's `..._CLN_ICA_INT.set` file from their
`DATA/<subjectID>/` folder first.

---

## 9. Getting help

If something doesn't match this guide, or you hit an error not covered
here, save the full MATLAB console output and check with your supervisor or
the person who maintains this pipeline before assuming your data is fine —
some failure modes here can be silent (i.e. no error thrown) rather than
loud, so it's worth asking rather than guessing.
