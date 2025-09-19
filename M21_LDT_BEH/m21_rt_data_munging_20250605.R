library(tidyverse)

# We read in the raw data from opensesame and select only the variables we need
df <- read_csv("csv_files/rawdata_rt_1a.csv", show_col_types = FALSE)
df_1 <- df |> select(subject_nr,counter,cond_trig,word_trig,targ_type,
                     target,response,cresp,correct,response_time) |> 
  filter(subject_nr != 0)  # gets rid of lines with  0 or empty subject numbers

unique(df_1$subject_nr)
str(df_1)

# For some reason the raw data file has the data 3 times!  So this code takes only the first set
# of data.  The first three hundred rows for each subject.
df_first_300 <- df_1 |> 
  group_by(subject_nr) |> 
  slice(1:300) |> 
  ungroup()  |>
  filter(subject_nr > 100) # remove pilot data

unique(df_first_300$subject_nr)

# In order to get the data for just the stimuli, I need to get them from just a single subject
df_S101 <- df_first_300 |> filter(subject_nr == 101)
stimuli <- df_S101 |> select(cond_trig, targ_type, word_trig, target)
conditions <- df_S101 |> select(cond_trig,targ_type)
words <- df_S101 |> select(word_trig, target)

# Now I can write the data for all subjects and the stimuli to disk
write_csv(stimuli, "stimuli.csv")
write_csv(df_1, "rt_data_chrt1.csv")

# Now we can read in the data from cohort2 that we got from the .vmrk file
df_2 <- read_csv("csv_files/rt_cw_nw_2_frm_vmrk.csv")


# We now need to bind this df with the stimuli df  the word and condition triggers
df_2_stm <- left_join(df_2, stimuli, by = join_by(cond_trig, word_trig))
write_csv(df_2_stm, "rt_data_chrt2.csv")

