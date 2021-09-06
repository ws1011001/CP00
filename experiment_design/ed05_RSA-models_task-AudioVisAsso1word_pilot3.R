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
nruns <- 5    # 5 runs
ntrls <- 240  # 48 stimuli per run
conditions <- c('WA', 'WV', 'PA', 'PV')
## ---------------------------

## read up task sequence
# initialize the dataframe to store task sequence
task_seqs <- data.frame(CONDITION = character(), PHRASE = character(), WAV = character(), RUN = double())
# load up tasks sequences
for (irun in 1:nruns){
  frun <- file.path(ddir, sprintf('Stimulation_task-AudioVisAsso1word_Pilot3_sub-01_Run%d.desc', irun))
  irun_seqs <- read.table(file = frun, sep = '\t', header = TRUE, stringsAsFactors = FALSE)
  irun_seqs$RUN <- rep(irun, dim(irun_seqs)[1])
  task_seqs <- rbind(task_seqs, irun_seqs[, names(task_seqs)])
}
task_seqs <- task_seqs[task_seqs$CONDITION %in% conditions,]  # clean up rows
# initialize vectors of stimuli info
task_seqs$trial <- seq(1, ntrls)   # trial sequence
task_seqs$fname <- rep('', ntrls)  # filename of its audio
task_seqs$ortho <- rep('', ntrls)  # orthographic form
task_seqs$phono <- rep('', ntrls)  # phonological form
task_seqs$nsyll <- rep(0, ntrls)   # number of syllables
task_seqs$nlett <- rep(0, ntrls)   # number of letters
task_seqs$nphon <- rep(0, ntrls)   # number of phonemes
info_stim <- c('fname', 'ortho', 'phono', 'nsyll', 'nlett', 'nphon')
info_wcol <- c('sfname', 'ortho', 'phon', 'nbsyll', 'nblettres', 'nbphons')
info_pcol <- c('sfname', 'v2written', 'phon', 'nbsyll', 'nblettres', 'nbphons')
## ---------------------------

## extract stimuli information
# read up words and pseudowords
info_word <- read.csv(file = file.path(pdir, 'Pilot3_words_1wordTrials.csv'), stringsAsFactors = FALSE)
info_psew <- read.csv(file = file.path(pdir, 'Pilot3_pseudowords_1wordTrials.csv'), stringsAsFactors = FALSE)
# extract info for each trial (exact orthographic and phonological forms)
for (itrl in 1:ntrls){
  itrl_cond <- task_seqs$CONDITION[itrl]
  switch (itrl_cond,
    WA = {
      itrl_stim <- task_seqs$WAV[itrl]
      task_seqs[itrl, info_stim] <- info_word[info_word$sfname == itrl_stim, info_wcol]
    },
    WV = {
      itrl_stim <- task_seqs$PHRASE[itrl]
      task_seqs[itrl, info_stim] <- info_word[info_word$ortho == itrl_stim, info_wcol]
    },
    PA = {
      itrl_stim <- task_seqs$WAV[itrl]
      task_seqs[itrl, info_stim] <- info_psew[info_psew$sfname == itrl_stim, info_pcol]
    },
    PV = {
      itrl_stim <- task_seqs$PHRASE[itrl]
      task_seqs[itrl, info_stim] <- info_psew[info_psew$v2written == itrl_stim, info_pcol]
    }
  )
}
# output stimuli info
fout <- file.path(wdir, 'Experiment-conducted_task-AudioVisAsso1word_stimuli-information.csv')
write.csv(task_seqs, file = fout, row.names = FALSE)
## ---------------------------

## create RSA models
## ---------------------------