simulateKelly <- function(mbase, lPmean = 'runif', type = 'vKelly', Kelly.type = 'flat', 
                          weight.stakes = 1, weight = 1, maxit = 100, parallel = FALSE) {
  ## Comparison of various fractional Kelly models
  ## mbase = a converted data frame by using readfirmData() and arrfirmData()s.
  ## type = 'flat', 'weight' or 'dynamic' for static or dynamic which is simulate the process 
  ##   to get the optimal weight  parameter.
  ## weight.stakes = a numeric weight parameter in single or vector format. Manual weight 
  ##   only work on 'flat' type.
  ## weight = a numeric weight parameter in single or vector format. Manual weight only work 
  ##   on 'flat' type.
  ## maxit = maximum iteration for the dynamic process. Only work on 'dynamic' type.
  ##   Once choose 'dynamic'.
  ## Kelly.type = 'flat' : both 'weight.stakes' and 'weight' will only usable for 'flat' type.
  ## Kelly.type = 'weight' : Once you choose Kelly.type = 'weight', both 'weight.stakes' and 
  ##   'weight' will auto ignore all input value but using previous year data to get a constant 
  ##   weight parameter.
  ## Kelly.type = 'dynamic' : Once you choose 'dynamic' type, both 'weight.stakes' and 'weight' 
  ##   will auto ignore all input value but using data from previous until latest staked 
  ##   match to generates a vector of weighted parameters.
  ## type = 'vKelly' or type = 'vKelly2' in order to simulate the vKelly() or vKelly2(). By 
  ##   the way, please select if the mean value of the league risk profile resampling by 
  ##   `runif` of `rnorm`.
  ## lPmean = 'runif' or lPmean = 'rnorm'.
  ## truncated.scores = 'option1' until truncated.scores = 'option7' which will simulate the 
  ##   soccer scores result for Kelly model proceed further and eventaully get the P&L from 
  ##   investment.
  ## --------------------- Load Packages -------------------------------- 
  suppressMessages(source('./function/rScores.R', local = TRUE))
  
  ## --------------------- Data validation -------------------------------- 
  if(!is.data.frame(mbase)) stop('Kindly apply the readfirmData() and arrfirmData() 
                                 in order to turn the data into a fittable data frame.')
  
  if(!is.data.frame(leagueProf)) stop('Kindly insert a data frame of league risk profile which list the min, median, sd and max stakes.')
  if(!is.logical(parallel)) parallel <- as.logical(as.numeric(parallel))
  
  if(type != 'flat' & type != 'weight' & type != 'dynamic1') {
    
    stop('Kindly choose "flat", "weight" or "dynamic" for parameter named "type". You can choose 
         fit the "weight" parameter controller for both models.')
    
  } else {
    if(type == 'dynamic') {
      
      wt <- data_frame(No = seq(nrow(mbase)))
      
      if(is.null(weight.stakes)) {
        wt$weight.stakes <- 1
      } else {
        if(!is.vector(weight.stakes)) {
          stop('Kindly insert a range of vector or single numeric value as weight.stakes parameter.')
        } else {
          if(is.vector(weight.stakes)) wt$weight.stakes <- weight.stakes
        }
      }
      
      if(is.null(weight)) {
        wt$weight <- 1
      } else {
        if(!is.vector(weight)) {
          stop('Kindly insert a range of vector or single numeric value as weight parameter.')
        } else {
          if(is.vector(weight)) wt$weight <- weight
        }
      }
      
      if(is.null(maxit)) {
        maxit <- 1
      } else {
        if(!is.numeric(maxit)) {
          stop('Kindly insert a numeric value as maximum iteration parameter.')
        } else {
        maxit <- maxit
        }
      }
    } else {
      wt <- data_frame(No = seq(nrow(mbase)))
      
      if(is.null(weight.stakes)) {
        wt$weight.stakes <- 1
      } else {
        if(!is.vector(weight.stakes)) {
          stop('Kindly insert a range of vector or single numeric value as weight.stakes parameter.')
        } else {
          if(is.vector(weight.stakes)) wt$weight.stakes <- weight.stakes
        }
      }
      
      if(is.null(weight)) {
        wt$weight <- 1
      } else {
        if(!is.vector(weight)) {
          stop('Kindly insert a range of vector or single numeric value as weight parameter.')
        } else {
          if(is.vector(weight)) wt$weight <- weight
        }
      }
      
      if(is.null(maxit)) {
        maxit <- 1
      } else {
        if(!is.vector(maxit)) stop('Kindly insert a range of vector or single numeric value as maximum iteration parameter.')
      }
    }
  }
  
  if(type != 'vKelly' & type != 'vKelly2') {
    stop('Kindly choose type = "vKelly" or type = "vKelly2" for simulation.')
  } else {
    
    ## risk management
    ## dynamic variance staking risk management similar with idea from bollinger bands.
    #'@ $$ = k^2 * r^2 * f^2$$
    ## leave it as next study in [Application of Kelly Criterion model in Sportsbook Investment - Part II](https://github.com/scibrokes/kelly-criterion)
    
    K <- list()
    for(i in maxit) {
      
      ## wrong... bivariate normal distribution required.
      ## chrome-extension://oemmndcbldboiebfnladdacbdfmadadm/https://cran.r-project.org/web/packages/mvtnorm/mvtnorm.pdf
      ## chrome-extension://oemmndcbldboiebfnladdacbdfmadadm/https://cran.r-project.org/web/packages/mnormt/mnormt.pdf
      ##
      ## Remarks :
      ## I directly apply the model8 as refer to below paper to simulate a final scores of a soccer match.
      ## chrome-extension://oemmndcbldboiebfnladdacbdfmadadm/http://tolstoy.newcastle.edu.au/R/e8/help/att-6544/karlisntzuofras03.pdf
      
      ## load rScores() for bivariate scoring.
      
      
      mbase %>% mutate(FTHG = rpois(length(FTHG), rnorm(mean(FTHG), sd(FTHG))), 
                       FTAG = rpois(length(FTAG), rnorm(mean(FTAG), sd(FTAG))))
      
      lProf <- leagueProf %>% 
        mutate(mean = ifelse(lPmean == 'runif', runif(mean, min, max), 
                      ifelse(lPmean == 'rnorm', rnorm(mean, sd), 0)))
      mb <- join(mbase, lProf) %>% mutate(Stakes = mean)
      
      if(Kelly == 'stakes') K[[i]] <- vKelly(mb, weight.stakes = weight.stakes, weight = weight)
      if(Kelly == 'prob') K[[i]] <- vKelly2(mb, weight.stakes = weight.stakes, weight = weight)
    }
  }
  
  options(warn = 0)
  return(list(K, leagueProf = leagueProf, lPmean = lPmean, Kelly = Kelly, maxit = maxit))
}