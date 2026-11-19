# ---------------------------------------------------------------------------
# N250 and N400 nonwords in one model: does the role of OS (and LP) differ
# between the two components?
# Requires: erp_fs_nw with BOTH time windows (do not filter on time_window)
# ---------------------------------------------------------------------------
library(tidyverse)
library(lmerTest)
library(emmeans)
emm_options(lmer.df = "satterthwaite", lmerTest.limit = 20000)

dat <- erp_fs_nw |>
  filter(!is.na(OS), !is.na(LP)) |>
  mutate(time_window = factor(time_window, levels = c("N250", "N400")))

# Same +/-0.5 coding as the separate models; time window coded the same way,
# so every term WITHOUT time_window is the average of the two components and
# every term WITH time_window is the N400 - N250 difference in that term.
contrasts(dat$complexity)  <- c(-0.5, 0.5)   # simple, complex
contrasts(dat$family_size) <- c(-0.5, 0.5)   # small, large
contrasts(dat$time_window) <- c(-0.5, 0.5)   # N250, N400

table(dat$time_window)            # should be 6804 each
n_distinct(dat$SubjID)            # should be 63

# Random intercepts: participant and electrode-within-participant, each allowed
# a separate baseline in each time window (the separate models had these
# implicitly, because each window was fit on its own).
re <- "(1 | SubjID) + (1 | SubjID:time_window) + (1 | SubjID:chlabel) + (1 | SubjID:chlabel:time_window)"

f_full <- as.formula(paste("value ~ complexity * family_size * LP * OS * time_window +", re))

m_tw <- lmer(f_full, data = dat, REML = TRUE,
             control = lmerControl(optimizer = "bobyqa"))
summary(m_tw)

# ---------------------------------------------------------------------------
# Omnibus tests (ML fits): remove every term that contains BOTH the
# individual-difference dimension AND time window, and compare.
# ---------------------------------------------------------------------------
fixed_terms <- attr(terms(f_full), "term.labels")
fixed_terms <- fixed_terms[!grepl("\\|", fixed_terms)]   # drop random-effect bits

has <- function(term, var) var %in% strsplit(term, ":")[[1]]

drop_window_terms <- function(var) {
  keep <- fixed_terms[!(sapply(fixed_terms, has, var = var) &
                        sapply(fixed_terms, has, var = "time_window"))]
  as.formula(paste("value ~", paste(keep, collapse = " + "), "+", re))
}

m_full_ml <- lmer(f_full, data = dat, REML = FALSE,
                  control = lmerControl(optimizer = "bobyqa"))
m_noOSxTW <- lmer(drop_window_terms("OS"), data = dat, REML = FALSE,
                  control = lmerControl(optimizer = "bobyqa"))
m_noLPxTW <- lmer(drop_window_terms("LP"), data = dat, REML = FALSE,
                  control = lmerControl(optimizer = "bobyqa"))

# Does OS's contribution differ between N250 and N400? (8 df)
anova(m_noOSxTW, m_full_ml)
# Does LP's contribution differ between N250 and N400? (8 df)
anova(m_noLPxTW, m_full_ml)

# ---------------------------------------------------------------------------
# Term-by-term: which OS (or LP) terms differ between components?
# Each "...:time_window1" row is (N400 term) - (N250 term).
# ---------------------------------------------------------------------------
cf <- as.data.frame(coef(summary(m_tw)))
cf$term <- rownames(cf)
cf |>
  filter(grepl("time_window", term), grepl("OS|LP", term)) |>
  select(term, Estimate, `Std. Error`, df, `t value`, `Pr(>|t|)`) |>
  mutate(across(where(is.numeric), ~ round(.x, 4)))

# ---------------------------------------------------------------------------
# Targeted contrasts: the same OS (or LP) slopes as before, estimated in each
# window and compared directly (N400 - N250).
# ---------------------------------------------------------------------------
lp_mean <- mean(distinct(dat, SubjID, LP)$LP)
os_mean <- mean(distinct(dat, SubjID, OS)$OS)

# OS slope of the complexity effect, within each family size, by window
emtrends(m_tw, ~ complexity | family_size * time_window, var = "OS",
         at = list(LP = lp_mean)) |>
  contrast("revpairwise")

# ... and the N400 - N250 difference in that slope
emtrends(m_tw, ~ complexity * time_window | family_size, var = "OS",
         at = list(LP = lp_mean)) |>
  contrast(interaction = "revpairwise")

# Same for LP
emtrends(m_tw, ~ complexity | family_size * time_window, var = "LP",
         at = list(OS = os_mean)) |>
  contrast("revpairwise")

emtrends(m_tw, ~ complexity * time_window | family_size, var = "LP",
         at = list(OS = os_mean)) |>
  contrast(interaction = "revpairwise")
