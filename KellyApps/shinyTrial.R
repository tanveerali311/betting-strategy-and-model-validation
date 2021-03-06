suppressPackageStartupMessages(library("BBmisc"))
suppressAll(library('plyr'))
suppressAll(library('stringr'))
suppressAll(library('tidyverse'))
suppressAll(library("shiny"))
suppressAll(library('shinyBS'))
suppressAll(library('shinyjs'))
suppressAll(library('shinythemes'))
suppressAll(library('highcharter'))
suppressAll(library('DT'))
suppressAll(library('quantmod'))
suppressAll(source("./function/selectFund.R"))
suppressAll(source("./function/compareKelly.R"))
suppressAll(source("./function/plotChart2.R"))

## This shinyApps test the highchart embed into shinyApp with application of shinyBS for datatable view.
## need to set the path if run independently.
#'@ getwd()
#'@ setwd()

fundsopt <<- list.files('./data1/', pattern = '.rds$')
fundsopt <<- c(tail(fundsopt, 1), fundsopt) %>% unique %>% str_replace_all('.rds', '')

##http://stackoverflow.com/questions/33020558/embed-iframe-inside-shiny-app
pages <<- list(
  'Natural Language Analysis' = 'http://rpubs.com/englianhu/natural-language-analysis', 
  'Part I' = 'https://englianhu.github.io/2016/09/Betting%20Strategy%20and%20Model%20Validation/Betting_Strategy_and_Model_Validation_-_Part_01.html', 
  'Part II' = 'http://rpubs.com/englianhu/208636', 
  'regressionApps' = 'https://beta.rstudioconnect.com/content/1807/')

#'@ BRSummary <<- read_rds(path = './data/BRSummary.rds')

#'@ load_data <<- function() {
#'@   Sys.sleep(2)
#'@   hide('loading-content')
#'@   show('app-content')
#'@ }

#'@ appCSS <- "
#'@ #loading-content {
#'@ position: absolute;
#'@ opacity: 0.9;
#'@ z-index: 100;
#'@ top: 0;
#'@ bottom: 0;
#'@ left: 0;
#'@ right: 0;
#'@ height: 100%;
#'@ text-align: center;
#'@ background: url(loader.gif) center no-repeat #fff;
#'@ }
#'@ "

ui <- fluidPage(
    shinythemes::themeSelector(),  # <--- Add this somewhere in the UI
    ## this is your web page header information
    tags$head(
      ## here you include your inline styles
      tags$style(HTML("
                      body {
                      Text color: yellow;
                      background-color: darkgoldenrod;
                      }
                      "))),
    #'@ tags$audio(src = 'sound.mp3', type = 'audio/mp3', autoplay = NA, controls = 'controls'), 
    useShinyjs(),
    #'@ inlineCSS(appCSS),
    
    #'@ div(id = 'loading-content'), 
    #'@ hidden(
      div(id = 'app-content', 
          h1('Highcharter Demo'),
          sidebarLayout(
            sidebarPanel(
              selectInput("funds", label = "Fund", width = "100%",
                          choices = fundsopt, 
                          selected = "SOFund"), 
              br(), 
              selectInput("type", label = "Type", width = "100%",
                          choices = c(FALSE, "line", "column", "spline", "bar", "pie"), 
                          selected = "line"), 
              selectInput("stacked", label = "Stacked",  width = "100%",
                          choices = c(FALSE, "normal", "percent"), 
                          selected = "normal"),
              selectInput("hc_theme", label = "Theme",  width = "100%",
                          choices = c("theme" = "hc_theme()", "538" = "hc_theme_538()", 
                                      "chalk" = "hc_theme_chalk()", 
                                      "darkunica" = "hc_theme_darkunica()", 
                                      "db" = "hc_theme_db()", 
                                      "economist" = "hc_theme_economist()",
                                      "flat" = "hc_theme_flat()", 
                                      "flatdark" = "hc_theme_flatdark()", 
                                      "ft" = "hc_theme_ft()", 
                                      "google" = "hc_theme_google()", 
                                      "gridlight" = "hc_theme_gridlight()", 
                                      "handdrwran" = "hc_theme_handdrawn()", 
                                      "merge" = "hc_theme_merge()", 
                                      "null" = "hc_theme_null()", 
                                      "sandsignika" = "hc_theme_sandsignika()",
                                      "smpl" = "hc_theme_smpl()", 
                                      "sparkline" = "hc_theme_sparkline()"), 
                          selected = "hc_theme_economist()"), 
              actionButton("tabBut", "View Table")),
            
            mainPanel(
              highchartOutput("hcontainer", height = "500px"),
              ## https://ebailey78.github.io/shinyBS/docs/Modals.html#components
              bsModal("modalExample", "Data Table", "tabBut", size = "large",
                      dataTableOutput("distTable"))))),#), 
    br(), 
    p('Powered by - Copyright® Intellectual Property Rights of ', 
      tags$a(href='http://www.scibrokes.com', target='_blank', 
             tags$img(height = '20px', alt='hot', #align='right', 
                      src='https://raw.githubusercontent.com/scibrokes/betting-strategy-and-model-validation/master/regressionApps/oda-army.jpg')), 
      HTML("<a href='http://www.scibrokes.com'>Scibrokes®</a>")))

server <- function(input, output) {
  
  #'@ load_data()
  
  ## Define a reactive expression for the document term matrix
  terms <- reactive({
    ## Change when the "update" button is pressed...
    input$funds
    ## ...but not for anything else
    isolate({
      withProgress({
        setProgress(message = "Processing graph...")
        selectFund(input$funds)
      })
    })
  })
  
  output$hcontainer <- renderHighchart({
    fund <- terms()$sfund
    plotChart2(fund, type = 'single', chart.type2 = input$type, 
               chart.theme = input$hc_theme, stacked = input$stacked)
    
  })
  
  output$distTable <- renderDataTable({
    fundDT <- terms()$sfundDT
    fundDT %>% datatable(
      caption = "Table 2.1.1 : Firm A Staking Data (in $0,000)", 
      escape = FALSE, filter = "top", rownames = FALSE, 
      extensions = list("ColReorder" = NULL, "RowReorder" = NULL, 
                        "Buttons" = NULL, "Responsive" = NULL), 
      options = list(dom = 'BRrltpi', autoWidth = TRUE, scrollX = TRUE, 
                     lengthMenu = list(c(10, 50, 100, -1), c('10', '50', '100', 'All')), 
                     ColReorder = TRUE, rowReorder = TRUE, 
                     buttons = list('copy', 'print', 
                                    list(extend = 'collection', 
                                         buttons = c('csv', 'excel', 'pdf'), 
                                         text = 'Download'), I('colvis'))))
    
  })#, options = list(pageLength = 10))
}

shinyApp(ui = ui, server = server)


