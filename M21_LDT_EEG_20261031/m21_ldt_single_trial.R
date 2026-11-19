# =============================================================================
# m21_ldt -- build the single-trial data sets
#
# Run this first. It writes the trial-level files that the analysis scripts
# read:
#   m21_ldt_single_trial_roi.R    ROI models and ERP reliability (main results)
#   m21_ldt_single_trial_scalp.R  supplementary grid analyses
#   m21_ldt_behaviour.R           accuracy, RT and behavioural reliability
#
# Steps:
#   - read the ERPLAB single-trial measurements (N250 200-300 ms, N400
#     300-500 ms) and drop empty bins (artefact-rejected trials)
#   - score every trial from the raw OpenSesame logs; compute d' and apply all
#     participant exclusions, including d' < 0.5
#   - re-run the PCA on the analysed sample (Orthographic Sensitivity,
#     Language Proficiency)
#   - attach item properties and presented strings; drop faulty items; keep
#     correct trials
#
# Outputs (in single_trial_output/):
#   nonword_trials.csv, word_trials.csv   one row per trial x window. The
#       "value" column is the mean over the 3 x 3 grid electrodes; the ROI and
#       scalp scripts replace it with their own electrodes.
#   behaviour_trials.csv                  every scored trial from the logs
#   dprime_by_participant.csv             accuracy and d' per participant
# =============================================================================

data_dir <- "data"                                   # <- edit
out_dir  <- "single_trial_output"
dir.create(out_dir, showWarnings = FALSE)
rd <- function(f) read.csv(file.path(data_dir, f), stringsAsFactors = FALSE,
                           check.names = FALSE)

# ---- Settings ---------------------------------------------------------------
# Participant exclusions (project notes) and those without language-test data.
# Participants with d' < 0.5 on the lexical decision task are added below.
excluded <- c("S130","S132","S133","S137","S157","S140",   # age / L1 / no NW responses
              "S152","S162",                               # no PCA scores
              "S147")                                      # reported a language disability
dprime_cut <- 0.5
# 3 x 3 grid; "value" in the trial files is the mean over these sites per trial
grid_ch  <- c("F3","Fz","F4","C3","CZ","C4","P3","Pz","P4")

# =============================================================================
# Part 1. Trial-level data
# =============================================================================
read_window <- function(f, win) {
  d <- rd(f)
  d$SubjID <- sub("_LDT$", "", d$ERPset)
  d$window <- win
  d
}
erp <- rbind(read_window("M21_LDT_mea_200_300_bl_n200_0.csv", "N250"),
             read_window("M21_LDT_mea_300_500_bl_n200_0.csv", "N400"))

# Empty bins: ERPLAB writes 0.000 on every channel when a bin has no accepted
# trial (the item was artifact-rejected). Those are missing data, not zeros.
key       <- interaction(erp$SubjID, erp$binlabel, erp$window, drop = TRUE)
all_zero  <- tapply(erp$value == 0, key, all)
erp$empty <- all_zero[as.character(key)]
cat("Participant x bin x window cells that are empty (no accepted trial):",
    sum(all_zero), "of", length(all_zero), "\n")
erp <- erp[!erp$empty, ]

# Grid average per trial
erp <- erp[erp$chlabel %in% grid_ch, ]
stopifnot(all(table(erp$SubjID, erp$binlabel, erp$window)[
  table(erp$SubjID, erp$binlabel, erp$window) > 0] == length(grid_ch)))
tr <- aggregate(value ~ SubjID + list + binlabel + window, data = erp, FUN = mean)

# Decode bin labels
tr$List   <- ifelse(tr$list == "A", "AB", "BA")
tr$type   <- ifelse(grepl("^NW_", tr$binlabel), "nonword", "word")
tr$cond_trig <- as.integer(sub(".*_c(\\d+)_.*", "\\1", tr$binlabel))
tr$word_trig <- as.integer(sub(".*_w(\\d+)_.*", "\\1", tr$binlabel))
tr$ItemID <- NA_integer_
is_nw <- tr$type == "nonword"
tr$ItemID[is_nw] <- as.integer(sub(".*_item(\\d+)_.*", "\\1", tr$binlabel[is_nw]))
tr$complexity <- ifelse(grepl("_Complex_", tr$binlabel), "complex",
                 ifelse(grepl("_Simple_",  tr$binlabel), "simple", NA))

# Presented strings (stimulus files)
stim <- rbind(transform(rd("m21_stimuli_AB.csv"), List = "AB"),
              transform(rd("m21_stimuli_BA.csv"), List = "BA"))
stim$target <- tolower(stim$target)
tr <- merge(tr, stim[, c("List","cond_trig","word_trig","target")],
            by = c("List","cond_trig","word_trig"), all.x = TRUE)
stopifnot(!anyNA(tr$target))

# Item properties: log base frequency and log family size (natural logs)
nw_items <- rd("frq_nw.csv")
nw_items$logBF <- log(nw_items$BF); nw_items$logFS <- log(nw_items$FS)
nw_items <- unique(nw_items[, c("ItemID","logBF","logFS")])  # base-level, same in both lists
cw_items <- rd("frq_cw.csv")
cw_items$logBF <- log(cw_items$BF); cw_items$logFS <- log(cw_items$FS)
cw_items$logWF <- cw_items$Log10WF            # whole-word frequency (log10)
cw_items$Len   <- cw_items$WholeFormLength    # whole-word length (letters)
cw_items$WordID <- cw_items$cond_trig * 100 + cw_items$word_trig

tr$WordID <- ifelse(tr$type == "word", tr$cond_trig * 100 + tr$word_trig, NA)
nw <- merge(tr[tr$type == "nonword", ], nw_items, by = "ItemID")
# Item 319 (adopt) was presented as ADOPTISH in both lists (experiment files and
# logs), so it has no simple version; it is dropped. (Its list AB bin label
# says "Simple", following the stimulus CSV, which does not match the logs.)
nw <- nw[nw$ItemID != 319, ]
w  <- merge(tr[tr$type == "word", ],
            cw_items[, c("WordID","logBF","logFS","logWF","Len","BF_Split")], by = "WordID")
w  <- w[w$target != "design", ]           # DESIGN is not a suffixed word

# ---- Behaviour: score every trial from the raw OpenSesame logs ---------------
# Answered = "/" or "z" (capital Z counted as z) with RT > 0. No response by the
# deadline ("None") = error. Any other key (space etc., with RTs of many
# seconds, ~3 per participant) or RT = 0 = invalid, treated as missing.
beh <- rbind(rd("rt_data_hc_A.csv"), rd("rt_data_hc_B_fixed.csv"))
beh$SubjID <- beh$subject_nr; beh$List <- beh$experiment_file
beh$resp <- tolower(beh$response); beh$rt <- as.numeric(beh$response_time)
beh$status <- ifelse(beh$resp %in% c("/","z") & beh$rt > 0, "answered",
              ifelse(beh$resp == "none", "timeout", "invalid"))
beh$acc <- ifelse(beh$status == "answered", beh$resp == beh$cresp,
           ifelse(beh$status == "timeout", FALSE, NA))
beh$cond_trig <- as.integer(beh$cond_trig); beh$word_trig <- as.integer(beh$word_trig)

# d' per participant over all scored trials (words: cresp "/"), with the
# log-linear correction (+0.5 / +1) for extreme rates
dprime <- do.call(rbind, lapply(split(beh[!is.na(beh$acc), ], beh$SubjID[!is.na(beh$acc)]),
  function(b) {
    wd <- b$cresp == "/"
    h  <- (sum(b$acc[wd]) + 0.5) / (sum(wd) + 1)
    fa <- (sum(!b$acc[!wd]) + 0.5) / (sum(!wd) + 1)
    data.frame(SubjID = b$SubjID[1], accuracy = mean(b$acc), dprime = qnorm(h) - qnorm(fa))
  }))
low_d <- dprime$SubjID[dprime$dprime < dprime_cut &
                       dprime$SubjID %in% setdiff(unique(tr$SubjID), excluded)]
cat("\nExcluded for d' <", dprime_cut, ":\n")
print(dprime[dprime$SubjID %in% low_d, ], row.names = FALSE)
excluded <- c(excluded, low_d)
write.csv(beh, file.path(out_dir, "behaviour_trials.csv"), row.names = FALSE)
write.csv(dprime, file.path(out_dir, "dprime_by_participant.csv"), row.names = FALSE)

# Participants and PCA scores (re-run on the analysed sample)
keep <- setdiff(unique(tr$SubjID), excluded)
demo <- rd("demo_lang_vsl_pca_hc.csv")
demo <- demo[demo$SubjID %in% keep, c("SubjID","z_vcb","z_spl","z_art","Dim.1","Dim.2")]
stopifnot(nrow(demo) == length(keep), !anyNA(demo[, 2:4]))
pca <- prcomp(demo[, c("z_vcb","z_spl","z_art")], center = TRUE, scale. = TRUE)
sc  <- pca$x[, 1:2]
if (pca$rotation["z_vcb", 1] < 0) sc[, 1] <- -sc[, 1]   # LP loads + on vocabulary
if (pca$rotation["z_spl", 2] < 0) sc[, 2] <- -sc[, 2]   # OS loads + on spelling
demo$LP <- sc[, 1]; demo$OS <- sc[, 2]
cat("\nN participants analysed:", nrow(demo), "\n")
print(round(pca$rotation[, 1:2], 3))
cat("r(LP, Dim.1) =", round(cor(demo$LP, demo$Dim.1), 3),
    "  r(OS, Dim.2) =", round(cor(demo$OS, demo$Dim.2), 3),
    "  SD(OS) =", round(sd(demo$OS), 3), "  SD(LP) =", round(sd(demo$LP), 3), "\n")

nw <- merge(nw, demo[, c("SubjID","OS","LP")], by = "SubjID")
w  <- merge(w,  demo[, c("SubjID","OS","LP")], by = "SubjID")

# Accuracy from the raw logs: keep correct trials only, for words and nonwords.
# Trials with no valid behavioural record (invalid key, RT = 0, or missing
# from the log) are dropped.
acc_key <- function(x) paste(x$SubjID, x$List, x$cond_trig, x$word_trig)
acc_tab <- setNames(beh$acc, acc_key(beh))
nw$correct <- unname(acc_tab[acc_key(nw)])
w$correct  <- unname(acc_tab[acc_key(w)])
cat("\nERP trials with no valid behavioural record: nonwords", sum(is.na(nw$correct)),
    " words", sum(is.na(w$correct)), "\n")
nw <- nw[nw$correct %in% TRUE, ]
w  <- w[w$correct %in% TRUE, ]

# Codes: numeric +/-0.5 for 2-level factors; item predictors z-scored over items
nw$cpx <- ifelse(nw$complexity == "complex", 0.5, -0.5)
for (d in c("nw","w")) {
  x <- get(d)
  x$win <- ifelse(x$window == "N400", 0.5, -0.5)
  it <- unique(x[, c(if (d == "w") "WordID" else "ItemID", "logBF", "logFS")])
  x$zLogBF <- (x$logBF - mean(it$logBF)) / sd(it$logBF)
  x$zLogFS <- (x$logFS - mean(it$logFS)) / sd(it$logFS)
  if (d == "w") {
    itw <- unique(x[, c("WordID","logWF","Len")])
    x$zLogWF <- (x$logWF - mean(itw$logWF)) / sd(itw$logWF)
    x$zLen   <- (x$Len   - mean(itw$Len))   / sd(itw$Len)
    cat("\nCorrelations among word-level predictors (across words):\n")
    print(round(cor(unique(x[, c("WordID","logBF","logFS","logWF","Len")])[, -1]), 2))
  }
  x$SubjID <- factor(x$SubjID)
  assign(d, x)
}
nw$ItemID <- factor(nw$ItemID)
w$WordID  <- factor(w$WordID)
w$fs <- ifelse(w$cond_trig == 202, 0.5, -0.5)       # large family = +.5
w$bf <- ifelse(w$BF_Split == "High", 0.5, -0.5)     # high base frequency = +.5
w$FS_group <- ifelse(w$fs > 0, "Large", "Small")

trial_counts <- function(x, by) {
  n <- aggregate(value ~ SubjID + window + get(by), data = x, FUN = length)
  names(n)[3] <- by
  aggregate(value ~ window + get(by), data = n,
            FUN = function(v) c(mean = mean(v), min = min(v), max = max(v)))
}
cat("\nNonword trials per participant (correct, artifact-free):\n")
print(trial_counts(nw, "complexity"))
cat("\nWord trials per participant (correct, artifact-free):\n")
print(trial_counts(w, "BF_Split"))
cat("\nRows: nonwords", nrow(nw), "  words", nrow(w), "\n")
write.csv(nw, file.path(out_dir, "nonword_trials.csv"), row.names = FALSE)
write.csv(w,  file.path(out_dir, "word_trials.csv"),    row.names = FALSE)

sink(file.path(out_dir, "sessionInfo.txt")); print(sessionInfo()); sink()
