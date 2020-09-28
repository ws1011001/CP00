rm(list=ls())
old.test <- matrix(0,nrow=96,ncol=3)
while (any(old.test==0)){
  source('trials_design.R')
  new.trials <- read.csv('Words_Selection_2019_1107_1915/Selected_Words_byConditions_newTrials.csv')
  old.test <- as.matrix(new.trials[97:192,c('OLD.A1A2','OLD.A1Ts','OLD.A2Ts')])
}