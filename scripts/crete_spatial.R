#!/usr/bin/Rscript
## Script name: crete_spatial.R
##
## Aim: handle spatial data of Crete
##
## Author: Savvas Paragkamian
##
## Date Created: 2023-11-16



library(sf)
library(tidyverse)
library(RColorBrewer)
# crete borders
crete_shp <- sf::st_read("data/crete/crete.shp") 

metadata_long <- read_delim("results/ena_samples_attributes-crete.tsv", delim="\t") %>%
    mutate(VALUE=gsub("\\r(?!\\n)","", VALUE, perl=T)) %>%
    distinct(.)
# metadata to wide format and column name tidy

metadata_wide <- metadata_long %>% 
    dplyr::select(-c(UNITS)) %>%
    mutate(TAG=gsub(" ","_", TAG, perl=T)) %>%
    mutate(TAG=gsub("-","_", TAG, perl=T)) %>%
    mutate(TAG=gsub("\\(|\\)","", TAG, perl=T)) %>%
    filter(!(TAG %in% c("bio_material", "BioSampleModel"))) %>% # these contain duplicates
    pivot_wider(id_cols="file", names_from=TAG, 
                values_from=VALUE) %>%
    filter(ENA_STUDY!="ERP024063") # this is the ISD Crete project


metadata_wide$elevation <- as.numeric(metadata_wide$geographic_location_elevation)
metadata_wide$geographic_location_latitude <- as.numeric(metadata_wide$geographic_location_latitude)
metadata_wide$latitude <- as.numeric(metadata_wide$latitude)
metadata_wide$geographic_location_longitude <- as.numeric(metadata_wide$geographic_location_longitude)
metadata_wide$longitude <- as.numeric(metadata_wide$longitude)

# If locations are not in geographic_location_* they might be in lat_lon.
# Here we tranform lat lon to readable format
metadata_wide$lat_lon1 <- gsub(" N ",",",metadata_wide$lat_lon, perl=T)
metadata_wide$lat_lon1 <- gsub(" |E","",metadata_wide$lat_lon1, perl=T)

metadata_wide <- metadata_wide %>%
    separate(lat_lon1, into=c("lat","lon"), sep=",") %>%
    mutate(lat=as.numeric(lat), lon=as.numeric(lon))

# combine all the complementary columns
metadata_wide$latitude <- coalesce(metadata_wide$lat, metadata_wide$geographic_location_latitude,metadata_wide$latitude)
metadata_wide$longitude <- coalesce(metadata_wide$lon, metadata_wide$geographic_location_longitude, metadata_wide$longitude)

metadata_wide_sf <- metadata_wide %>%
    dplyr::select(file,ENA_RUN,ENA_EXPERIMENT, ENA_STUDY,project_name, latitude, longitude,organism,environment_biome) %>%
    filter(!is.na(latitude)) %>%
    st_as_sf(coords=c("longitude", "latitude"),
             remove=F,
             crs="WGS84")

ena_sample_summary <- metadata_wide |>
    distinct(ENA_RUN,ENA_STUDY, organism, environment_feature, environment_biome, GOLD_Ecosystem_Classification) |>
    group_by(ENA_STUDY, organism) |>
    summarise(n=n(),.groups="keep") |>
    group_by(organism) |>
    summarise(studies=n(), samples=sum(n)) |>
    arrange(organism)

ena_sample_summary$organism <- factor(ena_sample_summary$organism, levels = c(sort(unique(ena_sample_summary$organism), decreasing = TRUE)))

ena_samples_bar <- ggplot() + 
    geom_col(ena_sample_summary, mapping=aes(x=samples, y=organism)) +
    theme_bw()+
    scale_x_continuous(breaks=seq(0,200,25))+
    xlab("Number of samples")+
    theme(axis.text.x = element_text(face="bold",
                                     size = 15),
          axis.title.x=element_text(face="bold",size=18),
          axis.ticks.y=element_blank(),axis.title.y=element_blank(),
          axis.text.y=element_text(size=10, hjust=0, vjust=0)) +
    theme(legend.position="bottom",
            panel.border = element_blank(),
            panel.grid.major = element_blank(), #remove major gridlines
            panel.grid.minor = element_blank())

ggsave("figures/ena_samples_bar.png",
       plot=ena_samples_bar,
       device="png",
       height = 75,
       width = 38,
       units="cm")

# filter the terrestrial metagenomes only
crete_terrestrial_metagenome <- st_intersection(metadata_wide_sf, crete_shp) %>%
    filter(grepl("metagenome",organism), !grepl("marine|sponge|seawater|sediment",organism))


write_delim(crete_terrestrial_metagenome,"results/crete_terrestrial_metagenome.tsv", delim="\t")

length(unique(crete_terrestrial_metagenome$ENA_STUDY))
length(unique(crete_terrestrial_metagenome$project_name))

# Maps
getPalette = colorRampPalette(brewer.pal(9, "Set1"))
colourCount = length(unique(crete_terrestrial_metagenome$organism))
colourCount_all = length(unique(metadata_wide_sf$organism))


g_base <- ggplot() +
    geom_sf(crete_shp, mapping=aes()) +
    coord_sf(crs="WGS84") +
    theme_bw()

g_ena <- g_base +
    geom_point(crete_terrestrial_metagenome,
               mapping=aes(x=longitude,
                           y=latitude,
                           color=organism),
               size=2,
               alpha=0.7) +
    scale_color_manual(values = getPalette(colourCount)) +
    theme(legend.position = 'bottom',legend.title=element_blank())

ggsave(paste0("figures/map_ena_terrestrial_metagenome_samples_crete.png",sep=""),
       plot=g_ena, 
       height = 20, 
       width = 30,
       dpi = 300, 
       units="cm",
       device="png")

g_ena_all <- g_base +
    geom_point(metadata_wide_sf,
               mapping=aes(x=longitude,
                           y=latitude,
                           color=organism),
               size=2,
               alpha=0.7) +
    scale_color_manual(values = getPalette(colourCount_all)) +
    theme(legend.position = 'bottom',legend.title=element_blank())

ggsave(paste0("figures/map_ena_all_samples_crete.png",sep=""),
       plot=g_ena_all, 
       height = 20, 
       width = 30,
       dpi = 300, 
       units="cm",
       device="png")
