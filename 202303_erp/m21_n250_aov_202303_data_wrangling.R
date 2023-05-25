
library(readr)
library(tidyr)
library(dplyr)


#This script joins the m21 N250 data with the spelling and vocabulary data


# First we load the libraries we need


library(readr)
library(psych)
library(dplyr)
library(tidyr)


#Then We load the N250 erp data file and the spelling and  vocab data, then  we join the files. We will use the `inner_join` rather than the `full_join` function in order to eliminate rows with missing data.

sv_202303.na <- read_csv("m21_spell_vocab_raw_z_pca.csv", show_col_types = FALSE)
n250 <- read_csv("S101-177_n250.csv", show_col_types = FALSE)
n250 <- inner_join(sv_202303.na,n250, by = "SubjID")  #join subject PCA data

#Divide participants based on median split of Dim2.  Higher values on this factor indicate that spelling scores were relatively higher than vocabulary, 

n250.median <- median(n250$Dim.2)
n250 <- n250 |>
  mutate(lang_type = case_when(
    Dim.2 < n250.median ~ "Semantic",
    Dim.2 > n250.median ~ "Orthographic"
  ))


# Let's save a `.csv` file with the data from the combined dataset 
write_csv(n250, "202303_sv_n250_rmna.csv")
