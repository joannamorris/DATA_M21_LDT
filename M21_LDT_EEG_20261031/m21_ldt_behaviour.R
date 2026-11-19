# =============================================================================
# m21_ldt -- behavioural analysis: accuracy, response time, and split-half
# reliability of the behavioural effects
#
# Run m21_ldt_single_trial.R first: this script uses its scored behaviour file
# (behaviour_trials.csv) and its analysed sample and PCA scores
# (nonword_trials.csv), so the same 57 participants enter every analysis.
#
#   Accuracy: valid trials (answered, or no response by the deadline = error)
#   RT:       correct answered trials, analysed as log(RT)
#   OS and LP enter as main effects (efficiency), as in the earlier RT models.
# =============================================================================

library(ggplot2)
library(lme4)
library(lmerTest)
library(emmeans)
emm_options(lmer.df = "satterthwaite", lmerTest.limit = 1e5)
set.seed(20261101)

data_dir <- "data"
in_dir   <- "single_trial_output"
out_dir  <- "behaviour_output"
dir.create(out_dir, showWarnings = FALSE)
rd <- function(d, f) read.csv(file.path(d, f), stringsAsFactors = FALSE)

beh  <- rd(in_dir, "behaviour_trials.csv")
subj <- unique(rd(in_dir, "nonword_trials.csv")[, c("SubjID","OS","LP")])
beh  <- merge(beh, subj, by = "SubjID")                 # analysed sample only
beh  <- beh[!is.na(beh$acc), ]                          # drop invalid trials
cat("Participants:", length(unique(beh$SubjID)), "\n")

# ---- Items -------------------------------------------------------------------
z <- function(v) (v - mean(v)) / sd(v)

# Nonwords: complexity follows the list (AB: 203/204 complex; BA: 205/206
# complex), except item 319, coded by the string shown (AB adoptilp = simple,
# BA adoptish = complex). Faulty items removed.
nwi <- rd(data_dir, "frq_nw.csv")
nwi$logBF <- log(nwi$BF); nwi$logFS <- log(nwi$FS)
nw <- merge(beh[beh$cond_trig %in% 203:206, ],
            nwi[, c("List","cond_trig","word_trig","ItemID","Complexity","logBF","logFS")],
            by = c("List","cond_trig","word_trig"))
nw <- nw[!(paste(nw$List, nw$cond_trig, nw$word_trig) %in%
           c("AB 203 15", "BA 204 18", "BA 204 20")), ]     # trueness, boil, ime
nw$Complexity[nw$ItemID == 319] <- ifelse(nw$List[nw$ItemID == 319] == "AB", "Simple", "Complex")
nw$cpx <- ifelse(nw$Complexity == "Complex", 0.5, -0.5)
it <- unique(nw[, c("ItemID","logBF","logFS")])
nw$zLogBF <- (nw$logBF - mean(it$logBF)) / sd(it$logBF)
nw$zLogFS <- (nw$logFS - mean(it$logFS)) / sd(it$logFS)
nw$ItemID <- factor(nw$ItemID)

# Words: properties from frq_cw.csv; DESIGN removed
cwi <- rd(data_dir, "frq_cw.csv")
cwi$logBF <- log(cwi$BF); cwi$logFS <- log(cwi$FS)
w <- merge(beh[beh$cond_trig %in% 201:202, ],
           cwi[, c("cond_trig","word_trig","target","logBF","logFS","Log10WF",
                   "WholeFormLength","BF_Split")],
           by = c("cond_trig","word_trig"), suffixes = c("", "_item"))
w <- w[w$target_item != "design", ]
w$WordID <- factor(w$cond_trig * 100 + w$word_trig)
iw <- unique(w[, c("WordID","logBF","logFS","Log10WF","WholeFormLength")])
for (v in c("logBF","logFS","Log10WF","WholeFormLength"))
  w[[paste0("z_", v)]] <- (w[[v]] - mean(iw[[v]])) / sd(iw[[v]])
w$fs <- ifelse(w$cond_trig == 202, 0.5, -0.5)
w$bf <- ifelse(w$BF_Split == "High", 0.5, -0.5)

for (x in c("nw","w")) { d <- get(x); d$SubjID <- factor(d$SubjID); assign(x, d) }
cat("Nonword items:", nlevels(nw$ItemID), " Word items:", nlevels(w$WordID), "\n")
cat("Scored trials: nonwords", nrow(nw), " words", nrow(w), "\n")

# ---- Descriptives -------------------------------------------------------------
desc <- function(d, by) {
  a  <- aggregate(acc ~ SubjID + get(by), data = d, FUN = mean); names(a)[2] <- by
  r  <- aggregate(rt ~ SubjID + get(by), data = d[d$acc, ], FUN = mean); names(r)[2] <- by
  m  <- merge(a, r)
  out <- aggregate(cbind(acc, rt) ~ get(by), data = m,
                   FUN = function(v) c(M = mean(v), SD = sd(v)))
  names(out)[1] <- by; out
}
cat("\nNonwords: accuracy (proportion) and correct RT (ms), mean of participant means:\n")
print(desc(nw, "Complexity"))
cat("\nWords by family size group (201 small, 202 large):\n")
print(desc(transform(w, FS = ifelse(fs > 0, "large", "small")), "FS"))

# ---- Model helpers ------------------------------------------------------------
fit_first_ok <- function(f_fixed, re_list, data, family = NULL) {
  for (re in re_list) {
    f <- as.formula(paste(deparse(f_fixed, width.cutoff = 500L), "+", re))
    warns <- character(0)
    m <- tryCatch(withCallingHandlers(
      if (is.null(family)) lmer(f, data = data, control = lmerControl(optimizer = "bobyqa",
                                                                      optCtrl = list(maxfun = 2e5)))
      else glmer(f, data = data, family = family,
                 control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))),
      warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }),
      error = function(e) NULL)
    if (!is.null(m) && !isSingular(m) && length(warns) == 0) {
      cat("\nRandom effects used:", re, "\n"); return(m)
    }
    cat("Dropped (singular / convergence warning):", re, "\n")
  }
  stop("No candidate converged.")
}
show <- function(m, label) {
  cat("\n\n==================== ", label, " ====================\n")
  print(VarCorr(m))
  s <- as.data.frame(coef(summary(m)))
  print(signif(s, 4))
  write.csv(cbind(term = rownames(s), s),
            file.path(out_dir, paste0(gsub("[^A-Za-z0-9]+", "_", label), ".csv")), row.names = FALSE)
}

# ---- Nonwords -----------------------------------------------------------------
nw_fixed_acc <- acc ~ cpx + zLogBF + zLogFS + OS + LP
m_nw_acc <- fit_first_ok(nw_fixed_acc,
  c("(1 + cpx | SubjID) + (1 | ItemID)", "(1 + cpx || SubjID) + (1 | ItemID)",
    "(1 | SubjID) + (1 | ItemID)"), nw, binomial)
show(m_nw_acc, "Nonwords accuracy (logistic)")
cat("\nAccuracy by complexity (probability scale):\n")
print(summary(emmeans(m_nw_acc, ~ cpx, at = list(cpx = c(-0.5, 0.5)), type = "response")))

nwc <- nw[nw$acc, ]
m_nw_rt <- fit_first_ok(log(rt) ~ cpx + zLogBF + zLogFS + OS + LP,
  c("(1 + cpx | SubjID) + (1 + cpx | ItemID)", "(1 + cpx | SubjID) + (1 | ItemID)",
    "(1 + cpx || SubjID) + (1 | ItemID)", "(1 | SubjID) + (1 | ItemID)"), nwc)
show(m_nw_rt, "Nonwords log RT (correct trials)")
cat("\nRT by complexity (ms, back-transformed):\n")
print(summary(regrid(update(emmeans(m_nw_rt, ~ cpx, at = list(cpx = c(-0.5, 0.5))), tran = "log")),
              infer = TRUE))
cat("Complex / simple RT ratio:\n")
print(summary(contrast(update(emmeans(m_nw_rt, ~ cpx, at = list(cpx = c(-0.5, 0.5))), tran = "log"),
                       "revpairwise", type = "response"), infer = TRUE))

# ---- Words --------------------------------------------------------------------
w_fixed <- ~ z_logFS + z_logBF + z_Log10WF + z_WholeFormLength + OS + LP
m_w_acc <- fit_first_ok(update(w_fixed, acc ~ .),
  c("(1 | SubjID) + (1 | WordID)"), w, binomial)
show(m_w_acc, "Words accuracy (logistic)")
wc <- w[w$acc, ]
m_w_rt <- fit_first_ok(update(w_fixed, log(rt) ~ .),
  c("(1 + z_logFS + z_logBF | SubjID) + (1 | WordID)",
    "(1 + z_logFS + z_logBF || SubjID) + (1 | WordID)",
    "(1 | SubjID) + (1 | WordID)"), wc)
show(m_w_rt, "Words log RT (correct trials)")

# ---- Split-half reliability of the behavioural effects ----------------------
# Same procedure as for the ERPs: random halves within condition, effect in
# each half, correlate across participants, Spearman-Brown; 2,000 splits.
split_half <- function(x, y, cond_var, hi, lo, n_perm = 2000) {
  subs <- unique(as.character(x$SubjID))
  idx  <- split(seq_len(nrow(x)), list(as.character(x$SubjID), x[[cond_var]]), drop = TRUE)
  r <- replicate(n_perm, {
    h <- t(sapply(subs, function(s) {
      hm <- sapply(c(hi, lo), function(cnd) {
        i <- idx[[paste(s, cnd, sep = ".")]]; i <- i[sample.int(length(i))]
        k <- floor(length(i) / 2)
        c(mean(x[[y]][i[1:k]]), mean(x[[y]][i[(k + 1):(2 * k)]]))
      })
      hm[, 1] - hm[, 2]
    }))
    rr <- cor(h[, 1], h[, 2]); 2 * rr / (1 + rr)
  })
  round(c(median = median(r), lower = unname(quantile(r, .025)),
          upper = unname(quantile(r, .975))), 3)
}
nwc$Complexity <- as.character(nwc$Complexity); nw$Complexity <- as.character(nw$Complexity)
wc$FS <- ifelse(wc$fs > 0, "large", "small"); w$FS <- ifelse(w$fs > 0, "large", "small")
nw$accn <- as.numeric(nw$acc); w$accn <- as.numeric(w$acc)
rel <- rbind(
  "Nonwords: complexity effect on RT (correct)" = split_half(nwc, "rt", "Complexity", "Complex", "Simple"),
  "Nonwords: complexity effect on accuracy"     = split_half(nw, "accn", "Complexity", "Complex", "Simple"),
  "Words: family size effect on RT (correct)"   = split_half(wc, "rt", "FS", "large", "small"),
  "Words: family size effect on accuracy"       = split_half(w, "accn", "FS", "large", "small"))
cat("\n\n==================== Split-half reliability (behaviour) ====================\n")
print(rel)
write.csv(data.frame(measure = rownames(rel), rel), file.path(out_dir, "split_half_reliability_behaviour.csv"),
          row.names = FALSE)

sink(file.path(out_dir, "sessionInfo.txt")); print(sessionInfo()); sink()
