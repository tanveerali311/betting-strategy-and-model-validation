plotChart2 <- function(Fund, type = 'multiple', event = NULL, event.dates = NULL, 
                       chart.type = NULL, chart.type2 = FALSE, 
                       chart.theme = 'hc_theme_economist()', stacked = FALSE) {
  ## http://jkunst.com/highcharter/highstock.html
  ## type = 'single' or type = 'multiple'. Plot comparison graph or single fund details.
  ## chart.type = 'Op', chart.type = 'Hi', chart.type = 'Lo', chart.type = 'Cl'. Use 
  ##   what kind of fund size to plot for multiple funds comparison.
  ## --------------------- Load packages ------------------------------------------
  suppressMessages(library('formattable'))
  suppressMessages(library('quantmod'))
  suppressMessages(library('highcharter'))
  suppressMessages(library('tidyverse'))
  
  ## --------------------- Data validation ------------------------------------------
  ## check chart.theme
  hctheme <- c('hc_theme()', 'hc_theme_538()', 'hc_theme_chalk()', 'hc_theme_darkunica()' , 
               'hc_theme_db()', 'hc_theme_economist()', 'hc_theme_flat()', 
               'hc_theme_flatdark()', 'hc_theme_ft()', 'hc_theme_google()', 
               'hc_theme_gridlight()', 'hc_theme_handdrawn()', 'hc_theme_merge()', 
               'hc_theme_null()', 'hc_theme_sandsignika()', 'hc_theme_smpl()', 
               'hc_theme_sparkline()')
  
  if(!chart.theme %in% hctheme) {
    stop('Kindly choose one theme among ', paste(hctheme, collapse = ', '), '.')
  } else {
    chart.theme <- chart.theme
  }
  
  ## check chart.type2
  hcchart <- c(FALSE, 'line', 'column', 'bar', 'spline', 'pie')
  
  if(!chart.type2 %in% hcchart) {
    stop('Kindly choose one chart type among ', paste(hcchart, collapse = ', '), '.')
  } else {
    if(chart.type2 == FALSE) {
      plotch <- highchart()
    } else {
      plotch <- highchart() %>% hc_chart(type = chart.type2)
    }
  }
  
  ## check stacked
  hcstacked <- c(FALSE, 'normal', 'percent')
  
  if(!stacked %in% hcstacked) {
    stop('Kindly choose one stacked among ', paste(hcstacked, collapse = ', '), '.')
  } else {
    stacked <- stacked
  }
  
  if(type == 'single') {
    ## --------------------- Plot single fund or sub funds ------------------------
    ## single model details, volume, moving average and daily open, high, low, close.
    FUND.SMA.10  <- SMA(Cl(Fund), n = 10)
    FUND.SMA.200 <- SMA(Cl(Fund), n = 200)
    FUND.RSI.14  <- RSI(Cl(Fund), n = 14)
    FUND.RSI.SellLevel <- xts(rep(70, NROW(Fund)), index(Fund))
    FUND.RSI.BuyLevel  <- xts(rep(30, NROW(Fund)), index(Fund))
    
    initial <- Op(Fund)[1, ] %>% unique %>% currency
    
    fname <- names(Op(Fund)) %>% str_replace_all('.Open', '')
    #'@ fname <- grep('.Open', names(Op(Fund)), value = TRUE) %>% 
    #'@   str_split_fixed('\\.', 2) %>% .[, 1]
    #'@ if(('$' %in% paste0(substitute(Fund))) & (length(paste0(substitute(Fund))) > 1)) {
    #'@   fname <- str_split(paste0(substitute(Fund))[2:3], '\\$') %>% 
    #'@     unlist %>% .[2:3] %>% paste0(collapse = '.')
    #'@   
    #'@ } else if((!'$' %in% paste0(substitute(Fund))) & (length(paste0(substitute(Fund))) == 1)) {
    #'@   fname <- grep('.Open', names(Op(Fund)), value = TRUE) %>% 
    #'@     str_split_fixed('\\.', 2) %>% .[, 1]
    #'@   
    #'@ } else {
    #'@   fname <- 'Fund'
    #'@ }
    
    plotc <- plotch %>% #highchart() %>% hc_chart(type = chart.type2) %>% 
      hc_title(text = "Sportsbook Hedge Fund") %>% 
      hc_subtitle(text = paste0("Candle stick chart with initial fund size : ", 
                                paste0(initial, collapse = ', '))) %>% 
      # create axis :)
      hc_yAxis_multiples(
        list(title = list(text = NULL), height = '45%', top = '0%'),
        list(title = list(text = NULL), height = '25%', top = '47.5%', opposite = TRUE),
        list(title = list(text = NULL), height = '25%', top = '75%')) %>% 
      hc_plotOptions(
        series = list(showInLegend = TRUE)) %>% 
      # series :D
      hc_add_series_ohlc(Fund, yAxis = 0, name = fname) %>% 
      hc_add_series_xts(FUND.SMA.10,  yAxis = 0, name = 'Fast MA') %>% 
      hc_add_series_xts(FUND.SMA.200, yAxis = 0, name = 'Slow MA') %>% 
      hc_add_series_xts(Fund[,names(Vo(Fund))], color = 'gray', yAxis = 1, name = 'Volume', 
                        type = 'column') %>% 
      hc_add_series_xts(FUND.RSI.14, yAxis = 2, name = 'Osciallator') %>% 
      hc_add_series_xts(FUND.RSI.SellLevel, color = 'red', yAxis = 2, 
                        name = 'Sell level', enableMouseTracking = FALSE) %>% 
      hc_add_series_xts(FUND.RSI.BuyLevel, color = 'blue', yAxis = 2, 
                        name = 'Buy level', enableMouseTracking = FALSE)
    
    # I <3 themes
    htc <- paste0('hc <- plotc %>% hc_add_theme(', chart.theme, 
                  '); if (stacked != FALSE) { ', 
                  'plotc <- plotc %>% ', 
                  'hc_plotOptions(showInLegend = TRUE, dataLabels = FALSE)}; hc')
    
    return(eval(parse(text = htc)))
    
  } else if(type == 'multiple') {
    ## --------------------- Plot multiple funds or main funds ------------------
    ## put remarks on big gap within highest and lowest within a day.
    #'@ event <- Hi(Fund) - Lo(Fund) # need to modify...
    # single chart high-low candle stick might need to 
    # label the reason and event to cause a hight volatility.
    
    chart.type <- ifelse(is.null(chart.type), 'Cl', chart.type)
    initial <- Op(Fund)[1, ] %>% unique %>% currency
    
    fname <- grep('.Open', names(Op(Kbase)), value = TRUE) %>% 
      str_split('\\.') %>% llply(., function(x) 
        paste0(str_replace_all(x, 'Open', '')[1:2], collapse = '.')) %>% unlist
    
    ## comparison of fund size and growth of various Kelly models
    #'@ event <- c('netEMEdge', 'PropHKPriceEdge', 'PropnetProbBEdge', 'KProbHKPrice',
    #'@              'KProbnetProbB', 'KProbFixed', 'KProbFixednetProbB', 'KEMProb',
    #'@              'KEMProbnetProbB', 'KProbHalf','KProbHalfnetProbB', 'KProbQuarter',
    #'@              'KProbQuarternetProbB', 'KProbAdj','KProbAdjnetProbB', 'KHalfAdj',
    #'@              'KHalfAdjnetProbB', 'KEMQuarterAdj', 'KEMQuarterAdjnetProbB')
    
    ## add dates for event...
    ##   label the high volatility daily event.
    if(is.null(event.dates)) {
      event.dates <- as.Date(period.apply(
        diff(Op(Fund)), INDEX = endpoints(Fund), FUN = max) %>% data.frame %>% 
          rownames, format = '%Y-%m-%d')
    } else {
      event.dates <- as.Date(event.dates)
    }
    
    ## id of event label, event text
    id <- seq(length(event.dates))
    
    if(is.null(event)) {
      event <- id
    } else {
      event <- event
    }
    
    if(length(event) == length(event.dates)) {
      event <- event
      event.dates <- event.dates
    } else {
      stop('The vector length of event must be same with vector length of event.dates.')
    }
    
    if(chart.type == 'Op') {
      Fund <- Op(Fund)
    } else if(chart.type == 'Hi') {
      Fund <- Hi(Fund)
    } else if(chart.type == 'Lo') {
      Fund <- Lo(Fund)
    } else if(chart.type == 'Cl') {
      Fund <- Cl(Fund)
    } else {
      stop('Kindly choose chart.type = "Op", chart.type = "Hi", chart.type = "Lo", chart.type = "Cl".')
    }
    
    #'@ plotc <- highchart(type = "stock") %>% 
    #'@   hc_title(text = "Sportsbook Hedge Fund") %>% 
    #'@   hc_subtitle(text = paste0("Multiple funds trend chart initial fund size : ", 
    #'@                            paste0(initial, collapse = ', '))) %>% 
    #'@   hc_add_series_xts(Fund[, 1], id = names(Fund)[1]) %>% 
    #'@   hc_add_series_xts(Fund[, 2], id = names(Fund)[2]) %>% 
    #'@   hc_add_series_xts(Fund[, 3], id = names(Fund)[3]) %>% 
    #'@   hc_add_series_xts(Fund[, 4], id = names(Fund)[4]) %>% 
    #'@   hc_add_series_xts(Fund[, 5], id = names(Fund)[5]) %>% 
    #'@   hc_add_series_xts(Fund[, 6], id = names(Fund)[6]) %>% 
    #'@   hc_add_series_xts(Fund[, 7], id = names(Fund)[7]) %>% 
    #'@   hc_add_series_xts(Fund[, 8], id = names(Fund)[8]) %>% 
    #'@   hc_add_series_xts(Fund[, 9], id = names(Fund)[9]) %>% 
    #'@   hc_add_series_xts(Fund[,10], id = names(Fund)[10]) %>% 
    #'@   hc_add_series_xts(Fund[,11], id = names(Fund)[11]) %>% 
    #'@   hc_add_series_xts(Fund[,12], id = names(Fund)[12]) %>% 
    #'@   hc_add_series_xts(Fund[,13], id = names(Fund)[13]) %>% 
    #'@   hc_add_series_xts(Fund[,14], id = names(Fund)[14]) %>% 
    #'@   hc_add_series_xts(Fund[,15], id = names(Fund)[15]) %>% 
    #'@   hc_add_series_xts(Fund[,16], id = names(Fund)[16]) %>% 
    #'@   hc_add_series_xts(Fund[,17], id = names(Fund)[17]) %>% 
    #'@   hc_add_series_xts(Fund[,18], id = names(Fund)[18]) %>% 
    #'@   hc_add_series_xts(Fund[,19], id = names(Fund)[19]) %>% 
    
    ## add event remarks onto the chart.
    #'@  hc_add_series_flags(event.dates, title = paste0('E', event), #label of the event box
    #'@                      text = paste('Event : High volatility ', event), id = id) %>% #text inside the event box
    #'@  hc_add_theme(hc_theme_flat())
    
    #'@ plotc <- paste0(
    #'@   'highchart(type = \'stock\') %>% ', 
    #'@   'hc_title(text = \'Sportsbook Hedge Fund\') %>% ', 
    #'@   'hc_subtitle(text = paste(\'Multiple funds trend chart initial fund size : \', initial)) %>% ', 
    #'@   paste0('hc_add_series_xts(Fund[,', subnum, '], id = fname[', subnum,'])', collapse = '%>%'), 
    #'@   ' %>% hc_add_series_flags(event.dates, title = paste0(\'E\', event), text = paste(\'Event : High volatility \', event), id = id) %>% hc_add_theme(hc_theme_flat());')
    
    plotc <- paste0(
      'highchart(type = \'stock\') %>% ', 
      'hc_title(text = \'Sportsbook Hedge Fund\') %>% ', 
      'hc_subtitle(text = paste0(\'Multiple funds trend chart initial fund size : \', paste0(initial, collapse = \', \'))) %>% ', 
      paste0('hc_add_series_xts(Fund[,', seq(fname), '], name = \'', fname,'\', id = \'', fname, '\')', collapse = ' %>% '), 
      ' %>% hc_add_series_flags(event.dates, title = paste0(\'E\', event), text = paste(\'Event : High volatility \', event), id = id) %>% hc_add_theme(hc_theme_flat());')
    
    return(eval(parse(text = plotc)))
    
  } else {
    stop('Kindly choose type = "single" or type = "multiple" if you choose chart = TRUE.')
  }
}
