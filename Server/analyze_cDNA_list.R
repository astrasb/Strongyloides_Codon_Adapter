# This script includes the the primary computation for analyzing a list of cDNA
# sequences for the Strongyloides Codon Adapter App in Analyze Sequences Mode
# This script is very similar to analyze_geneID_list.R, except since the user has 
# already provided cDNA sequences, the calls to BioMart are skipped. Code will analyse 
# GC content and CAI values for each gene using calls to `calc_sequence_stats.R`.

analyze_cDNA_list <- function(gene.seq, vals){
    withProgress(message = "Calculating...",expr = {
        setProgress(0)

    
    calc.inc <- 0.3/nrow(gene.seq)
    
    # Strongyloides CAI values ----
    Sr.temp<- lapply(gene.seq$cDNA, function (x){
        incProgress(amount = calc.inc)
        if (!is.na(x)) {
            s2c(x) %>%
                calc_sequence_stats(.,w.tbl$Sr_relAdap)}
        else {
            list(GC = NA, CAI = NA)
        }
    }) 
    
    ## Calculate info each sequence (S. ratti index)
    info.gene.seq<- Sr.temp %>%
        map("GC") %>%
        unlist() %>%
        as_tibble_col(column_name = 'GC')
    
    info.gene.seq<- Sr.temp %>%
        map("CAI") %>%
        unlist() %>%
        as_tibble_col(column_name = 'Sr_CAI') %>%
        add_column(info.gene.seq, .)
    
    info.gene.seq <- info.gene.seq %>%
        add_column(geneID = gene.seq$geneID, .before = 'GC') 
    
    
    # C. elegans CAI values ----
    setProgress(0.35)
    ## Calculate info each sequence (C. elegans index)
    Ce.temp<- lapply(gene.seq$cDNA, function (x){
        incProgress(amount = calc.inc)
        if (!is.na(x)) {
            s2c(x) %>%
                calc_sequence_stats(.,w.tbl$Ce_relAdapt)}
        else {
            list(GC = NA, CAI = NA)
        }
    }) 
    
    Ce.info.gene.seq<- Ce.temp %>%
        map("CAI") %>%
        unlist() %>%
        as_tibble_col(column_name = 'Ce_CAI')
    
    # B. malayi CAI values ----
    setProgress(0.7)
    ## Calculate info each sequence (B. malayi index)
    Bm.temp<- lapply(gene.seq$cDNA, function (x){
        incProgress(amount = calc.inc)
        if (!is.na(x)) {
            s2c(x) %>%
                calc_sequence_stats(.,w.tbl$Bm_relAdapt)}
        else {
            list(GC = NA, CAI = NA)
        }
    }) 
    
    Bm.info.gene.seq<- Bm.temp %>%
        map("CAI") %>%
        unlist() %>%
        as_tibble_col(column_name = 'Bm_CAI')

    # N. brasiliensis CAI values ----
    # 
    ## Calculate info each sequence ( N. brasiliensis index) 
    Nb.temp<- lapply(gene.seq$cDNA, function (x){
        incProgress(amount = calc.inc)
        if (!is.na(x)) {
            s2c(x) %>%
                calc_sequence_stats(.,w.tbl$Nb_relAdapt)}
        else {
            list(GC = NA, CAI = NA)
        }
    }) 
    
    Nb.info.gene.seq<- Nb.temp %>%
        map("CAI") %>%
        unlist() %>%
        as_tibble_col(column_name = 'Nb_CAI')
    
    ## Merge tibbles ----
    info.gene.seq <- add_column(info.gene.seq, 
                                Ce_CAI = Ce.info.gene.seq$Ce_CAI,
                                Bm_CAI = Bm.info.gene.seq$Bm_CAI,
                                Nb_CAI = Nb.info.gene.seq$Nb_CAI,
                                .after = "Sr_CAI")
    
    vals$geneIDs <- suppressMessages(info.gene.seq %>%
                                         left_join(.,gene.seq) %>%
                                         rename('cDNA sequence' = cDNA))
    
    setProgress(1)
    info.gene.seq
    })
    
    
}