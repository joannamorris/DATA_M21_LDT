
library(tidyverse)

dem <- read_csv("csv/chrt1/demographics_cleaned.csv")
spl <- read_csv("csv/chrt1/spelling_scores.csv")
vcb <- read_csv("csv/chrt1/vocabulary_scores.csv")
art <- read_csv("csv/chrt1/art_scores.csv")

# 2. Check dimensions
dim(dem)  
dim(spl)
dim(vcb) 
dim(art) 

# 3. Find rows in demo2 but not in demo1
lang1 <- full_join(spl, vcb, by = "Participant Number")
lang2 <- full_join(lang1, art, by = "Participant Number")
dem_lang <- full_join(dem, lang2, by = "Participant Number")

write_csv(dem_lang, "csv/chrt1/demographics_language.csv")


