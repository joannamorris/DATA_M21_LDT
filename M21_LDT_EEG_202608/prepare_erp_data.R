## =========================================================================
## prepare_erp_data.R
##
## Reads a long-format ERP mean-amplitude CSV (as produced by
## ERP_measure_amp.m / pop_geterpvalues) and derives the columns needed
## for statistical modeling:
##
##   SubjID          - first 4 characters of the ERPset column
##   lexical_status   <factor> "word" | "nonword"
##   complexity        <factor> "simple" | "complex"   (nonwords only, NA for words)
##   family_size       <factor> "small" | "large"       (NA if not present in binlabel)
##   base_frequency    <factor> "low"  | "high"         (NA if not present in binlabel)
##
## binlabel is parsed by keyword matching (case-insensitive) rather than
## positional splitting, since the BF and FS bin descriptor files order
## and include different terms in their labels:
##
##   Words,   both files:  "Critical_word_small_FS_High_BF_(residualized)"
##   Nonwords, BF file:    "NonWord_Simple_High_Base_Frequency"      (no family size)
##   Nonwords, FS file:    "nonword_large_complex"                    (no base frequency)
##
## Requires: dplyr, stringr
## =========================================================================

library(dplyr)
library(stringr)

#' Add SubjID and the four derived factor columns to a raw ERP long CSV
#'
#' @param df A data frame read from an ERP_measure_amp.m output CSV, with
#'   at minimum columns `ERPset` and `binlabel`.
#' @return The same data frame with SubjID, lexical_status, complexity,
#'   family_size, and base_frequency added as factor columns (SubjID is
#'   character).
prepare_erp_data <- function(df) {

  df %>%
    mutate(

      SubjID = substr(ERPset, 1, 4),

      lexical_status = case_when(
        str_detect(binlabel, regex("nonword", ignore_case = TRUE)) ~ "nonword",
        str_detect(binlabel, regex("word",    ignore_case = TRUE)) ~ "word",
        TRUE ~ NA_character_
      ),

      complexity = case_when(
        lexical_status != "nonword" ~ NA_character_,
        str_detect(binlabel, regex("simple",  ignore_case = TRUE)) ~ "simple",
        str_detect(binlabel, regex("complex", ignore_case = TRUE)) ~ "complex",
        TRUE ~ NA_character_
      ),

      family_size = case_when(
        str_detect(binlabel, regex("small", ignore_case = TRUE)) ~ "small",
        str_detect(binlabel, regex("large", ignore_case = TRUE)) ~ "large",
        TRUE ~ NA_character_
      ),

      base_frequency = case_when(
        str_detect(binlabel, regex("high", ignore_case = TRUE)) ~ "high",
        str_detect(binlabel, regex("low",  ignore_case = TRUE)) ~ "low",
        TRUE ~ NA_character_
      ),

      lexical_status = factor(lexical_status, levels = c("word", "nonword")),
      complexity     = factor(complexity,     levels = c("simple", "complex")),
      family_size    = factor(family_size,    levels = c("small", "large")),
      base_frequency = factor(base_frequency, levels = c("low", "high"))

    )
}

## -------------------------------------------------------------------------
## Read in the two files and apply the transformation
## -------------------------------------------------------------------------

erp_bf_raw <- read.csv("LDT_mea_200_300_bl_n200_0_20260827_150844_BF_BA.csv",
                        stringsAsFactors = FALSE)

erp_fs_raw <- read.csv("LDT_mea_200_300_bl_n200_0_20260827_150708_FS_BA.csv",
                        stringsAsFactors = FALSE)

erp_bf <- prepare_erp_data(erp_bf_raw)
erp_fs <- prepare_erp_data(erp_fs_raw)

## -------------------------------------------------------------------------
## Sanity checks -- confirm every binlabel was parsed and factor levels
## line up with what's actually in the data before moving to modeling
## -------------------------------------------------------------------------

check_unparsed <- function(df, label) {

  unparsed <- df %>%
    filter(is.na(lexical_status) |
             (lexical_status == "nonword" & is.na(complexity))) %>%
    distinct(binlabel)

  if (nrow(unparsed) > 0) {
    warning(sprintf("%s: %d binlabel(s) did not parse as expected:\n%s",
                     label, nrow(unparsed),
                     paste(unparsed$binlabel, collapse = "\n")))
  } else {
    message(sprintf("%s: all binlabels parsed successfully.", label))
  }
}

check_unparsed(erp_bf, "BF file")
check_unparsed(erp_fs, "FS file")

# Quick look at how the derived factors distribute across binlabel, per file
erp_bf %>% distinct(binlabel, lexical_status, complexity, family_size, base_frequency)
erp_fs %>% distinct(binlabel, lexical_status, complexity, family_size, base_frequency)

## -------------------------------------------------------------------------
## erp_bf and erp_fs are now ready for modeling:
##   - erp_bf: base frequency is populated for both words and nonwords;
##             family_size is NA for nonwords (collapsed across FS in this file)
##   - erp_fs: family_size is populated for both words and nonwords;
##             base_frequency is NA for nonwords (collapsed across BF in this file)
## -------------------------------------------------------------------------
