# Header ----
navbarPage(h3("Wild Worm Codon Adapter"),
           windowTitle = "WWCA",
           theme = shinytheme("flatly"),
           collapsible = TRUE,
           id = "tab",
           
           
           # Optimize Sequence Mode Tab ----
           tabPanel(h4("Optimize Sequences"),
                    value = "optimization",
                    fluidRow(
                        column(width = 3,
                               panel(
                                   heading = tagList(h5(shiny::icon("fas fa-sliders-h"),"Inputs & Options")),
                                   
                                   status = "primary",
                                   
                                   ### Option to pick what species the sequence will be codon optimized for
                                   h5('Select Optimization Rule', class = 'text-danger', style = "margin: 0px 0px 5px 0px"),
                                   p(tags$em('Select the codon usage pattern to apply.', style = "color: #7b8a8b")),
                                   selectInput('sp_Opt',
                                               h6('Built-in Rules'),
                                               choices = list("Strongyloides",
                                                              "Nippostrongylus",
                                                           "Pristionchus",
                                                           "Brugia"),
                                               selected = "Strongyloides"),
                                   
                                   ### Upload custom optimal codon table
                                   uiOutput('custom_lut_upload'),
                                   p(tags$em('Note: uploading a custom list of optimal codons will override the dropdown menu selection above. Please use the Clear button if switching between custom and built-in usage rules.', style = "color: #7b8a8b")),
                                   
                                   h5('Add Sequence', class = 'text-danger', style = "margin: 0px 0px 5px 0px"),
                                   p(tags$em('Please input a cDNA or single-letter amino acid sequence for optimization. Alternatively, upload a gene sequence file (.gb, .fasta, or .txt files accepted).', style = "color: #7b8a8b")),
                                   p(tags$em(tags$b('Note: Please hit the Clear button if switching between typing and uploading inputs.', style = "color: #F39C12"))),
                                   
                                   ### Sequence (text box)
                                   textAreaInput('seqtext',
                                                 h6('Sequence (DNA or AA)'),
                                                 rows = 5,
                                                 resize = "vertical"),
                                   
                                   ### Upload list of sequences
                                   uiOutput('optimization_file_upload'),
                                   
                                   h5('Pick Intron Options', class = 'text-danger', style = "margin: 0px 0px 5px 0px"),
                                   p(tags$em('Users may choose between three sets of intron sequences, the canonical Fire lab set, PATC-rich introns, or native Pristionchus pacificus intron sequences', style = "color: #7b8a8b")),
                                   
                                   ### Option to pick intron sequences (pulldown)
                                   selectInput('type_Int',
                                               h6('Sequence Source'),
                                               choices = list("Canonical (Fire lab)",
                                                              "PATC-rich",
                                                           "Pristionchus"),
                                               selected = "Canonical (Fire lab)"),
                                   
                                   ### Option to add introns (pulldown)
                                   selectInput('num_Int',
                                               h6('Number of Introns'),
                                               choices = 0:3,
                                               selected = 3),
                                   
                                   actionButton('goButton',
                                                'Submit',
                                                #width = '40%',
                                                class = "btn-primary",
                                                icon = icon("fas fa-share")),
                                   
                                   actionButton('resetOptimization', 'Clear',
                                                icon = icon("far fa-trash-alt"))
                               )
                               
                               
                        ),
                        
                        column(width = 9,
                               conditionalPanel(condition = "input.goButton",
                                                panel(heading = tagList(h5(shiny::icon("fas fa-dna"),
                                                                           "Optimized Sequences")),
                                                      status = "primary",
                                                      uiOutput("tabs"))
                               )),
                        
                        column(width = 4,
                               uiOutput("seqinfo")
                        )
                        
                        
                    )
           ),
           # Analysis Mode Tab ---- 
           tabPanel(h4("Analyze Sequences"),
                    value = "analysis",
                    fluidRow(
                        column(width = 3,
                               panel(heading = tagList(h5(shiny::icon("fas fa-sliders-h"),"Inputs & Options")),
                                     width = NULL,
                                     status = "primary",
                                     ## GeneID Upload
                                     h5('Analyze Transgene', class = 'text-danger', style = "margin: 0px 0px 5px 0px"),
                                     p(tags$em('To measure the codon bias of an individual transgene, supply the cDNA sequence.', style = "color: #7b8a8b")),
                                      ### Sequence direct input
                                     textAreaInput('cDNAtext',
                                                   h6('Transgene sequence'),
                                                   rows = 2, 
                                                   resize = "vertical"),
                                     
                                     h5('Analyze Native Sequences', class = 'text-danger', style = "margin: 5px 0px 5px 0px"),
                                     p(tags$em('To perform analysis of native cDNA sequences, list sequence IDs as: gene or transcript IDs starting with SSTP, SRAE, SPAL, or SVEN; WB gene IDs for S. ratti and C. elegans genes; C. elegans gene names with a "Ce-" prefix (e.g. Ce-ttx-1); or C. elegans transcript IDs. For individual analyses use textbox input; for bulk analysis upload gene/transcript IDs as a single-column .csv file. If using the text box, please separate search terms by a comma.', style = "color: #7b8a8b")),
                                     
                                     p(tags$em('Alternatively, users may directly provide cDNA sequences for analysis, either as a 2-column .csv file listing sequence names and cDNA sequences, or a .fa file containing named cDNA sequences.', style = "color: #7b8a8b")),
                                     p(tags$em('Example .csv files can be downloaded using the Data Availability panel in the About tab', style = "color: #7b8a8b")),
                                     p(tags$em(tags$b('Note: Please hit the Clear button if switching between typing and uploading inputs.', style = "color: #F39C12"))),
                                     
                                     ### GeneID (text box)
                                     textAreaInput('idtext',
                                                   h6('Gene/Transcript IDs'),
                                                   rows = 2, 
                                                   resize = "vertical"),

                                     uiOutput('analysis_file_upload'),
                                     
                                     actionButton('goAnalyze',
                                                  'Submit',
                                                  # width = '40%',
                                                  class = "btn-primary",
                                                  icon = icon("fas fa-share")),
                                     
                                     actionButton('resetAnalysis', 'Clear',
                                                  icon = icon("far fa-trash-alt"))
                                     
                               )
                        ),
                        column(width = 6, 
                               conditionalPanel(condition = "input.goAnalyze",
                                                panel(heading = tagList(h5(shiny::icon("fas fa-calculator"),
                                                                           "Sequence Info")),
                                                      status = "primary",
                                                      DTOutput("info_analysis")
                                                      )
                               )
                        ),
                        column(width = 3,
                               conditionalPanel(condition ="input.goAnalyze != 0 && output.info_analysis",
                                                panel(heading = tagList(h5(shiny::icon("fas fa-file-download"),
                                                                           "Download Options")),
                                                      status = "primary",
                                                      prettyCheckboxGroup("download_options",
                                                                          'Select Values to Download',
                                                                    status = "default",
                                                                    icon = icon("check"),
                                                                    choiceNames = c("GC ratio",
                                                                    "Sr_CAI values",
                                                                    "Ce_CAI values",
                                                                    "Bm_CAI values",
                                                                    "Nb_CAI values",
                                                                    "cDNA sequences"
                                                                    ),
                                                                    choiceValues = c("GC",
                                                                                     "Sr_CAI",
                                                                                     "Ce_CAI",
                                                                                     "Bm_CAI",
                                                                                     "Nb_CAI",
                                                                                     "cDNA sequence"),
                                                                    selected =  c("GC",
                                                                                  "Sr_CAI",
                                                                                  "Ce_CAI",
                                                                                  "Bm_CAI",
                                                                                  "Nb_CAI",
                                                                                  "cDNA sequence")),
                                                      uiOutput("downloadbutton_AM")
                                                      ))
                        
                        )
                    )
           ),
           ## About Tab ----
           tabPanel(h4("About"),
                    value = "about",
                    fluidRow(
                        column(12,
                               panel(heading =  tagList(h5(shiny::icon("fas fa-question-circle"),
                                                           "App Overview")),
                                     status = "primary",
                                     id = "About_Overview",
                                     includeMarkdown('UI/README/README_Features.md')
                               )
                        )),
                    fluidRow(
                        column(8,
                               panel(heading =  tagList(h5(shiny::icon("fas fa-chart-line"),
                                                           "Optimization Methods")),
                                     status = "primary",
                                     id = "About_Analysis_Methods",
                                     tabsetPanel(
                                         type = "pills",
                                         
                                         tabPanel(
                                             title = "Codon Adaptation Index",
                                             includeMarkdown('UI/README/README_Methods_CAI.md')
                                         ),
                                         tabPanel(
                                             title = "GC Ratio",
                                             includeMarkdown('UI/README/README_Methods_GC.md')
                                         ),
                                         tabPanel(
                                             title = "Artificial Introns",
                                             includeMarkdown('UI/README/README_Methods_Introns.md')
                                         )
                                     )
                               )
                        ),
                        column(4,
                               panel(heading =  tagList(h5(shiny::icon("fas fa-cloud-download-alt"),
                                                           "Data Availability")),
                                     status = "primary",
                                     p('The following datasets used can be
        downloaded using the dropdown menu and download button below:',
                                       tags$ol(
                                           tags$li('Multi-species codon frequency/relative adaptiveness table (.csv)'),
                                           tags$li('Multi-species optimal codon lookup table (.csv)'),
                                           tags$li('Example custom preferred codon table (.csv)'),
                                           tags$li('Example geneID List (.csv)'),
                                           tags$li('Example 2-column geneID/cDNA List (.csv)')
                                       )),
                                     
                                     pickerInput("which.Info.About",
                                                 NULL, 
                                                 choices =  c('Multi-species codon frequency table',
                                                              "Multi-species optimal codon table",
                                                              "Example custom preferred codon table",
                                                              "Example geneID List",
                                                              "Example 2-column geneID/cDNA List"),
                                                 options = list(style = 'btn btn-primary',
                                                                title = "Select a file to download")),
                                     uiOutput("StudyInfo.panel.About")
                                     
                               )
                        ),
                        column(4,
                               ## App Credits ----
                               panel( heading =  tagList(h5(shiny::icon("fas fa-drafting-compass"),
                                                            "Authors")),
                                      
                                      status = "primary",
                                      p('This app was created by', 
                                        tags$a(
                                            href = "https://scholar.google.com/citations?user=uSGqqakAAAAJ&hl=en", 
                                            'Astra S. Bryant, PhD'),'for the', 
                                        tags$a(href="http://www.hallemlab.com/",'Hallem Lab'), 'at UCLA.', 
                                        tags$br(),
                                        tags$br(),
                                        'The source code for this app is available on GitHub:', 
                                        tags$a(
                                            href = "https://github.com/HallemLab/Wild_Worm_Codon_Adapter", 
                                            'https://github.com/HallemLab/Wild_Worm_Codon_Adapter', target = "blank"),
                                        tags$br(),
                                        tags$br(),
                                        'The source code for data preprocessing steps is also available on GitHub:',
                                        tags$a(
                                            href = "https://github.com/HallemLab/Bryant-and-Hallem-2021", 
                                            'https://github.com/HallemLab/Bryant-and-Hallem-2021', target = "blank")
                                      ))
                        )
                    )
           )
           
)



