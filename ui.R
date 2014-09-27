library(shinyAce)

## Display the magpie control structure for debugging.
tinsel.ui.control <- quote({ tabPanel('control.json', uiOutput('magpieControl')) })

## The knitr plugin creates two tabs, one for the source notebook and
## one for the rendered output.

## TODO figure out how to get multiple tabPanels out of one expression
knitr.ui.notebook <- quote({
    tabPanel('notebook',
             aceEditor('knitrNotebook', mode = 'markdown', value = ''),
             actionButton('knitrRefresh', 'Re-knit', icon('refresh')),
             downloadLink('sourceDownload', 'Download source')
             )
})

knitr.ui.output <- quote({
    tabPanel('knitr',
             uiOutput('knitrOut'),
             downloadLink('knitrDownload', 'Download')
             )
})

## Set up magpie boilerplate and inject plugins where appropriate.
## TODO plugins should include their own dependencies (js, css, etc)
shinyUI(fluidPage(
    withTags(head(
        title('magpie'),
        link(rel = 'stylesheet', type = 'text/css', href = 'css/magpie.css'),
        ##script(src = 'http://ajaxorg.github.io/ace/build/src-min-noconflict/ace.js'),
        script(src = 'js/magpie.js')
    )),
    tags$body(
        sidebarLayout(
            sidebarPanel(id = 'sidebar',
                         fluidRow(img(id = 'logo', src = 'img/magpie-64x64.png')),
                         wellPanel(id = 'consoleLog', p(id = 'consoleTitle', '# console log'))
                         ),    
            mainPanel(
                tabsetPanel(id = 'magpieTabs',
                            ## TODO should lapply(ui(plugins), eval) or something
                            eval(knitr.ui.notebook),
                            eval(knitr.ui.output),
                            eval(tinsel.ui.control)
                            )
            )
        )
    )
))
