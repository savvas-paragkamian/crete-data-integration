# Crete data integration

This repository aims to bring together biodiversity knowledge regarding 
the island of Crete, Greece. Crete has been studied extensively for more 
than three centures. This has resulted in a wealth of knownledge available 
in the forms of :

* literature (contemporary - PubMed and historical - Biodiversity Heriatage Library),

* species occurrences and metadata in public databases (GBIF, IUCN)

* environmental data from remote sensing (e.g Copernicus, )

* sequences from environmental DNA studies (e.g ENA, Mgnify)

More specificaly, the focus is on the soil ecosystems of Crete.
Soils are consindered the cornerstones of terrestrial functioning.
Biodiversity interactions are between all domains of life which form
multilevel associations. Bacteria, archaea, unicellular eukaryotes, nematodes,
earthworms, arthropods, molluscs, plants, mammals; all occur in unison and 
influence the ecosystems they inhabit with their abundance, biomass and metabolism.
The plant-insect-soil ecosystem is starting to be studied as a whole to discover
important associations with practical implications such as plant resistance 
to insect attack.

The integration of biodiversity knowledge in one place is a longstanding
goal in ecological research. The synthesis of multiple data types and datasets across the globe has enabled 
holistic approaches to crutial scientific and sociatal questions.

Based on the consept of data representation of ecosystems 

## BHL

Historical literature of Crete's biodiversity.

```
wget http://www.biodiversitylibrary.org/data/data.zip
```
From the schema and the BHL data model we perform searches on Title, Items and Subjects. Items are the bound objects of BHL, so a title can have multiple items. The digitised document is the item. Additionaly, each title is assigned with subjects. The are not standardised. Each Item also has a pages table with information per page.

In the BHL schema it is noted that :

NOTE: This export DOES NOT include all of the pages in the BHL database. It only contains pages on which taxonomic names have been identified.

## Pubmed

Keep the PMIDs of the articles that mention crete

```
date; gunzip -c ../pubmed2023/*.tsv.gz | ./scripts/search_engine.awk keywords_crete.txt - > crete_pubmed_ids.tsv ; date 
```

then keep only the PMIDs of Crete

```
gunzip -c ../pubmed2023/*.tsv.gz \ 
    | gawk -F"\t" -v OFS="\t" '(FNR==NR){id[$2]=1; next}{gsub("\\|.*$","",$1); if ($1 in id){print}}' crete_results.tsv - > crete_pubmed_all.tsv
```
The OFS ensures the output is tab-separated after gsub.

Sanity check that all abstracts are returned

```
gawk -F"\t" '(FNR==NR){found[$1]=1; next}(!($2 in found)){print $2}' crete_pubmed_all.tsv crete_pubmed_ids.tsv
```

## GBIF

> GBIF.org (17 January 2023) GBIF Occurrence Download  https://doi.org/10.15468/dl.xphruk

The `occurrence.txt` has 259 fields. 

```
head -1 occurrence.txt | gawk -F"\t" '{for (i=1;i<=NF;i++){print i FS $i}}' 
```

Summery of occurrences per kingdom
```
gawk -F"\t" '(NR>1){a[$197]++}END{for (i in a){print i FS a[i]}}' occurrence.txt
Protozoa        483
Chromista       12984
Plantae 50763
Archaea 35
Animalia        93692
Bacteria        2189
incertae sedis  871
Fungi   11675
```

## JGI GOLD

Download all the metadata of the GOLD database from [here](https://gold.jgi.doe.gov/downloads). 
Select the `Public Studies/Biosamples/SPs/APs/Organisms Excel` option.

## IUCN

More than 650 assessments of species that occur in Crete are available in IUCN Red Lists.

## EUROPEAN SOIL DATA CENTRE (ESDAC)

ESDAC hosts the European soil database which contains information about soils across
Europe from satelite data as well as sampling data. More specificaly, Land Use and Cover 
Survey (LUCAS) has valuable point data and soil physical/ chemical properties. This 
top soil sampling has also reached Crete.

## Copernicus Land Monitoring Service

Copernicus contains multiple remore sensing data that for example categorise the 
ecotypes of Crete.

## Metagenomic studies

Island Sampling Day, a metagenome project, sampled top soil in 72 locations around Crete
in 2016 and 2022.
