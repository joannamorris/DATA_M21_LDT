# This file formats the rt, pca and freq data for m21 in preparation for statistical analysis

#Loads RT data and join to PCA dataset

library(readr)
library(dplyr)
library(tidyr)
sv <- read_csv("m21_spell_vocab_raw_z_pca.csv")
frq_w <- read_csv("cw_frq_2.csv")
frq_nw <- read_csv("nw_frq_2.csv")
rt <- read_csv("cw_nw_rt_2.csv")
rt <- rt |> select(c("SubjID", 
                                 "response_time", 
                                 "correct", 
                                 "targ_type", 
                                 "cond_trig", 
                                 "word_trig", 
                                 "target", 
                                 "experiment_file"))


rt_sv <- inner_join( rt, sv, by = "SubjID")  #join subject PCA data

# Creates two different dataframes for words and nonwords

words_rt <- rt_sv |> filter(grepl("CW_", targ_type))
nwords_rt <- rt_sv |> filter(grepl("NW_", targ_type))

# joins the frequency data for each dataset

words_rt <- words_rt |> mutate(word = tolower(target))
words_rt <- left_join(words_rt, frq_w, by = "word")

nwords_rt <- nwords_rt |> mutate(word = tolower(target))
nwords_rt <- left_join(nwords_rt, frq_nw, by = "word")

# Creates columns for each factor

nwords_rt <- dplyr::mutate(nwords_rt,
                        famsize = case_when(grepl("_S_", targ_type) ~ "Small",
                                             grepl("_L_", targ_type) ~ "Large"))

words_rt <- dplyr::mutate(words_rt,
                           famsize = case_when(grepl("_S", targ_type) ~ "Small",
                                               grepl("_L", targ_type) ~ "Large"))


# Write files to disk
words_rt <- write_csv(words_rt, "words_rt_sv_frq.csv")
nwords_rt <- write_csv(nwords_rt, "nwords_rt_sv_frq.csv")