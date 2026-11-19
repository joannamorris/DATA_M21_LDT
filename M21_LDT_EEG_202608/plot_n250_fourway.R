# ---------------------------------------------------------------------------
# N250 nonwords: Complexity x Family Size x LP x OS
# Requires: m_full_nw_n250_fs (REML fit), erp_fs_nw, lp_vals, os_vals
# ---------------------------------------------------------------------------
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

# ---- Plot 1: cell means in a 3 x 3 grid (rows = LP, columns = OS) ----------
cells <- emmeans(m_full_nw_n250_fs, ~ complexity * family_size | LP * OS,
                 at = list(LP = lp_vals, OS = os_vals), nesting = NULL) |>
  as.data.frame() |> fix_ci() |>
  mutate(LP_level = factor(LP, levels = lp_vals, labels = lp_lab),
         OS_level = factor(OS, levels = os_vals, labels = os_lab),
         family_size = factor(family_size, levels = c("small", "large"),
                              labels = c("Small", "Large")),
         complexity  = factor(complexity, levels = c("simple", "complex"),
                              labels = c("Simple", "Complex")))

pd <- position_dodge(width = 0.25)
p1 <- ggplot(cells, aes(family_size, emmean, colour = complexity, group = complexity)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey60") +
  geom_line(position = pd, linewidth = 0.8) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.12,
                position = pd, linewidth = 0.4) +
  geom_point(position = pd, size = 2.2) +
  facet_grid(LP_level ~ OS_level) +
  scale_colour_manual(values = cols) +
  labs(x = "Family size", y = expression("Predicted N250 amplitude (" * mu * "V)"),
       colour = "Complexity") +
  theme_bw(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")
p1

# ---- Plot 2: complexity effect (Complex - Simple) by family size, same grid --
#      A flat line = no Complexity x Family Size interaction in that panel;
#      a steep line = a strong interaction.
cx <- emmeans(m_full_nw_n250_fs, ~ complexity | family_size * LP * OS,
              at = list(LP = lp_vals, OS = os_vals), nesting = NULL) |>
  contrast("revpairwise") |>
  summary(infer = TRUE) |>
  as.data.frame() |> fix_ci() |>
  mutate(LP_level = factor(LP, levels = lp_vals, labels = lp_lab),
         OS_level = factor(OS, levels = os_vals, labels = os_lab),
         family_size = factor(family_size, levels = c("small", "large"),
                              labels = c("Small", "Large")))

p2 <- ggplot(cx, aes(family_size, estimate, group = 1)) +
  geom_hline(yintercept = 0, linewidth = 0.4, colour = "grey50") +
  geom_line(linewidth = 0.8, colour = "grey30") +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.1, colour = "grey30") +
  geom_point(size = 2.4, colour = "grey15") +
  facet_grid(LP_level ~ OS_level) +
  labs(x = "Family size",
       y = expression("Complexity effect, Complex-Simple (" * mu * "V)")) +
  theme_bw(base_size = 10) +
  theme(panel.grid.minor = element_blank())
p2

# ---- Plot 3: the interaction contrast as a continuous surface ---------------
#      Colour = Complexity x Family Size interaction contrast
#      ((Complex-Simple for large) - (Complex-Simple for small)).
#      Black contour = |t| = 1.96; points = participants.
subj <- erp_fs_nw |> distinct(SubjID, OS, LP) |> filter(!is.na(OS), !is.na(LP))
grid_lp <- seq(min(subj$LP), max(subj$LP), length.out = 40)
grid_os <- seq(min(subj$OS), max(subj$OS), length.out = 40)

surf <- emmeans(m_full_nw_n250_fs, ~ complexity * family_size | LP * OS,
                at = list(LP = grid_lp, OS = grid_os), nesting = NULL) |>
  contrast(interaction = "revpairwise") |>
  as.data.frame()
surf$t <- surf$estimate / surf$SE

lim <- max(abs(surf$estimate))
p3 <- ggplot(surf, aes(OS, LP)) +
  geom_raster(aes(fill = estimate), interpolate = TRUE) +
  geom_contour(aes(z = t), breaks = c(-1.96, 1.96), colour = "black", linewidth = 0.5) +
  geom_point(data = subj, aes(OS, LP), inherit.aes = FALSE,
             shape = 21, fill = "white", colour = "black", size = 1.6) +
  geom_vline(xintercept = os_vals, linetype = "dotted", colour = "grey40") +
  geom_hline(yintercept = lp_vals, linetype = "dotted", colour = "grey40") +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b",
                       midpoint = 0, limits = c(-lim, lim),
                       name = "Interaction\ncontrast (uV)") +
  coord_cartesian(expand = FALSE) +
  labs(x = "Orthographic Sensitivity (PCA score)",
       y = "Language Proficiency (PCA score)") +
  theme_bw(base_size = 10)
p3

ggsave("N250_4way_cells.png",    p1, width = 7.5, height = 7,   dpi = 300)
ggsave("N250_4way_cxeffect.png", p2, width = 7,   height = 6.5, dpi = 300)
ggsave("N250_4way_surface.png",  p3, width = 6.5, height = 5,   dpi = 300)
