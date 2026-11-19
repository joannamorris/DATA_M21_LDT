# ---------------------------------------------------------------------------
# Combined N250 + N400 model: the three interactions with time window
#   A. Complexity x Family Size x OS x window
#   B. Complexity x LP x window          (averaged over family size)
#   C. Family Size x LP x window         (averaged over complexity)
# In every panel: colour = time window, x = skill score, y = an effect.
# Where the two coloured lines have different slopes, that effect changes
# between the N250 and the N400.
# Requires: m_tw (REML fit from combined_window_model.R) and dat
# ---------------------------------------------------------------------------
library(tidyverse)
library(emmeans)
library(patchwork)
emm_options(lmer.df = "satterthwaite", lmerTest.limit = 20000)

fix_ci <- function(df) {
  names(df)[names(df) == "asymp.LCL"] <- "lower.CL"
  names(df)[names(df) == "asymp.UCL"] <- "upper.CL"
  df
}

subj    <- dat |> distinct(SubjID, OS, LP)
os_mean <- mean(subj$OS); lp_mean <- mean(subj$LP)
os_grid <- seq(min(subj$OS), max(subj$OS), length.out = 30)
lp_grid <- seq(min(subj$LP), max(subj$LP), length.out = 30)

tw_cols <- c(N250 = "#1b9e77", N400 = "#7570b3")
tw_lty  <- c(N250 = "solid",   N400 = "dashed")

effect_plot <- function(df, xvar, xlab, ylab, rug_var) {
  ggplot(df, aes(.data[[xvar]], estimate, colour = time_window, fill = time_window,
                 linetype = time_window)) +
    geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey50") +
    geom_ribbon(aes(ymin = lower.CL, ymax = upper.CL), alpha = 0.15, colour = NA) +
    geom_line(linewidth = 0.9) +
    geom_rug(data = subj, aes(x = .data[[rug_var]]), inherit.aes = FALSE,
             sides = "b", alpha = 0.5, length = unit(0.02, "npc")) +
    scale_colour_manual(values = tw_cols) +
    scale_fill_manual(values = tw_cols) +
    scale_linetype_manual(values = tw_lty) +
    labs(x = xlab, y = ylab, colour = "Window", fill = "Window", linetype = "Window") +
    theme_bw(base_size = 10) +
    theme(panel.grid.minor = element_blank(), legend.position = "bottom")
}

# ---- A. Complexity effect across OS, by family size and window --------------
dA <- emmeans(m_tw, ~ complexity | OS * family_size * time_window,
              at = list(OS = os_grid, LP = lp_mean), nesting = NULL) |>
  contrast("revpairwise") |>                       # complex - simple
  summary(infer = TRUE) |> as.data.frame() |> fix_ci() |>
  mutate(family_size = factor(family_size, levels = c("small", "large"),
                              labels = c("Small family", "Large family")))

pA <- effect_plot(dA, "OS", "Orthographic Sensitivity (PCA score)",
                  expression("Complexity effect, Complex-Simple (" * mu * "V)"), "OS") +
  facet_wrap(~ family_size) +
  ggtitle("A. Complexity x Family Size x OS x window")

# ---- B. Complexity effect across LP, by window (averaged over family size) --
dB <- emmeans(m_tw, ~ complexity | LP * time_window,
              at = list(LP = lp_grid, OS = os_mean), nesting = NULL) |>
  contrast("revpairwise") |>
  summary(infer = TRUE) |> as.data.frame() |> fix_ci()

pB <- effect_plot(dB, "LP", "Language Proficiency (PCA score)",
                  expression("Complexity effect, Complex-Simple (" * mu * "V)"), "LP") +
  ggtitle("B. Complexity x LP x window")

# ---- C. Family size effect across LP, by window (averaged over complexity) --
dC <- emmeans(m_tw, ~ family_size | LP * time_window,
              at = list(LP = lp_grid, OS = os_mean), nesting = NULL) |>
  contrast("revpairwise") |>                       # large - small
  summary(infer = TRUE) |> as.data.frame() |> fix_ci()

pC <- effect_plot(dC, "LP", "Language Proficiency (PCA score)",
                  expression("Family size effect, Large-Small (" * mu * "V)"), "LP") +
  ggtitle("C. Family Size x LP x window")

# ---- Show and save ------------------------------------------------------------
pA; pB; pC

combined <- pA / (pB | pC) + plot_layout(guides = "collect") &
  theme(legend.position = "bottom")
combined

ggsave("Window_A_CxFSxOS.png", pA, width = 8,   height = 4,   dpi = 300)
ggsave("Window_B_CxLP.png",    pB, width = 4.5, height = 4,   dpi = 300)
ggsave("Window_C_FSxLP.png",   pC, width = 4.5, height = 4,   dpi = 300)
ggsave("Window_all.png",  combined, width = 8.5, height = 8,  dpi = 300)
