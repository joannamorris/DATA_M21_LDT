# Load tidyverse package
library(tidyverse)

# read in rt data files with condition labels to be fixed
df1 <- read_csv("rtdata_pc_B.csv")

# add new column with fixed labels
df1 <- df1 |> mutate(targ_type_2 = case_when(targ_type == "NW_L_COMP" ~ "NW_L_SIMP",
                                                               targ_type == "NW_S_COMP" ~ "NW_S_SIMP",
                                                               targ_type == "NW_L_SIMP" ~ "NW_L_COMP",
                                                               targ_type == "NW_S_SIMP" ~ "NW_S_COMP",
                                                               TRUE ~ targ_type ))

# delete old column and rename new one
df1 <- df1 |> 
  select(-targ_type) |>
  rename(targ_type = targ_type_2)

# put the columns back in original order
df1 <- df1 |>
  select(subject_nr, accuracy, average_response_time, cond_trig, correct, counter, cresp,
         datetime, experiment_file, logfile, response, response_time,
         targ_type, target, total_correct, total_response_time, total_responses, word_trig)

# write the fixed file to disc
write_csv(df1, "rt_data_pc_B_fixed.csv")
