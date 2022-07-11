#!/bin/bash

#The WIMP output only includes the taxon names for the most specific taxonomic level classified.
#In order to get uniform genus (or order etc.) level classifications, we need the full taxonomy
#lineage for each taxon ID.

#We will use taxonkit to generate a lookup table for the IDs
#INSTALL TAXONKIT 
# conda install -c bioconda taxonkit
# wget -c ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
# tar -zxvf taxdump.tar.gz
# mkdir -p $HOME/.taxonkit
# cp names.dmp nodes.dmp delnodes.dmp merged.dmp $HOME/.taxonkit

#Set working directory
WDIR="/data/projects/cag/users/akoeppel/projects/habssed-data-ms"

#Generate list of taxon IDs used in analysis
cat $WDIR/data/*results.csv | cut -f 6,7 -d "," | grep -v "-" | sort | uniq | grep -vw name | cut -f 1 -d "," > $WDIR/data/ncbi_list.txt

#Generate taxonomy table for each with the columns
# 1) ID
# 2) Kingdom
# 3) Phylum
# 4) Class
# 5) Order
# 6) Genus
# 7) Species
# 8) Strain/Subspecies
#... and unassigned levels marked "Unassigned".

cat $WDIR/data/ncbi_list.txt | taxonkit reformat -I 1 -r "Unassigned" -f "{k}\t{p}\t{c}\t{o}\t{f}\t{g}\t{s}\t{t}" > $WDIR/data/ncbi_taxa.tsv
