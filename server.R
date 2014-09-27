library(jsonlite)
library(rmarkdown)
library(shinyAce)

## TODO move "plugin" code to new files
## TODO beware excessive soft-coding

tinsel.server <- quote({
    default.control <- function() { fromJSON('{ worksheets: [ { cells: [ ], metadata: {} } ], metadata: {} }') }
    
    magpie.control <- reactive({
        ## Initialize the magpie control structure, 

        query <- parseQueryString(session$clientData$url_search)
        
        if (is.null(query$url))
            return(default.control())

        control <- fromJSON(query$url, simplifyVector = FALSE)

        ##control$metadata$source_url <- query$url
        ##control$metadata$work_dir <- getwd()
        
        return(control)
    })

    ## Process the magpie control structure.
    observe({
        control <- magpie.control()

        ## Process the first worksheet's cells into a markdown
        ## document. The `input` in code cells is wrapped in a
        ## markdown code block, and the `source` in other cells is
        ## printed verbatim.

        worksheet <- control$worksheets[[1]]

        cell_inputs <- sapply(worksheet$cells, function(cell) {
            if (cell$cell_type == 'code') {
                return(c(sprintf('```{%s echo=%s}\n', cell$language, 'TRUE'),
                                 cell$input,
                                 '```\n'))
            } else if (cell$cell_type == 'heading') {
                return(c(sprintf('%s %s\n',
                                 paste0(rep('#', as.integer(cell$level)), collapse = ''),
                                 cell$source)))
            } else {
                return(cell$source)
            }
        })
        
        ## TODO handle missing parameters or connection errors
        ## TODO tinsel shouldn't know about knitr; write to something else
        isolate(updateAceEditor(session, 'knitrNotebook', value = paste0(unlist(cell_inputs), collapse = '')))
    })
    
    ## Render the magpie control structure for debugging.
    output$magpieControl <- renderUI({
        pre(style = 'font-size: x-small;', toJSON(magpie.control(), auto_unbox = TRUE, pretty = TRUE))
    })
})

## The knitr plugin presents the user with an interactive R notebook
## that's already been set up for them to do fun things with their
## data.

render.fragment <- function(text) {
    src.file <- tempfile(fileext = ".Rmd")
    writeLines(text, src.file)

    fragment.file <- rmarkdown::render(src.file,
                                       envir = new.env(),
                                       output_format = 'html_fragment',
                                       runtime = 'static',
                                       quiet = TRUE)
    return(paste0(readLines(fragment.file), collapse = '\n'))
}

knitr.server <- quote({
    ## knitr reacts when the notebook's action button is pressed by
    ## grabbing the notebook's contents and rendering it.
    ## TODO read the notebook's contents from a pipe instead
    output$knitrOut <- renderUI({
        input$knitrRefresh
        isolate(HTML(render.fragment(input$knitrNotebook)))
    })

    output$knitrDownload <- downloadHandler(
        filename = 'magpie-document.html',
        content = function(file) {
            src.file <- tempfile(fileext = ".Rmd")
            writeLines(input$knitrNotebook, src.file)

            rmarkdown::render(src.file,
                              envir = new.env(),
                              output_format = 'html_document',
                              output_file = file,
                              runtime = 'static',
                              quiet = TRUE)
        }
    )

    ## knitr also switches the active tab in the UI when the
    ## notebook's action button is pressed.
    observe({
        input$knitrRefresh
        isolate(updateTabsetPanel(session, 'magpieTabs', selected = 'knitr'))
    })
})

## Having most of the server logic offloaded to plugins makes for a
## terse call to shinyServer :)

shinyServer(function(input, output, session) {
    ## eval the plugins
    ## TODO we should lapply(server(plugins), eval) or something
    eval(tinsel.server)
    eval(knitr.server)
})
