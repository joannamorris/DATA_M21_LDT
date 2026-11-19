# =============================================================================
# m21_ldt -- figures for the refit nonword analyses (PCA rerun on N = 62)
# Sources the refit script (which fits m_n250, m_n400, m_tw and defines
# erp, lp_vals, os_vals), then draws and saves the manuscript figures.
# =============================================================================
source("m21_ldt_refit_option1.R")
library(tidyverse)
library(emmeans)
emm_options(lmer.df = "satterthwaite", lmerTest.limit = 20000)

fix_ci <- function(df) {
  names(df)[names(df) == "asymp.LCL"] <- "lower.CL"
  names(df)[names(df) == "asymp.UCL"] <- "upper.CL"
  df
}
lp_lab <- c("Low LP (-1 SD)", "Mean LP", "High LP (+1 SD)")
os_lab <- c("Low OS (-1 SD)", "Mean OS", "High OS (+1 SD)")
cols   <- c(Simple = "#1b6ca8", Complex = "#d1495b")
subj   <- erp |> distinct(SubjID, OS, LP)

# ---- Complexity effect by family size over the LP x OS grid (one per window) --
grid_plot <- function(m, comp) {
  cx <- emmeans(m, ~ complexity | family_size * LP * OS,
                at = list(LP = lp_vals, OS = os_vals), nesting = NULL) |>
    contrast("revpairwise") |> summary(infer = TRUE) |> as.data.frame() |> fix_ci() |>
    mutate(LP_level = factor(LP, levels = lp_vals, labels = lp_lab),
           OS_level = factor(OS, levels = os_vals, labels = os_lab),
           family_size = factor(family_size, levels = c("small", "large"),
                                labels = c("Small", "Large")))
  ggplot(cx, aes(family_size, estimate, group = 1)) +
    geom_hline(yintercept = 0, linewidth = 0.4, colour = "grey50") +
    geom_line(linewidth = 0.8, colour = "grey30") +
    geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.1, colour = "grey30") +
    geom_point(size = 2.4, colour = "grey15") +
    facet_grid(LP_level ~ OS_level) +
    labs(x = "Family size",
         y = bquote("Complexity effect, Complex" - "Simple (" * mu * "V), " * .(comp))) +
    theme_bw(base_size = 10) + theme(panel.grid.minor = element_blank())
}
ggsave("N250_4way_cxeffect.png", grid_plot(m_n250, "N250"), width = 7, height = 6.5, dpi = 300)
ggsave("N400_4way_cxeffect.png", grid_plot(m_n400, "N400"), width = 7, height = 6.5, dpi = 300)

# ---- N400 cell means across LP (OS at mean) -----------------------------------
cells <- emmeans(m_n400, ~ complexity * family_size | LP,
                 at = list(LP = lp_vals, OS = os_vals[2])) |>
  as.data.frame() |> fix_ci() |>
  mutate(LP_level = factor(LP, levels = lp_vals, labels = lp_lab),
         family_size = factor(family_size, levels = c("small", "large"), labels = c("Small", "Large")),
         complexity  = factor(complexity, levels = c("simple", "complex"), labels = c("Simple", "Complex")))
pd <- position_dodge(width = 0.25)
p_cells <- ggplot(cells, aes(family_size, emmean, colour = complexity, linetype = complexity, group = complexity)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey60") +
  geom_line(position = pd, linewidth = 0.8) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.12, position = pd,
                linewidth = 0.5, linetype = "solid") +
  geom_point(position = pd, size = 2.5) +
  facet_wrap(~ LP_level) +
  scale_colour_manual(values = cols) +
  scale_linetype_manual(values = c(Simple = "dashed", Complex = "solid")) +
  labs(x = "Family size", y = expression("Predicted N400 amplitude (" * mu * "V)"),
       colour = "Complexity", linetype = "Complexity") +
  theme_bw(base_size = 11) + theme(panel.grid.minor = element_blank(), legend.position = "bottom")
ggsave("Figure_N400_CxFSxLP_cells.png", p_cells, width = 7.5, height = 3.6, dpi = 300)

# ---- Combined model: effects that differ between windows ----------------------
os_grid <- seq(min(subj$OS), max(subj$OS), length.out = 30)
lp_grid <- seq(min(subj$LP), max(subj$LP), length.out = 30)
tw_cols <- c(N250 = "#1b9e77", N400 = "#7570b3")
tw_lty  <- c(N250 = "solid",   N400 = "dashed")
effect_plot <- function(df, xvar, xlab, ylab) {
  ggplot(df, aes(.data[[xvar]], estimate, colour = time_window, fill = time_window,
                 linetype = time_window)) +
    geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey50") +
    geom_ribbon(aes(ymin = lower.CL, ymax = upper.CL), alpha = 0.15, colour = NA) +
    geom_line(linewidth = 0.9) +
    geom_rug(data = subj, aes(x = .data[[xvar]]), inherit.aes = FALSE,
             sides = "b", alpha = 0.5, length = unit(0.02, "npc")) +
    scale_colour_manual(values = tw_cols) + scale_fill_manual(values = tw_cols) +
    scale_linetype_manual(values = tw_lty) +
    labs(x = xlab, y = ylab, colour = "Window", fill = "Window", linetype = "Window") +
    theme_bw(base_size = 10) + theme(panel.grid.minor = element_blank(), legend.position = "bottom")
}
dA <- emmeans(m_tw, ~ complexity | OS * family_size * time_window,
              at = list(OS = os_grid, LP = lp_vals[2]), nesting = NULL) |>
  contrast("revpairwise") |> summary(infer = TRUE) |> as.data.frame() |> fix_ci() |>
  mutate(family_size = factor(family_size, levels = c("small", "large"),
                              labels = c("Small family", "Large family")))
pA <- effect_plot(dA, "OS", "Orthographic Sensitivity (PCA score)",
                  expression("Complexity effect, Complex-Simple (" * mu * "V)")) +
  facet_wrap(~ family_size) + ggtitle("A")
dB <- emmeans(m_tw, ~ complexity | LP * time_window,
              at = list(LP = lp_grid, OS = os_vals[2]), nesting = NULL) |>
  contrast("revpairwise") |> summary(infer = TRUE) |> as.data.frame() |> fix_ci()
pB <- effect_plot(dB, "LP", "Language Proficiency (PCA score)",
                  expression("Complexity effect, Complex-Simple (" * mu * "V)")) + ggtitle("B")
dC <- emmeans(m_tw, ~ family_size | LP * time_window,
              at = list(LP = lp_grid, OS = os_vals[2]), nesting = NULL) |>
  contrast("revpairwise") |> summary(infer = TRUE) |> as.data.frame() |> fix_ci()
pC <- effect_plot(dC, "LP", "Language Proficiency (PCA score)",
                  expression("Family size effect, Large-Small (" * mu * "V)")) + ggtitle("C")
ggsave("Window_A_CxFSxOS.png", pA, width = 8,   height = 4, dpi = 300)
ggsave("Window_B_CxLP.png",    pB, width = 4.5, height = 4, dpi = 300)
ggsave("Window_C_FSxLP.png",   pC, width = 4.5, height = 4, dpi = 300)
