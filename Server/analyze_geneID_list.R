# Get cDNA sequences for given geneIDs from BioMaRT

if (any(grepl('SSTP', genelist$geneID))) {
    Sspp.seq <- getBM(attributes=c('wbps_gene_id', 'cdna'),
                    # grab the cDNA sequences for the given genes from WormBase Parasite
                    mart = useMart(biomart="parasite_mart", 
                                   dataset = "wbps_gene", 
                                   host="https://parasite.wormbase.org", 
                                   port = 443),
                    filters = c('species_id_1010', 
                                'wbps_gene_id'),
                    values = list(c('strattprjeb125','ststerprjeb528'),
                                  genelist$geneID)) %>%
        as_tibble() %>%
        #we need to rename the columns retreived from biomart
        dplyr::rename(geneID = wbps_gene_id, cDNA = cdna)
    Sspp.seq$cDNA <- tolower(Sspp.seq$cDNA)
} 
if (any(grepl('SRAE', genelist$geneID))) {
    Sr.seq <- getBM(attributes=c('wbps_transcript_id', 'cdna'),
                    # grab the cDNA sequences for the given genes from WormBase Parasite
                    mart = useMart(biomart="parasite_mart", 
                                   dataset = "wbps_gene", 
                                   host="https://parasite.wormbase.org", 
                                   port = 443),
                    filters = c('species_id_1010',
                                'wbps_transcript_id'),
                    values = list('strattprjeb125',
                                  genelist$geneID)) %>%
        as_tibble() %>%
        #we need to rename the columns retreived from biomart
        dplyr::rename(geneID = wbps_transcript_id, cDNA = cdna)
    Sr.seq$cDNA <- tolower(Sr.seq$cDNA)
}

gene.seq <- dplyr::bind_rows(Sspp.seq,Sr.seq) %>%
    dplyr::left_join(genelist, . , by = "geneID")

## Calculate info each sequence (S. ratti index) ----
temp<- lapply(gene.seq$cDNA, function (x){
    if (!is.na(x)) {
    s2c(x) %>%
        calc_sequence_stats(.,w)}
    else {
        list(GC = NA, CAI = NA)
    }
}) 

# Strongyloides CAI values ----
info.gene.seq<- temp %>%
    map("GC") %>%
    unlist() %>%
    as_tibble_col(column_name = 'GC (%)')

info.gene.seq<- temp %>%
    map("CAI") %>%
    unlist() %>%
    as_tibble_col(column_name = 'Sr_CAI') %>%
    add_column(info.gene.seq, .)

info.gene.seq <- info.gene.seq %>%
    add_column(geneID = gene.seq$geneID, .before = 'GC (%)') 

# C. elegans CAI values ----
# Only run this under certain conditions
# 

## Calculate info each sequence (C. elegans index) ----
Ce.temp<- lapply(gene.seq$cDNA, function (x){
    if (!is.na(x)) {
        s2c(x) %>%
            calc_sequence_stats(.,Ce.w)}
    else {
        list(GC = NA, CAI = NA)
    }
}) 

ce.info.gene.seq<- Ce.temp %>%
    map("CAI") %>%
    unlist() %>%
    as_tibble_col(column_name = 'Ce_CAI')


## Merge both tibbles
info.gene.seq <- add_column(info.gene.seq, 
                            Ce_CAI = ce.info.gene.seq$Ce_CAI, .after = "Sr_CAI")

vals$geneIDs <- info.gene.seq %>%
    left_join(.,gene.seq, by = "geneID") %>%
    rename('cDNA sequence' = cDNA)

info.gene.seq