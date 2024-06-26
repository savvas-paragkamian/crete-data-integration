#!/usr/bin/Rscript
## Script name: crete_literature.R
##
## Aim: handle literature of Crete
##
## Author: Savvas Paragkamian
##
## Date Created: 2024-06-12
library(taxize)
library(tidyverse)
library(RColorBrewer)

setwd("../")

#################### load data #########################
# BHL
bhl_taxa <- read_delim("results/bhl/bhl_item_page_taxa.tsv", delim="\t", col_names=F)
colnames(bhl_taxa) <- c("taxonName","itemID", "pageID")

# pubmed
pubmed_mesh <- read_delim("results/pubmed_mesh.tsv", delim="\t")
pubmed_curated <- read_delim("results/crete_pubmed_curated.tsv", delim="\t",col_names=F) |> 
        mutate(pmid=as.numeric(gsub("PMID:","",X1)))

pubmed_mesh_all <- read_delim("results/pubmed_mesh_terms.tsv", delim="\t")

# dimensions
# https://api-lab.dimensions.ai/?_gl=1*pfdosi*_ga*OTY3NTc1NDY4LjE3MTczNTMyMDg.*_ga_CHDNWH4YDX*MTcxODM5NzUyNy4yLjEuMTcxODM5ODM2Ni4wLjAuMA..
#
dimensions <- read_delim("results/Dimensions-Publication-2024-06-02_18-36-52.csv",
                         delim=",",
                         skip=1)
# google scholar
scholar <- read_delim("results/scholar_crete.tsv", delim="\t")

#################################### BHL ##################################


gbif_bhl_ids <- get_gbifid(bhl_taxa$taxonName,rows=1)

saveRDS(gbif_bhl_ids, file = "results/bhl/gbif_bhl_ids.rds")
gbif_bhl_ids_u <- unique(gbif_bhl_ids)

classification_gbif <- classification(gbif_bhl_ids_u, db = 'gbif') 

saveRDS(classification_gbif, file = "results/bhl/gbif_bhl_classification.rds")

combined_df <- do.call(rbind,classification_gbif)

combined_df$gbif_bhl <- rownames(combined_df)

combined_df <- as_tibble(combined_df) |> mutate(gbif_bhl = gsub("\\.[0-9]*$","",gbif_bhl))

plant <- combined_df |> filter(name %in% c("Plantae") )

combined_df_f <- combined_df |> filter(gbif_bhl %in% plant$gbif_bhl & rank=="phylum")

phyla_summary_p <- combined_df_f |> group_by(name) |> summarise(n_taxa=n()) |> filter(n_taxa>10)
write_delim(phyla_summary_p, "results/bhl/bhl_gbif_phyla_summary_plant.tsv", delim="\t")
animal <- combined_df |> filter(name %in% c("Animalia") )

combined_df_f <- combined_df |> filter(gbif_bhl %in% animal$gbif_bhl & rank=="phylum")

phyla_summary_a<- combined_df_f |> group_by(name) |> summarise(n_taxa=n()) |> filter(n_taxa>10)
write_delim(phyla_summary_a, "results/bhl/bhl_gbif_phyla_summary_animal.tsv", delim="\t")


############### pubmed ##########

# keep the parent mesh terms
mesh_parent_categories <- pubmed_mesh_all |>
    mutate(strcount = nchar(TreeNumber)) |>
    filter(strcount==3) |>
    rename("parent_UI"="DescriptorUI",
    "parentName"="DescriptorName")

# summarise the mesh terms results
mesh_summary <- pubmed_mesh |> 
    separate_rows(mesh_terms ,sep = "; ") |>
    distinct(mesh_terms, pmid) |>
    group_by(mesh_terms) |>
    summarise(n_pmid=n()) |>
    arrange(desc(n_pmid)) |> 
    left_join(pubmed_mesh_all, by=c("mesh_terms"="DescriptorName")) 

# summarise the mesh terms results with parent terms
mesh_summary_parent <- mesh_summary |>
    mutate(mesh_head = substr(TreeNumber,1,3)) |>
    left_join(mesh_parent_categories, by=c("mesh_head"="TreeNumber")) |>
    dplyr::select(-c(mesh_terms,DescriptorUI,TreeNumber,strcount)) |>
    group_by(parentName, parent_UI) |>
    summarise(n_pmids = sum(n_pmid), .groups="keep") |>
    arrange(desc(n_pmids))


# summarise the mesh terms results of the curated list

pubmed_curated_mesh <- pubmed_mesh |>
    filter(pmid %in% pubmed_curated$pmid) |>
    separate_rows(mesh_terms ,sep = "; ") |>
    distinct(mesh_terms, pmid) |>
    group_by(mesh_terms) |>
    summarise(n_pmid=n()) |>
    arrange(desc(n_pmid)) |> 
    left_join(pubmed_mesh_all, by=c("mesh_terms"="DescriptorName")) 

pubmed_curated_mesh_parent <- pubmed_curated_mesh |> 
    mutate(mesh_head = substr(TreeNumber,1,3)) |>
    left_join(mesh_parent_categories, by=c("mesh_head"="TreeNumber")) |>
    dplyr::select(-c(mesh_terms,DescriptorUI,TreeNumber,strcount)) |>
    group_by(parentName, parent_UI) |>
    summarise(n_pmids = sum(n_pmid), .groups="keep") |>
    arrange(desc(n_pmids))


