# This script takes the WIMP classification data (too large for github, takes
# long to read in and compile) and pulls out stuff that's actually used in the
# manuscript. The inputs are .gitignore'd, the outputs are committed.

library(dplyr)

#Read in combined WIMP data
wimp_class <- readRDS(here::here("data","wimp_classified_filt.rds"))

#Make list of top 10 genera
top_10_gen <-
  wimp_class %>%
  filter(!is.na(genus)) %>%
  filter(genus != "Unassigned") %>%
  count(genus) %>%
  arrange(-n) %>%
  head(10) %>%
  pull(genus)

# Make genus count by barcode that will be further processed in the manuscript
genus_count_by_barcode <-
  wimp_class %>%
  filter(!is.na(genus)) %>%
  filter(genus != "Unassigned") %>%
  mutate(genmod = ifelse(genus %in% top_10_gen, genus, "Other")) %>%
  mutate(genmod = factor(genmod, levels=top_10_gen %>% sort() %>% append("Other"))) %>%
  rename(gen_og = genus, genus = genmod) %>%
  count(barcode, genus)

# Save and commit the preprocessed data
save(top_10_gen, genus_count_by_barcode, file=here::here("data/preprocessed.rd"))
