# Strongyloides Codon Adapter Shiny App

## --- Libraries ---
suppressPackageStartupMessages({
    library(shiny)
    library(seqinr)
    library(htmltools)
    library(shinyWidgets)
    library(shinythemes)
    library(magrittr)
    library(tidyverse)
    library(openxlsx)
    library(BiocManager)
    library(biomaRt)
    library(read.gb)
    library(tools)
    library(DT)
    library(ggplot2)
    source('Server/calc_sequence_stats.R')
    source('Server/detect_language.R',local = TRUE)
    source("Server/analyze_geneID_list.R", local = TRUE)
    source("Server/analyze_cDNA_list.R", local = TRUE)
    
})

## Increase the maximum file upload size to 30 MB
options(shiny.maxRequestSize = 45*1024^2)

## --- end_of_chunk ---

## --- Background ---
## Load *Strongyloides* and *C. elegans* codon usage chart
## For both species usage charts: 
## Calculate the relative adaptiveness of each codon
## Generate lookup tables that are readible by the seqinr::cai function
source('Static/generate_codon_lut.R', local = TRUE)

## --- end_of_chunk ---

## ---- UI ----
ui <- fluidPage(
    
    source('UI/ui.R', local = TRUE)$value,
    
    source('UI/custom_css.R', local = T)$value
)

## --- end_of_chunk ---

## ---- Server ----
# Define server logic
server <- function(input, output, session) {
    
    vals <- reactiveValues(cds_opt = NULL,
                           og_GC = NULL,
                           og_CAI = NULL,
                           opt_GC = NULL,
                           og_CeCAI = NULL,
                           geneIDs = NULL,
                           analysisType = NULL)
    
    # The bits that have to be responsive start here.
    
    ## Codon Optimization Mode ----
    ## Parse nucleotide inputs
    optimize_sequence <- eventReactive (input$goButton, {
        validate(
            need({isTruthy(input$seqtext) | isTruthy(input$loadseq)}, "Please input sequence for optimization")
        )
        
        if (isTruthy(input$seqtext)) {
            dat <- input$seqtext %>%
                tolower %>%
                trimSpace %>%
                s2c
        } else if (isTruthy(input$loadseq)){
            if (tools::file_ext(input$loadseq$name) == "gb") {
                dat <- suppressMessages(read.gb(input$loadseq$datapath, Type = "nfnr")) 
                dat <- dat[[1]]$ORIGIN %>%
                    tolower %>%
                    trimSpace %>%
                    s2c
            } else if (tools::file_ext(input$loadseq$name) == "fasta") {
                dat <- suppressMessages(read.fasta(input$loadseq$datapath,
                                                   seqonly = T)) 
                dat <- dat[[1]] %>%
                    tolower %>%
                    trimSpace %>%
                    s2c
            } else if (file_ext(input$loadseq$name) == "txt") {
                dat <- suppressWarnings(read.table(input$loadseq$datapath,
                                                   colClasses = "character",
                                                   sep = "")) 
                dat <- dat[[1]] %>%
                    tolower %>%
                    trimSpace %>%
                    s2c
            } else {
                validate(need({file_ext(input$loadseq$name) == "txt" | 
                        file_ext(input$loadseq$name) == "fasta" |
                        file_ext(input$loadseq$name) == "gb"}, "File type not recognized. Please try again."))
            }
        }
        ## Determine whether input sequence in nucleotide or amino acid
        lang <- detect_language(dat)
        
        ## Calculate info for original sequence
        if (lang == "nuc"){
            info_dat <- calc_sequence_stats(dat, w)
            Ce_info_dat <- calc_sequence_stats(dat,Ce.w)
            
            ## Translate nucleotides to AA
            source('Server/translate_nucleotides.R', local = TRUE)
        } else if (lang == "AA") {
            AA_dat <- toupper(dat)
            info_dat <- list("GC" = NA, "CAI" = NA)
        } else if (lang == "error") {
            info_dat <- list("GC" = NA, "CAI" = NA)
            vals$cds_opt <- NULL
            return("Error: Input sequence contains unrecognized characters. 
                   Check to make sure it only includes characters representing
                   nucleotides or amino acids.")
        }
        
        ## Codon optimize back to nucleotides
        source('Server/codon_optimize.R', local = TRUE)
        
        ## Calculate info for optimized sequence
        info_opt <- calc_sequence_stats(opt, w)
        Ce_info_opt <- calc_sequence_stats(opt,Ce.w)
        
        vals$og_GC <- info_dat$GC
        vals$og_CAI <- info_dat$CAI
        vals$og_CeCAI <- Ce_info_dat$CAI
        vals$opt_GC <- info_opt$GC
        vals$opt_CAI <- info_opt$CAI
        vals$opt_CeCAI <- Ce_info_opt$CAI
        
        vals$cds_opt <- cds_opt
    })
    
    
    add_introns <- reactive({
        req(vals$cds_opt)
        cds_opt <- vals$cds_opt
        
        ## Detect insertion sites for artificial introns
        source('Server/locate_intron_sites.R', local = TRUE)
        
        ## Insert canonical artificial introns
        if (!is.na(loc_iS[[1]])){
            source('Server/insert_introns.R', local = TRUE)
        } else cds_wintrons <- c("Error: no intron insertion sites are 
                                 avaliable in this sequence")
        
        return(cds_wintrons)
    })
    
    ## Outputs: Optimization Mode ----
    ## Reactive run of function that generates optimized sequence without added artificial introns
    ## Can be assigned to an output slow
    output$optimizedSequence <- renderText({
        optimize_sequence()
    })
    
    ## Reactive run of function that generates optimized sequence with added artificial introns
    ## Can be assigned to an output slow
    output$intronic_opt <- renderText({
        if(as.numeric(input$num_Int) > 0){
            optimize_sequence()
            add_introns()
        }
    })
    
    ## Display optimized sequence with and wihout added artificial introns in a tabbed panel
    output$tabs <- renderUI({
        req(input$goButton)
        
        if (isTruthy(input$loadseq$name)) { 
            name <- file_path_sans_ext(input$loadseq$name)
        } else { name <- "SubmittedGene"}
        
        if (as.numeric(input$num_Int) > 0 && !is.null(vals$cds_opt)) {
            output$download_opt <- downloadHandler(
                filename = paste0(name,"_Optimized_NoIntrons.txt"),
                content = function(file){
                    write.table(paste0(vals$cds_opt,
                                       collapse = "")[[1]], 
                                file = file,
                                quote = FALSE,
                                row.names = FALSE,
                                col.names = FALSE)
                })
            
            output$download_intronic_opt <- downloadHandler(
                filename = paste0(name,"_Optimized_WithIntrons.txt"),
                content = function(file){
                    optimize_sequence()
                    tbl <- add_introns()
                    write.table(paste0(tbl, 
                                       collapse = ""), 
                                file = file,
                                quote = FALSE,
                                row.names = FALSE,
                                col.names = FALSE)
                })
            
            tabs <- list(
                tabPanel(title = h6("With Introns"), 
                         textOutput("intronic_opt", 
                                    container = div),
                         downloadButton("download_intronic_opt",
                                        "Download Sequence",
                                        class = "btn-primary")),
                tabPanel(title = h6("Without Introns"), 
                         textOutput("optimizedSequence", 
                                    container = div),
                         downloadButton("download_opt",
                                        "Download Sequence",
                                        class = "btn-primary"))
                
            )
        } else {
            output$download_opt <- downloadHandler(
                filename = paste0(name,"_Optimized_NoIntrons.txt"),
                content = function(file){
                    write.table(paste0(vals$cds_opt,
                                       collapse = ""), 
                                file = file,
                                quote = FALSE,
                                row.names = FALSE,
                                col.names = FALSE)
                })
            tabs <- list(
                tabPanel(title = h6("Without Introns"), 
                         textOutput("optimizedSequence", 
                                    container = div),
                         downloadButton("download_opt",
                                        "Download Sequence",
                                        class = "btn-primary")))
        }
        
        args <- c(tabs, list(id = "box", 
                             type = "tabs"
        ))
        
        
        do.call(tabsetPanel, args)
    })
    
    ## Make a reactive table containing calculated GC content and CAI values that can be assigned to an output slot
    output$info <- renderTable({
        tibble(Sequence = c("Original", "Optimized"),
               GC = c(vals$og_GC, vals$opt_GC),
               Sr_CAI =c(vals$og_CAI, vals$opt_CAI),
               Ce_CAI = c(vals$og_CeCAI, vals$opt_CeCAI))
    },
    striped = T,
    bordered = T)
    
    # Display Calculated Sequence Values (e.g. GC content, CAI indeces)
    output$seqinfo <- renderUI({
        req(input$goButton)
        
        args <- list(heading = tagList(h5(shiny::icon("fas fa-calculator"),
                                          "Sequence Info")), 
                     status = "primary",
                     tableOutput("info"))
        do.call(panel,args)
    })
    
    
    ## Analysis Mode ----
    source("Server/reset_state.R", local = TRUE)
    
    # Primary reactive element in the Analysis Mode
    analyze_sequence <- eventReactive(input$goAnalyze, {
        validate(
            need({isTruthy(input$idtext) | isTruthy(input$loadfile)}, "Please input geneIDs or sequences for analysis")
        )
        
        isolate({
            if (isTruthy(input$idtext)){
                # If user provides input using the textbox, 
                # assume they are provided a list of geneIDs
                genelist <- input$idtext %>%
                    gsub(" ", "", ., fixed = TRUE) %>%
                    str_split(pattern = ",") %>%
                    unlist() %>%
                    as_tibble_col(column_name = "geneID")
                info.gene.seq<-analyze_geneID_list(genelist, vals)

            } else if (isTruthy(input$loadfile)){
                file <- input$loadfile
                ext <- tools::file_ext(file$datapath)
                validate(need(ext == "csv" | ext == "fa", 
                              "Please upload a csv  or a .fa file"))
                
                if (tools::file_ext(input$loadfile$name) == "fa") {
                    # If user provides input using the file upload, &
                    # if it's a .fa file assume they are providing
                    # named cDNA sequences
                    dat <- suppressMessages(read.fasta(input$loadfile$datapath,
                                                       as.string = T,
                                                       set.attributes = F))
                    genelist <- dat %>%
                        as_tibble() %>%
                        pivot_longer(cols = everything(),
                                     names_to = "geneID", 
                                     values_to = "cDNA")
                    
                    info.gene.seq <- analyze_cDNA_list(genelist, vals)
                    
                } else if (tools::file_ext(input$loadfile$name) == "csv") {
                    # If user provides input using the file upload, &
                    # if it's a .csv file assume they either provided 
                    # a list of geneIDs, or 
                    # a 2 column matrix with geneID and cDNA sequence

                genelist <- suppressWarnings(read.csv(file$datapath, 
                                                      header = FALSE, 
                                                      colClasses = "character", 
                                                      strip.white = T)) %>%
                    as_tibble() 
                # Assume that an input with two columns and more than one 
                # row is a list of geneID/cDNA pairs
                if (ncol(genelist) == 2 & nrow(genelist) > 1) {
                    genelist <- genelist %>%
                        dplyr::rename(geneID = V1, cDNA = V2)
                    info.gene.seq <- analyze_cDNA_list(genelist,vals)
                
                #Assume every other input structure is a list of geneIDs 
                } else {
                    genelist <- genelist %>%
                        pivot_longer(cols = everything(), values_to = "geneID") %>%
                        dplyr::select(geneID)
                    info.gene.seq<-analyze_geneID_list(genelist, vals)
                    }
                } 
            }
            
        })
    })
    
    # Datatable of analysis values
    output$info_analysis <- renderDT({
        tbl<-analyze_sequence()
        info_analysis.DT <- tbl %>%
            DT::datatable(rownames = FALSE,
                          options = list(scrollY = '400px',
                                         scrollCollapse = TRUE,
                                         ordering = FALSE,
                                         paging = FALSE,
                                         dom = 'tS'))
        
        info_analysis.DT <- info_analysis.DT %>%
            DT::formatRound(columns = 2:4, digits = 2)
        
        info_analysis.DT
        
    }
    )
    
    ## Plot comparing, for each gene, Ce_CAI vs Sr_CAI
    output$cai_plot <- renderPlot({
        tbl<-analyze_sequence()
        
        # Generate summary statistics for the linear regression below
        linearMod <- lm(Sr_CAI ~ Ce_CAI, data = tbl) %>%
            summary() 
            
        vals$cai_plot <- ggplot(tbl, aes(Sr_CAI, Ce_CAI)) +
            geom_smooth(method=lm, color = "steelblue4", fill = "steelblue1",linetype = 2, size = 0.5, formula = "y ~ x") +
            geom_point(shape = 1, size = 3) +
            labs(title = "Species-specific codon adaptiveness",
                 subtitle = paste("Blue line/shading = linear regression \n",
                 "w/ 95% confidence regions (formula = y ~ x). \n",
                 "Adj R-squared =", 
                 round(linearMod$adj.r.squared,3) ,
                 "
                 "),
                     
                 x = "Codon bias relative to \n S. ratti usage rules (CAI)",
                 y = "Codon Bias relative to \n C. elegans usage rules (CAI)",
                 caption = "") +
            coord_equal() +
            theme_bw() +
            theme(plot.title.position = "plot",
                  plot.caption.position = "panel",
                  plot.title = element_text(face = "bold",
                                            size = 13, hjust = 0),
                  axis.title = element_text(size = 12),
                  axis.text = element_text(size = 10))
        vals$cai_plot
        
        
    }) 
    
    # Save CAI Plot
    output$download_CAI_plot <- downloadHandler(
        filename = function(){
            paste('CAIplot_', Sys.Date(),'.pdf', sep = "")
        },
        content = function(file){
            ggsave(file, plot = vals$cai_plot, 
                   width = 11, height = 8, 
                   units = "in", device = "pdf", 
                   useDingbats = FALSE)
        }
    )
    
    # Generate and Download report
    source("Server/excel_srv.R", local = TRUE)
    
    # Shiny output for analysis datatable
    output$analysisinfo <- renderUI({
        req(input$goAnalyze)
        args <- list(heading = tagList(h5(shiny::icon("fas fa-calculator"),
                                          "Sequence Info")), 
                     status = "primary",
                     DTOutput("info_analysis"),
                     downloadButton(
                         "generate_excel_report",
                         "Create Excel Report",
                         class = "btn-primary"
                     ))
        do.call(panel,args)
    })
    
    # Shiny output for CAI plot
    output$analysisplot<- renderUI({
        req(input$goAnalyze)
        args <- list(heading = tagList(h5(shiny::icon("fas fa-mountain"),
                                          "Analysis Plot")), 
                     status = "primary",
                     plotOutput('cai_plot'),
                     downloadButton("download_CAI_plot",
                                    "Download Plot as PDF",
                                    class = "btn-primary"))
        do.call(panel,args)
    })
    
    
    session$onSessionEnded(stopApp)
    
}
## --- end_of_chunk ---

## --- App ---
shinyApp(ui = ui, server = server)
## --- end_of_chunk ---