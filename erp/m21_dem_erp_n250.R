# This R script contains the code for 'munging' the morph 21 data

library(dplyr)

# Read in demographic data file
m21_dem <- read_csv("m21_dem_data.csv")

# Read in N250 erp data file
m21_n250 <- read_csv("S101-177_n250.csv")

# Join demographic and erp data files. Use `inner_join` rather than `full_join` function
# to eliminate rows with `NA`
m21_n250 <- inner_join(m21_dem,m21_n250, by = "SubjID")

# Save a .csv file of the combined dataset 
write_csv(m21_n250, "m21_dem_erp_n250_rmna.csv")

# For each dataset, create a subset with only the electrode sites we will be 
# analysing: F3, Fz, F4, C3, Cz, C4, P3, Pz, P4
sites = c(3,2, 25, 7, 20, 21, 12, 11, 16)
m21_n250_9 <- filter(m21_n250, chindex %in% sites)

# Create separate columns for the  variable: "Anteriority"
# To do this we have to use the`mutate` function from the dplyr package
# along with the `case_when` function. The `case_when` functions  is a sequence
# of two-sided formulas. The left hand side determines which values match
# this case. The right hand side provides the replacement value.

m21_n250_9 <- dplyr::mutate(m21_n250_9, 
                            anteriority = case_when(grepl("F", chlabel) ~ "Frontal",
                                              grepl("C", chlabel) ~ "Central",
                                              grepl("P", chlabel) ~ "Parietal"
                                              )
                            )


# Create separate columns for the  variable: "Laterality" again using the
#  `mutate` and `case_when` functions

m21_n250_9 <- dplyr::mutate(m21_n250_9, 
                            laterality = case_when(grepl("3", chlabel) ~ "Left",
                                                    grepl("z", chlabel) ~ "Midline",
                                                    grepl("Z", chlabel) ~ "Midline",
                                                    grepl("4", chlabel) ~ "Right"
                            )
)


# Create separate columns for the  variable: "Morphological Family Size" again using the
#  `mutate` and `case_when` functions

m21_n250_9 <- dplyr::mutate(m21_n250_9, 
                            fam_size = case_when(grepl("small", binlabel) ~ "Small",
                                                   grepl("large", binlabel) ~ "Large"
                            )
)

# Create smaller dataset with only the columns we need

m21_n250_9b <- dplyr::select(m21_n250_9, 
                             SubjID, 
                             Type, 
                             anteriority, 
                             laterality, 
                             fam_size,
                             chlabel,
                             value,
                             binlabel)


# Divide dataset into 3 separate ones: "words", "nonwords simple" and "non-words complex"
m21_n250_words <- dplyr::filter(m21_n250_9b, grepl("Critical_word",binlabel))
m21_n250_nwsmpl <- dplyr::filter(m21_n250_9b, grepl("simple",binlabel))
m21_n250_nwcplx <- dplyr::filter(m21_n250_9b, grepl("complex",binlabel))


# Conduct ANOVA 





