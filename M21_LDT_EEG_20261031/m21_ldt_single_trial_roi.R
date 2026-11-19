# =============================================================================
# m21_ldt -- single-trial ROI models for words
#
# Hypotheses:
#   N250: Orthographic Sensitivity (OS) modulates the base frequency effect
#   N400: Language Proficiency (LP) modulates the family size effect
#
# ROI: C3, Cz, C4, CP1, CP2, CP5, CP6, P3, Pz, P4 (all C, CP and P sites
# except P7 and P8), averaged per trial.
#
# Run m21_ldt_single_trial.R first: this script uses its word_trials.csv
# (exclusions, item properties, PCA scores) and replaces the grid-averaged
# amplitude with the ROI average from the ERPLAB measurement files.
#
# Primary coding: family size and base frequency as continuous item measures
# (log, z-scored over words). Sensitivity: the small/large and low/high groups
# the words were selected in.
# =============================================================================

library(ggplot2)
library(lme4)
library(lmerTest)
library(emmeans)
emm_options(lmer.df = "satterthwaite", lmerTest.limit = 1e5)

data_dir <- "data"
in_dir   <- "single_trial_output"
out_dir  <- "single_trial_roi_output"
dir.create(out_dir, showWarnings = FALSE)

roi <- c("C3","CZ","C4","CP1","CP2","CP5","CP6","P3","Pz","P4")

# ---- ROI amplitude per trial --------------------------------------------------
read_window <- function(f, win) {
  d <- read.csv(file.path(data_dir, f), stringsAsFactors = FALSE)
  d <- d[d$chlabel %in% roi, ]
  stopifnot(setequal(unique(d$chlabel), roi))
  d$SubjID <- sub("_LDT$", "", d$ERPset); d$window <- win
  aggregate(value ~ SubjID + binlabel + window, data = d, FUN = mean)
}
amp <- rbind(read_window("M21_LDT_mea_200_300_bl_n200_0.csv", "N250"),
             read_window("M21_LDT_mea_300_500_bl_n200_0.csv", "N400"))

w <- read.csv(file.path(in_dir, "word_trials.csv"), stringsAsFactors = FALSE)
n_trials <- nrow(w)
w$value <- NULL
w <- merge(w, amp, by = c("SubjID","binlabel","window"))   # empty bins already dropped
stopifnot(nrow(w) == n_trials)

it <- unique(w[, c("WordID","logBF","logFS","logWF","Len")])
z  <- function(v, iv) (v - mean(iv)) / sd(iv)
w$zLogBF <- z(w$logBF, it$logBF); w$zLogFS <- z(w$logFS, it$logFS)
w$zLogWF <- z(w$logWF, it$logWF); w$zLen   <- z(w$Len,   it$Len)
w$fs <- ifelse(w$cond_trig == 202, 0.5, -0.5)          # large family = +.5
w$bf <- ifelse(w$BF_Split == "High", 0.5, -0.5)        # high base frequency = +.5
w$SubjID <- factor(w$SubjID); w$WordID <- factor(w$WordID)

subj <- unique(w[, c("SubjID","OS","LP")])
sd_OS <- sd(subj$OS); sd_LP <- sd(subj$LP)
cat("Participants:", nrow(subj), " Words:", nrow(it), " Trials per window:",
    paste(table(w$window), collapse = " / "), "\n")
cat("SD(OS) =", round(sd_OS, 3), " SD(LP) =", round(sd_LP, 3), "\n")

# ---- Helpers -------------------------------------------------------------------
fit_first_ok <- function(fixed, re_list, data) {
  for (re in re_list) {
    f <- as.formula(paste(deparse(fixed, width.cutoff = 500L), "+", re))
    warns <- character(0)
    m <- tryCatch(withCallingHandlers(
           lmer(f, data = data, control = lmerControl(optimizer = "bobyqa",
                                                      optCtrl = list(maxfun = 2e5))),
           warning = function(w) { warns <<- c(warns, conditionMessage(w))
                                   invokeRestart("muffleWarning") }),
         error = function(e) NULL)
    if (!is.null(m) && !isSingular(m) && length(warns) == 0) {
      cat("\nRandom effects used:", re, "\n"); return(m)
    }
    cat("Dropped (singular / convergence warning):", re, "\n")
  }
  stop("No candidate converged.")
}
coef_table <- function(m) {
  s <- as.data.frame(coef(summary(m)))
  data.frame(term = rownames(s), estimate = round(s$Estimate, 3), SE = round(s$`Std. Error`, 3),
             df = round(s$df, 1), t = round(s$`t value`, 2), p = signif(s$`Pr(>|t|)`, 3))
}
# Effect of the item variable at the moderator's mean and +/- 1 SD
simple_slopes <- function(m, item_var, mod, mod_sd, numeric_item = TRUE) {
  at <- setNames(list(c(-mod_sd, 0, mod_sd)), mod)
  if (numeric_item) {
    s <- emtrends(m, specs = mod, var = item_var, at = at)
  } else {
    at[[item_var]] <- c(-0.5, 0.5)
    s <- contrast(emmeans(m, specs = c(item_var, mod), at = at), "revpairwise", by = mod)
  }
  summary(s, infer = TRUE)
}
run <- function(label, data, fixed, re_list, item_var, mod, mod_sd, numeric_item) {
  cat("\n\n==================== ", label, " ====================\n")
  m <- fit_first_ok(fixed, re_list, data)
  print(VarCorr(m))
  ct <- coef_table(m)
  print(ct, row.names = FALSE)
  write.csv(ct, file.path(out_dir, paste0(gsub("[^A-Za-z0-9]+", "_", label), "_coefs.csv")),
            row.names = FALSE)
  cat("\nEffect of", item_var, "at", mod, "= -1 SD, mean, +1 SD:\n")
  print(simple_slopes(m, item_var, mod, mod_sd, numeric_item))
  invisible(m)
}

n250 <- droplevels(w[w$window == "N250", ])
n400 <- droplevels(w[w$window == "N400", ])

# ---- N250: base frequency x OS ------------------------------------------------
re_n250 <- function(v) c(sprintf("(1 + %s | SubjID) + (1 + OS | WordID)", v),
                         sprintf("(1 + %s | SubjID) + (1 | WordID)", v),
                         sprintf("(1 + %s || SubjID) + (1 | WordID)", v),
                         "(1 | SubjID) + (1 | WordID)",
                         # word variance can be ~0 in this ROI: drop that term
                         sprintf("(1 + %s | SubjID)", v),
                         sprintf("(1 + %s || SubjID)", v),
                         "(1 | SubjID)")
m_n250 <- run("N250 base frequency x OS (continuous)", n250,
              value ~ zLogBF * OS + LP + zLogFS + zLogWF + zLen,
              re_n250("zLogBF"), "zLogBF", "OS", sd_OS, TRUE)
m_n250g <- run("N250 base frequency x OS (high vs low groups)", n250,
               value ~ bf * OS + LP + fs + zLogWF + zLen,
               re_n250("bf"), "bf", "OS", sd_OS, FALSE)

# ---- N400: family size x LP ---------------------------------------------------
re_n400 <- function(v) c(sprintf("(1 + %s | SubjID) + (1 + LP | WordID)", v),
                         sprintf("(1 + %s | SubjID) + (1 | WordID)", v),
                         sprintf("(1 + %s || SubjID) + (1 | WordID)", v),
                         "(1 | SubjID) + (1 | WordID)",
                         # word variance can be ~0 in this ROI: drop that term
                         sprintf("(1 + %s | SubjID)", v),
                         sprintf("(1 + %s || SubjID)", v),
                         "(1 | SubjID)")
m_n400 <- run("N400 family size x LP (continuous)", n400,
              value ~ zLogFS * LP + OS + zLogBF + zLogWF + zLen,
              re_n400("zLogFS"), "zLogFS", "LP", sd_LP, TRUE)
m_n400g <- run("N400 family size x LP (small vs large groups)", n400,
               value ~ fs * LP + OS + bf + zLogWF + zLen,
               re_n400("fs"), "fs", "LP", sd_LP, FALSE)

# =============================================================================
# Nonwords in the same ROI: Complexity x Window x (OS + LP)
# Hypothesis: OS modulates the complexity effect more at the N250 than the N400
# (the Complexity x OS x Window term). Item log BF and log FS (z) by window.
# =============================================================================
nw <- read.csv(file.path(in_dir, "nonword_trials.csv"), stringsAsFactors = FALSE)
n_nw <- nrow(nw); nw$value <- NULL
nw <- merge(nw, amp, by = c("SubjID","binlabel","window"))
stopifnot(nrow(nw) == n_nw)
itn <- unique(nw[, c("ItemID","logBF","logFS")])
nw$zLogBF <- z(nw$logBF, itn$logBF); nw$zLogFS <- z(nw$logFS, itn$logFS)
nw$cpx <- ifelse(nw$complexity == "complex", 0.5, -0.5)
nw$win <- ifelse(nw$window == "N400", 0.5, -0.5)
nw$SubjID <- factor(nw$SubjID); nw$ItemID <- factor(nw$ItemID)
cat("\n\nNonwords: participants", nlevels(nw$SubjID), " items", nlevels(nw$ItemID),
    " trials per window", paste(table(nw$window), collapse = " / "), "\n")

cat("\n\n==================== Nonwords: complexity x OS x window (ROI) ====================\n")
m_nw <- fit_first_ok(value ~ cpx * win * (OS + LP) + (zLogBF + zLogFS) * win,
  c("(1 + cpx * win | SubjID) + (1 + cpx * win | ItemID)",
    "(1 + cpx * win || SubjID) + (1 + cpx + win || ItemID)",
    "(1 + cpx + win || SubjID) + (1 + cpx || ItemID)",
    "(1 + win || SubjID) + (1 + cpx || ItemID)",
    "(1 + win || SubjID) + (1 | ItemID)",
    "(1 | SubjID) + (1 | ItemID)"), nw)
print(VarCorr(m_nw))
ct <- coef_table(m_nw); print(ct, row.names = FALSE)
write.csv(ct, file.path(out_dir, "Nonwords_complexity_OS_window_coefs.csv"), row.names = FALSE)
at2 <- list(cpx = c(-0.5, 0.5), win = c(-0.5, 0.5))
cat("\nComplexity effect (complex - simple) by window, at mean OS and LP:\n")
print(summary(contrast(emmeans(m_nw, ~ cpx | win, at = at2), "revpairwise"), infer = TRUE))
for (mod in c("OS","LP")) {
  cat("\nComplexity x", mod, "by window (change in complexity effect per unit", mod, "):\n")
  print(summary(contrast(emtrends(m_nw, ~ cpx | win, var = mod, at = at2),
                         "revpairwise", by = "win"), infer = TRUE))
}

# =============================================================================
# Split-half reliability in the ROI (permutation, Spearman-Brown corrected)
# =============================================================================
set.seed(20261101)
split_half <- function(x, cond_var, hi, lo, measure = "effect", n_perm = 2000) {
  subs <- unique(as.character(x$SubjID))
  idx  <- split(seq_len(nrow(x)), list(as.character(x$SubjID), x[[cond_var]]), drop = TRUE)
  r <- replicate(n_perm, {
    h <- t(sapply(subs, function(s) {
      hm <- sapply(c(hi, lo), function(cnd) {
        i <- idx[[paste(s, cnd, sep = ".")]]; i <- i[sample.int(length(i))]
        k <- floor(length(i) / 2)
        c(mean(x$value[i[1:k]]), mean(x$value[i[(k + 1):(2 * k)]]))
      })
      if (measure == "effect") hm[, 1] - hm[, 2] else rowMeans(hm)
    }))
    rr <- cor(h[, 1], h[, 2]); 2 * rr / (1 + rr)
  })
  round(c(median = median(r), lower = unname(quantile(r, .025)),
          upper = unname(quantile(r, .975))), 3)
}
w$FS_group <- ifelse(w$fs > 0, "Large", "Small")
rel <- list()
for (win in c("N400","N250")) {
  xn <- nw[nw$window == win, ]; xw <- w[w$window == win, ]
  rel[[paste("Nonwords", win, "mean amplitude")]]     <- split_half(xn, "complexity", "complex", "simple", "mean")
  rel[[paste("Nonwords", win, "complexity effect")]]  <- split_half(xn, "complexity", "complex", "simple")
  rel[[paste("Words", win, "mean amplitude")]]        <- split_half(xw, "FS_group", "Large", "Small", "mean")
  rel[[paste("Words", win, "family-size effect")]]    <- split_half(xw, "FS_group", "Large", "Small")
  rel[[paste("Words", win, "base-frequency effect")]] <- split_half(xw, "BF_Split", "High", "Low")
}
rel <- data.frame(measure = names(rel), do.call(rbind, rel))
cat("\n\n==================== Split-half reliability (ROI) ====================\n")
print(rel, row.names = FALSE)
write.csv(rel, file.path(out_dir, "split_half_reliability_ROI.csv"), row.names = FALSE)

sink(file.path(out_dir, "sessionInfo.txt")); print(sessionInfo()); sink()
