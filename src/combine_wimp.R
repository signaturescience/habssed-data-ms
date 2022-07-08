# Alex Koeppel
# Signature Science
# Project Erie - NOAA SBIR
# 07/08/2022
# combine_wimp.R - Combine WIMP results and test code for taxon chart.

#Load packages
library("tidyverse")
library("viridis")

#Read in all WIMP results
#Read in WIMP outputs
wimp_prebloom1 <- read_csv(here::here("data","fullrun1_wimp_results.csv")) %>%
  mutate(barcode="fullrun1")
wimp_prebloom2 <- read_csv(here::here("data","fullrun2_wimp_results.csv")) %>%
  mutate(barcode="fullrun2")
wimp_bc1 <- read_csv(here::here("data","barcode_run1_wimp_results.csv")) %>%
  #Filter out unused barcodes
  filter(barcode %in% c("barcode01","barcode02","barcode03","barcode04","barcode05"))
wimp_bc2 <- read_csv(here::here("data","barcode_run2_wimp_results.csv")) %>%
  #Filter out unused barcodes
  filter(barcode %in% c("barcode06","barcode07","barcode08","barcode09","barcode10","barcode11"))

#Combine all WIMP results
all_wimp <- wimp_bc1 %>%
  bind_rows(wimp_bc2) %>%
  bind_rows(wimp_prebloom1) %>%
  bind_rows(wimp_prebloom2)

#Add taxonomy level column
all_wimp_tl <- all_wimp %>%
  rowwise() %>%
  mutate(lin_length = length(unlist(str_split(name," ")))) %>%
  mutate(lin_length = ifelse(str_detect(name, "Candidatus"),lin_length-1,lin_length)) %>%
  mutate(lin_length = ifelse(str_detect(name, "sp."),lin_length-1,lin_length)) %>%
  ungroup()

#Filter to classified
wimp_class <- all_wimp_tl %>%
  #Remove unclassified
  filter(exit_status !="Unclassified") %>%
  #Remove effectively unclassified
  filter(name !="root") %>%
  filter(name !="cellular organisms")

#Add genus tag
wimp_genera <- wimp_class %>%
  mutate(genus = ifelse(str_detect(name, "Candidatus"),
                        str_replace(name, "Candidatus","") %>%
                          str_extract("[^ ]+"),
                        str_extract(name, "[^ ]+")))
  #filter(str_detect(name, "Candidatus")) %>%
  #select(name, genus)
  #count(barcode, genus)

#Write table
saveRDS(wimp_genera, here::here("data","wimp_classified_filt.rds"))

#Make genus count table
wimp_genera %>%
  count(barcode, genus) %>%
  group_by(barcode) %>%
  top_n(8, n)
