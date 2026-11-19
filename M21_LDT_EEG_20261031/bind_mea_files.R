library(dplyr)
M21_LDT_mea_200_300_bl_n200_0 <- bind_rows(list(A = M21_LDT_mea_200_300_bl_n200_0_A, 
                                                B = M21_LDT_mea_200_300_bl_n200_0_B),
                                           .id = "list")
write_csv(M21_LDT_mea_200_300_bl_n200_0," M21_LDT_mea_200_300_bl_n200_0.csv")

M21_LDT_mea_300_500_bl_n200_0 <- bind_rows(list(A = M21_LDT_mea_300_500_bl_n200_0_A, 
                                                B = M21_LDT_mea_300_500_bl_n200_0_B),
                                           .id = "list")
write_csv(M21_LDT_mea_300_500_bl_n200_0," M21_LDT_mea_300_500_bl_n200_0.csv")
