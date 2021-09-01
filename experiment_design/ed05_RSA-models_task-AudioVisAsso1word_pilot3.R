## ---------------------------
## [script name] 
##
## SCRIPT to ...
##
## By Shuai Wang, [date]
##
## ---------------------------
## Notes:
##   
##
## ---------------------------

## clean up
rm(list=ls())
## ---------------------------

## set environment (packages, functions, working path etc.)
# setup working path
mdir <- '/media/wang/BON/Projects/CP00'               # the project folder
wdir <- file.path(mdir, 'experiment_design')          # the experiment design folder
pdir <- file.path(wdir, 'labview_scripts', 'Pilot3')  # the experiment design that used for data collection
ddir <- file.path(pdir, 'AVA-1word', 'sub-01')        # the data collection used the task sequence of sub-01 for all subjects
# task parameters
ntrls <- 48              # 48 stimuli per run
nruns <- 5               # 5 runs
conditions <- c('WA', 'WV', 'PA', 'PV')
## ---------------------------

## read up task sequence
# initialize the dataframe to store task sequence
task_desc <- data.frame(CONDITION = '', PHRASE = '', BITMAP = '', WAV = '', DUREE = 0,REPONSE1 = 0, REPONSE2 = 0, REPONSE3 = 0)
# load up tasks sequences
for (irun in 1:nruns){
  attach(what = file.path(ddir, sprintf('Stimulation_task-AudioVisAsso1word_Pilot3_sub-01_Run%d.Rdata', irun)))
    irun_desc <- irun.desc
  detach()
  task_desc <- rbind(task_desc, irun_desc)
}
# clean up
task_seqs <- task_desc[task_desc$CONDITION %in% conditions, c('CONDITION', 'PHRASE', 'WAV')]
## ---------------------------

## extract stimuli information
# read up words and pseudowords
info_word <- read.csv(file = file.path(pdir, 'Pilot3_words_1wordTrials.csv'), stringsAsFactors = FALSE)
info_psew <- read.csv(file = file.path(pdir, 'Pilot3_pseudowords_1wordTrials.csv'), stringsAsFactors = FALSE)
# extract info for each trial (exact orthographic and phonological forms)
for (itrl in 1:dim(task_seqs)[1]){
  itrl_cond <- task_seqs$CONDITION[itrl]
  switch (itrl_cond,
    WA = {},
    WV = {},
    PA = {},
    PV = {}
  )
}
## ---------------------------

## create RSA models
## ---------------------------