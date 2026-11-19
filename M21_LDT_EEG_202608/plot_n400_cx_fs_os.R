# ---------------------------------------------------------------------------
# N400 nonwords: Complexity x Family Size x OS
# Requires: m_full_nw_n400_fs (REML fit) and erp_fs_nw from your Rmd
# ---------------------------------------------------------------------------
library(tidyverse)
library(emmeans)
emm_options(lmer.df = "satterthwaite", lmerTest.limit = 20000)

# Participant-level OS scores (one row per participant, not per observation)
subj   <- erp_fs_nw |> distinct(SubjID, OS) |> filter(!is.na(OS))
os_m   <- mean(subj$OS)
os_sd  <- sd(subj$OS)
os_pts <- c(os_m - os_sd, os_m, os_m + os_sd)

# Some emmeans settings name the CI columns asymp.LCL / asymp.UCL; standardise them
fix_ci <- function(df) {
  names(df)[names(df) == "asymp.LCL"] <- "lower.CL"
  names(df)[names(df) == "asymp.UCL"] <- "upper.CL"
  df
}

# ---- Plot A: cell means at OS = -1 SD, mean, +1 SD ------------------------
emm_A <- emmeans(m_full_nw_n400_fs, ~ complexity * family_size | OS,
                 at = list(OS = os_pts)) |>
  as.data.frame() |>
  fix_ci() |>
  mutate(OS_level = factor(OS, levels = os_pts,
                           labels = c("OS -1 SD", "OS mean", "OS +1 SD")),
         family_size = factor(family_size, levels = c("small", "large"),
                              labels = c("Small", "Large")),
         complexity  = factor(complexity, levels = c("simple", "complex"),
                              labels = c("Simple", "Complex")))

pd <- position_dodge(width = 0.25)

p_A <- ggplot(emm_A, aes(x = family_size, y = emmean,
                         colour = complexity, group = complexity)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey60") +
  geom_line(position = pd, linewidth = 0.8) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL),
                width = 0.12, position = pd, linewidth = 0.5) +
  geom_point(position = pd, size = 2.5) +
  facet_wrap(~ OS_level) +
  scale_colour_manual(values = c(Simple = "#1b6ca8", Complex = "#d1495b")) +
  labs(x = "Family size", y = expression("Predicted N400 amplitude (" * mu * "V)"),
       colour = "Complexity") +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")
# Add scale_y_reverse() if you want negative plotted up.

p_A

# ---- Plot B: family size effect (Large - Small) across the observed OS range --
os_grid <- seq(min(subj$OS), max(subj$OS), length.out = 40)

emm_B <- emmeans(m_full_nw_n400_fs, ~ family_size | complexity * OS,
                 at = list(OS = os_grid)) |>
  contrast("revpairwise") |>          # large - small
  confint() |>
  as.data.frame() |>
  fix_ci() |>
  mutate(complexity = factor(complexity, levels = c("simple", "complex"),
                             labels = c("Simple", "Complex")))

p_B <- ggplot(emm_B, aes(x = OS, y = estimate,
                         colour = complexity, fill = complexity)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey50") +
  geom_vline(xintercept = os_pts, linetype = "dotted", colour = "grey60") +
  geom_ribbon(aes(ymin = lower.CL, ymax = upper.CL), alpha = 0.18, colour = NA) +
  geom_line(linewidth = 0.9) +
  geom_rug(data = subj, aes(x = OS), inherit.aes = FALSE,
           sides = "b", alpha = 0.5, length = unit(0.02, "npc")) +
  scale_colour_manual(values = c(Simple = "#1b6ca8", Complex = "#d1495b")) +
  scale_fill_manual(values   = c(Simple = "#1b6ca8", Complex = "#d1495b")) +
  labs(x = "Orthographic Sensitivity (PCA score)",
       y = expression("Family size effect, Large-Small (" * mu * "V)"),
       colour = "Complexity", fill = "Complexity") +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_B

# ---- Save -------------------------------------------------------------------
ggsave("Figure_N400_CxFSxOS_cells.png", p_A, width = 7.5, height = 3.6, dpi = 300)
ggsave("Figure_N400_CxFSxOS_FSeffect.png", p_B, width = 5.5, height = 4, dpi = 300)
