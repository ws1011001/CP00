## ---------------------------
## [script name] sound_equalizer.R
##
## SCRIPT to ...
##
## By Shuai Wang, [date] 2020-09-07
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
# load up packages
library('tuneR')
library('seewave')
# setup path
wdir <- '/media/wang/BON/Projects/CP00/experiment_design/stimuli_generation/'
setwd(wdir)
sdir <- file.path(wdir,'stimuli_words+pseudowords_pilot2/')            # original stimuli
edir <- file.path(wdir,'stimuli_words+pseudowords_reverb_corrected/')  # modified stimuli
dir.create(edir)
# read bad stimuli list
stims <- read.table(file=file.path(wdir,'stimuli_words+pseudowords_pilot2_list.txt'),stringsAsFactors=FALSE)$V1
# homemade functions
fb2 <- function (wavo,wl,ol,fb,perc,fsample,filename){
  wavs <- spectro(wavo,wl=wl,ovlp=ol,complex=TRUE,norm=FALSE,plot=FALSE,dB=NULL)
  wavm <- wavs$amp  # complex matrix
  wavm2 <- wavm[wavs$freq>=fb[1] & wavs$freq<=fb[2],]
  wavm3 <- wavm2*perc
  wavm[wavs$freq>=fb[1] & wavs$freq<=fb[2],] <- wavm3
  wavo2 <- istft(wavm,wl=wl,f=fsample,output='Wave')
  savewav(wavo2,filename=filename)
}
## ---------------------------

## reduce the intensity for a specific frequency band
n <- length(stims)
for (i in 1:n){
  stim <- stims[i]
  fstim <- file.path(sdir,paste0(stim,'.wav'))
  stim_wave <- readWave(fstim)
  fredc <- file.path(edir,paste0(stim,'.wav'))  # reduced version
  stim_reduced <- fb2(wavo=stim_wave,wl=2048,ol=75,fb=c(0.8,1.2),perc=0.01,fsample=48000,filename=fredc)
  # copy files
  #file.copy(fstim,edir)
}
## ---------------------------