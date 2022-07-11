# Alex Koeppel
# Signature Science
# Project Erie - NOAA SBIR
# 07/08/2022
# combine_wimp.R - Combine WIMP results and test code for taxon chart.

#Load packages
library("tidyverse")
library("viridis")

#Load in taxon lookup table
tax_lookup <- read_tsv(here::here("data","ncbi_taxa.tsv"),
                       col_names = c("taxID", "kingdome", "phylum", "class", "order",
                                     "family","genus","species","strain"))

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

#Load in supplemental data (for sample IDs)
samp_dat <- read_csv(here::here("data","supplemental_table_S1_sampledata.csv"))

#Combine all WIMP results
all_wimp <- wimp_bc1 %>%
  bind_rows(wimp_bc2) %>%
  bind_rows(wimp_prebloom1) %>%
  bind_rows(wimp_prebloom2) %>%
  #Join to taxonomy
  left_join(tax_lookup)


#Filter to classified
wimp_class <- all_wimp %>%
  #Remove unclassified
  filter(exit_status !="Unclassified") %>%
  #Remove effectively unclassified
  filter(name !="root") %>%
  filter(name !="cellular organisms")

#Write table
saveRDS(wimp_class, here::here("data","wimp_classified_filt.rds"))

#Make list of top 10 genera
top_10_gen <- wimp_class %>%
  filter(!is.na(genus)) %>%
  filter(genus != "Unassigned") %>%
  count(genus) %>%
  arrange(-n) %>%
  head(10) %>%
  pull(genus)

cols <- c("Acinetobacter" = "purple", "Candidatus Fonsibacter" = "darkblue",
          "Candidatus Methylopumilis" = "darkgreen", "Candidatus Nanopelagicus" = "blue",
          "Candidatus Planktophila" = "green", "Escherichia" = "red2", "Homo" = "orange",
          "Microcystis" = "forestgreen", "Muvirus" = "Yellow", "Salmonella" = "salmon",
          "Other" = "darkgrey")
##p + scale_colour_manual(values = cols)

#Make genus count table
wimp_class %>%
  filter(!is.na(genus)) %>%
  filter(genus != "Unassigned") %>%
  mutate(genmod = ifelse(genus %in% top_10_gen, genus, "Other")) %>%
  mutate(genmod = factor(genmod, levels=top_10_gen %>% sort() %>% append("Other"))) %>%
  rename(gen_og = genus, genus = genmod) %>%
  count(barcode, genus) %>%
  group_by(barcode) %>%
  mutate(n_frac = n / sum(n)) %>%
  ungroup() %>%
  left_join(samp_dat %>% select(barcode, sample), by="barcode") %>%
  mutate(samptype = case_when(
    str_detect(sample,"_RB") ~ "Reagent Blank",
    str_detect(sample,"_NC") ~ "Negative Control",
    str_detect(sample,"_B") ~ "Bloom",
    str_detect(sample,"_B") ~ "Pre-Bloom",
    TRUE ~ "NA"
  )) %>%
  mutate(sampname = case_when(
    sample == "MP1_RB1" ~ "Reagent Blank 1",
    sample == "MP2_RB1" ~ "Reagent Blank 2",
    sample == "MP2_NC1" ~ "Negative Control",
    sample == "MP1_WE02_B1" ~ "WE02 Bloom 1",
    sample == "MP1_WE02_PB1" ~ "WE02 Pre-bloom 1",
    sample == "MP1_WE13_B1" ~ "WE13 Bloom 1",
    sample == "MP1_WE13_PB1" ~ "WE13 Pre-bloom 1",
    sample == "MP2_WE02_PB2" ~ "WE02 Pre-bloom 2",
    sample == "MP2_WE13_PB2" ~ "WE13 Pre-bloom 2",
    sample == "MP2_WE02_B2" ~ "WE02 Bloom 2",
    sample == "MP2_WE13_B2" ~ "WE13 Bloom 2",
    sample == "FR1_WE13_PB6" ~ "WE02 Pre-bloom 3",
    sample == "FR2_WE02_PB2" ~ "WE13 Pre-bloom 3",
    TRUE ~ "NA"
  )) %>%
  mutate(sampname = factor(sampname, levels=c( "WE02 Bloom 1", "WE02 Bloom 2", "WE13 Bloom 1", "WE13 Bloom 2",
                                               "WE02 Pre-bloom 1", "WE02 Pre-bloom 2", "WE02 Pre-bloom 3",
                                               "WE13 Pre-bloom 1", "WE13 Pre-bloom 2", "WE13 Pre-bloom 3",
                                               "Reagent Blank 1", "Reagent Blank 2", "Negative Control"))) %>%
  ggplot(aes(x=sampname, y=n_frac, fill=genus)) +
  geom_bar(stat="identity")+
  scale_fill_manual(values=cols)+
  #scale_fill_viridis(discrete = T, option="D") +
  xlab("Sample ID") +
  ylab("Relative Abundance")+
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))
