# =============================================================================
# m21_ldt -- single-trial models with scalp distribution (Laterality x
# Anteriority over the 3 x 3 grid)
#
# Run m21_ldt_single_trial.R first: this script uses its trial-level files
# (nonword_trials.csv, word_trials.csv), which already carry the exclusions,
# accuracy filter, item properties and PCA scores, and adds back the
# individual grid electrodes from the ERPLAB measurement files.
#
# Fixed effects mirror the Holcomb-lab grid analysis: the design variables are
# crossed with Laterality x Anteriority; only terms involving the design
# variables are examined (Luck & Gaspelin, 2017).
#
# Random effects:
#   participants and items crossed, as in the grid-averaged models
#   (1 | SubjID:chlabel:window)  each participant's scalp topography, per window
#   (1 | TrialID)                the nine electrodes on one trial come from one
#                                epoch; without this term they would count as
#                                nine independent observations
# =============================================================================

library(ggplot2)
library(lme4)
library(lmerTest)
library(emmeans)
emm_options(lmer.df = "satterthwaite", lmerTest.limit = 3e5)

data_dir <- "data"
in_dir   <- "single_trial_output"          # output of m21_ldt_single_trial.R
out_dir  <- "single_trial_scalp_output"
dir.create(out_dir, showWarnings = FALSE)

grid <- data.frame(
  chlabel     = c("F3","Fz","F4", "C3","CZ","C4", "P3","Pz","P4"),
  Laterality  = rep(c("Left","Midline","Right"), times = 3),
  Anteriority = rep(c("Frontal","Central","Parietal"), each = 3))

# ---- Electrode-level data ----------------------------------------------------
read_window <- function(f, win) {
  d <- read.csv(file.path(data_dir, f), stringsAsFactors = FALSE)
  d <- d[d$chlabel %in% grid$chlabel, c("ERPset","binlabel","chlabel","value")]
  d$SubjID <- sub("_LDT$", "", d$ERPset); d$window <- win
  d[, c("SubjID","binlabel","window","chlabel","value")]
}
el <- rbind(read_window("M21_LDT_mea_200_300_bl_n200_0.csv", "N250"),
            read_window("M21_LDT_mea_300_500_bl_n200_0.csv", "N400"))
el <- merge(el, grid, by = "chlabel")

prep <- function(trials_file) {
  t <- read.csv(file.path(in_dir, trials_file), stringsAsFactors = FALSE)
  t$value <- NULL                               # grid average; replaced below
  x <- merge(t, el, by = c("SubjID","binlabel","window"))   # inner join: keeps
  stopifnot(nrow(x) == 9 * nrow(t))             # only trials in the analysis
  x$TrialID <- factor(paste(x$SubjID, x$binlabel))
  x$window  <- factor(x$window)
  x$chlabel <- factor(x$chlabel)
  x$SubjID  <- factor(x$SubjID)
  x$Laterality  <- factor(x$Laterality,  levels = c("Left","Midline","Right"))
  x$Anteriority <- factor(x$Anteriority, levels = c("Frontal","Central","Parietal"))
  contrasts(x$Laterality)  <- contr.sum(3)
  contrasts(x$Anteriority) <- contr.sum(3)
  x$win <- ifelse(x$window == "N400", 0.5, -0.5)
  x
}
nw <- prep("nonword_trials.csv")
w  <- prep("word_trials.csv")

nw$cpx <- ifelse(nw$complexity == "complex", 0.5, -0.5)
nw$ItemID <- factor(nw$ItemID)
it <- unique(nw[, c("ItemID","logBF","logFS")])
nw$zLogBF <- (nw$logBF - mean(it$logBF)) / sd(it$logBF)
nw$zLogFS <- (nw$logFS - mean(it$logFS)) / sd(it$logFS)

w$WordID <- factor(w$WordID)
w$fs <- ifelse(w$cond_trig == 202, 0.5, -0.5)
w$bf <- ifelse(w$BF_Split == "High", 0.5, -0.5)
itw <- unique(w[, c("WordID","logWF","Len")])
w$zLogWF <- (w$logWF - mean(itw$logWF)) / sd(itw$logWF)
w$zLen   <- (w$Len   - mean(itw$Len))   / sd(itw$Len)
cat("Rows: nonwords", nrow(nw), " words", nrow(w), "\n")

# ---- Helpers -----------------------------------------------------------------
fit <- function(f, data) {
  t0 <- Sys.time()
  m <- lmer(f, data = data,
            control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5),
                                  calc.derivs = FALSE))
  cat("\nFitted in", round(difftime(Sys.time(), t0, units = "mins"), 1), "min;",
      "singular:", isSingular(m), "\n")
  print(VarCorr(m))
  m
}
f_table <- function(m, must) {
  a <- as.data.frame(anova(m, type = 3, ddf = "Satterthwaite"))
  a <- data.frame(term = rownames(a), df1 = a$NumDF, df2 = round(a$DenDF, 1),
                  F = round(a$`F value`, 2), p = signif(a$`Pr(>F)`, 3),
                  eta_p2 = round(a$`F value` * a$NumDF /
                                   (a$`F value` * a$NumDF + a$DenDF), 3))
  keep <- Reduce(`|`, lapply(must, function(v) grepl(paste0("(^|:)", v, "(:|$)"), a$term)))
  a[keep, ]
}
report <- function(m, must, label) {
  cat("\n\n==================== ", label, " ====================\n")
  ft <- f_table(m, must)
  print(ft, row.names = FALSE)
  write.csv(ft, file.path(out_dir, paste0(gsub("[^A-Za-z0-9]+", "_", label), "_Ftable.csv")),
            row.names = FALSE)
  sig_scalp <- ft$term[ft$p < .05 & grepl("Laterality|Anteriority", ft$term)]
  cat("\nSignificant terms involving the scalp factors:",
      if (length(sig_scalp)) paste(sig_scalp, collapse = ", ") else "none", "\n")
  invisible(ft)
}

# ---- Nonwords ----------------------------------------------------------------
# Complexity x OS x Window crossed with the grid; LP and item covariates as in
# the grid-averaged model (LP not crossed with the scalp factors).
m_nw <- fit(value ~ cpx * win * OS * Laterality * Anteriority + cpx * win * LP +
              (zLogBF + zLogFS) * win +
              (1 + win || SubjID) + (1 + cpx || ItemID) +
              (1 | SubjID:chlabel:window) + (1 | TrialID:window), nw)
ft_nw <- report(m_nw, "cpx", "Nonwords by scalp (correct trials)")

# ---- Words -------------------------------------------------------------------
# Family size x base frequency x Window crossed with the grid; word frequency,
# length, OS and LP by window (not crossed with the scalp factors).
m_w <- fit(value ~ fs * bf * win * Laterality * Anteriority +
             (zLogWF + zLen) * win + (OS + LP) * win +
             (1 + fs + bf + win || SubjID) + (1 | WordID) +
             (1 | SubjID:chlabel:window) + (1 | TrialID:window), w)
ft_w <- report(m_w, c("fs","bf"), "Words by scalp (correct trials)")

# ---- Follow-ups for significant scalp interactions ---------------------------
# For each significant term involving a design variable and a scalp factor,
# show the design effect at each level of the scalp factor(s) in that term,
# separately by window if Window is in the term.
follow <- function(m, term, effect) {
  parts <- strsplit(term, ":")[[1]]
  by <- intersect(c("Laterality","Anteriority"), parts)
  at <- setNames(list(c(-0.5, 0.5)), effect)
  if ("win" %in% parts) { by <- c(by, "win"); at$win <- c(-0.5, 0.5) }
  cat("\n--- Follow-up:", term, "---\n")
  print(summary(contrast(emmeans(m, c(effect, by), at = at), "revpairwise", by = by),
                infer = TRUE))
}
for (t in ft_nw$term[ft_nw$p < .05 & grepl("Laterality|Anteriority", ft_nw$term)])
  follow(m_nw, t, "cpx")
for (t in ft_w$term[ft_w$p < .05 & grepl("Laterality|Anteriority", ft_w$term)])
  follow(m_w, t, if (grepl("(^|:)fs(:|$)", t)) "fs" else "bf")

sink(file.path(out_dir, "sessionInfo.txt")); print(sessionInfo()); sink()
