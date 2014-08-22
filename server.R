library(knitr)
library(jsonlite)
library(shinyAce)

## TODO move "plugin" code to new files
## TODO beware excessive soft-coding

tinsel.server <- quote({
    default.control <- function() { fromJSON('{ metadata: {}, cells: [ ] }') }
    
    magpie.control <- reactive({
        query <- parseQueryString(session$clientData$url_search)
        
        if (is.null(query$url))
            return(default.control())
        
        control.json <- paste(readLines(con = url(query$url)), collapse = '\n')
        control <- fromJSON(control.json)
        return(control)
    })
    
    ## Process the magpie control structure.
    observe({
        control <- magpie.control()
        
        ## Discard everything but the code cells, concatenate them,
        ## and wrap them in an rmarkdown code block.
        
        code.cells <- subset(control$cells, cell_type == 'code' && language == 'r')
        code <- c('```{r echo=TRUE}\n', code.cells$input, '```\n')
        
        ## TODO handle missing parameters or connection errors
        ## TODO tinsel shouldn't know about knitr; write to a pipe instead
        ## TODO isolate()
        updateAceEditor(session, 'knitrNotebook', value = paste(code, collapse = '\n'))
    })
    
    ## Render the magpie control structure for debugging.
    output$magpieControl <- renderUI({
        pre(style = 'font-size: x-small;', toJSON(magpie.control(), pretty = TRUE))
    })
})

## The knitr plugin presents the user with an interactive R notebook
## that's already been set up for them to do fun things with their
## data.

knitr.server <- quote({
    ## knitr reacts when the notebook's action button is pressed by
    ## grabbing the notebook's contents and rendering it.
    ## TODO read the notebook's contents from a pipe instead
    output$knitrOut <- renderUI({
        input$knitrRefresh
        isolate(HTML(knit2html(text = input$knitrNotebook, fragment.only = TRUE, quiet = TRUE)))
    })

    ## knitr also switches the active tab in the UI when the
    ## notebook's action button is pressed.
    observe({
        input$knitrRefresh
        updateTabsetPanel(session, 'magpieTabs', selected = 'knitr')
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
