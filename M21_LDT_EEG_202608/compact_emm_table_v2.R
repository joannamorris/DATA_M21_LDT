compact_emm_table <- function(emm_object,
                              by_var,
                              condition_prefix = NULL,
                              reverse = FALSE,      # TRUE = later level minus earlier (revpairwise)
                              adjust = NULL,        # NULL = emmeans default; e.g. "none", "tukey", "holm"
                              digits_est = 2,
                              digits_df = 1,
                              digits_p = 3,
                              digits_by = 2) {      # decimals shown for numeric by-values (e.g. OS, LP)

  emm_df <- summary(emm_object) |> as.data.frame()

  # by_var can be one bare name (by_var = OS) or several (by_var = c(family_size, OS))
  by_names <- names(tidyselect::eval_select(rlang::enquo(by_var), emm_df))

  contrast_df <- if (is.null(adjust)) {
    pairs(emm_object, reverse = reverse)
  } else {
    pairs(emm_object, reverse = reverse, adjust = adjust)
  }
  contrast_df <- contrast_df |> summary() |> as.data.frame()

  # Exclude BOTH Satterthwaite/KR-style and asymptotic-style CI/df column names
  non_focal_cols <- c(by_names, "emmean", "SE", "df",
                      "lower.CL", "upper.CL",
                      "asymp.LCL", "asymp.UCL")
  focal_vars <- setdiff(names(emm_df), non_focal_cols)

  # Detect whichever CI column names are actually present
  lcl_col <- intersect(c("lower.CL", "asymp.LCL"), names(emm_df))
  ucl_col <- intersect(c("upper.CL", "asymp.UCL"), names(emm_df))

  # Condition label: a bare value (single by-variable, no prefix, as before),
  # "prefix = value" (single by-variable with prefix), or
  # "name = value, name = value" (several by-variables)
  fmt_by <- function(x) {
    if (is.numeric(x)) formatC(x, format = "f", digits = digits_by) else as.character(x)
  }
  make_condition <- function(df) {
    if (length(by_names) == 1) {
      v <- fmt_by(df[[by_names]])
      if (is.null(condition_prefix)) v else paste(condition_prefix, "=", v)
    } else {
      parts <- lapply(by_names, function(n) paste(n, "=", fmt_by(df[[n]])))
      do.call(paste, c(parts, sep = ", "))
    }
  }

  emm_part <- emm_df |>
    rowwise() |>
    mutate(Comparison = paste(c_across(all_of(focal_vars)), collapse = " ")) |>
    ungroup() |>
    mutate(Condition = make_condition(pick(everything()))) |>
    transmute(
      across(all_of(by_names)),          # kept temporarily for sorting
      Comparison,
      Condition,
      Estimate = emmean,
      SE,
      df,
      lower.CL = if (length(lcl_col) > 0) .data[[lcl_col]] else NA_real_,
      upper.CL = if (length(ucl_col) > 0) .data[[ucl_col]] else NA_real_,
      t.ratio = NA_real_,
      p.value = NA_real_
    )

  # Detect whichever test-statistic column name is present (t.ratio vs z.ratio)
  ratio_col <- intersect(c("t.ratio", "z.ratio"), names(contrast_df))

  contrast_part <- contrast_df |>
    mutate(Comparison = as.character(contrast),
           Condition  = make_condition(pick(everything()))) |>
    transmute(
      across(all_of(by_names)),
      Comparison,
      Condition,
      Estimate = estimate,
      SE,
      df,
      lower.CL = NA_real_,
      upper.CL = NA_real_,
      t.ratio = if (length(ratio_col) > 0) .data[[ratio_col]] else NA_real_,
      p.value
    )

  # Sort by the by-variables' actual values (numeric order for OS/LP, level
  # order for factors), not by the text label, then drop them
  bind_rows(emm_part, contrast_part) |>
    arrange(across(all_of(by_names)), Comparison) |>
    select(-all_of(by_names)) |>
    mutate(
      Estimate = round(Estimate, digits_est),
      SE       = round(SE, digits_est),
      df       = round(df, digits_df),
      lower.CL = round(lower.CL, digits_est),
      upper.CL = round(upper.CL, digits_est),
      t.ratio  = round(t.ratio, digits_est),
      p.value  = round(p.value, digits_p)
    )
}
