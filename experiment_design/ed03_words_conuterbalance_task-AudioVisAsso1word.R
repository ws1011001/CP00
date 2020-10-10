## ---------------------------
## [script name] ed03_words_conuterbalance.R
##
## SCRIPT to match words between conditions for both 1-word and 2-words tasks.
##
## By Shuai Wang, [date] 2020-05-31
##
## ---------------------------
## Notes:
##   
##
## ---------------------------

## clean up
rm(list=ls())
## ---------------------------

## set environment (packages, functions, working path, and constants)
# load up packages
library('psych')  # describeBy()
library('vwr')    # levenshtein.distance()
# working path
wdir <- '/media/wang/BON/Projects/CP00/experiment_design/labview_scripts/'
pdir <- file.path(wdir,'Pilot3')
setwd(pdir)
odir <- file.path(pdir,'AVA-1word')
# constant variables
subjects <- c('sub-01','sub-02','sub-03','sub-04','sub-05','sub-06','sub-07','sub-08','sub-09','sub-10')
match.realwords <- c('nbsyll','freqlivres','freqfilms2','nblettres','nbphons','old20','pld20','puphon')
match.pseudowords <- c('nbsyll','nblettres','nbphons')
NumOfWords.1word <- 60
nruns.1word <- 5
# custom functions
LDM <- function(Wds){                      
  # LDM(), Levenshtein Distance Matrix
  # Wds must has two cols, one is the orthography, the other is the phonological
  # labels, i.e. Wds$ortho, Wds$phon
  NumOfWds <- dim(Wds)[1]
  OLDM <- matrix(NA,NumOfWds,NumOfWds)  # orthographic distance
  PLDM <- matrix(NA,NumOfWds,NumOfWds)  # phonological distance
  OFLM <- matrix(NA,NumOfWds,NumOfWds)  # the first letter
  PFLM <- matrix(NA,NumOfWds,NumOfWds)  # the first phoneme
  for (iW in 1:NumOfWds){
    # calculate the OLD and PLD using Levenstein Distance
    OLDM[,iW] <- levenshtein.distance(Wds$ortho[iW],Wds$ortho)
    PLDM[,iW] <- levenshtein.distance(Wds$phon[iW],Wds$phon)
    # calculate the OLD and PLD between the first letters/phonemes to extract 
    # "First Letter Matrix" where the link between two words equals 0 if they 
    # share the first letter/phoneme, otherwise the link is 1.
    OFLM[,iW] <- levenshtein.distance(substr(Wds$ortho[iW],1,1),substr(Wds$ortho,1,1))   
    PFLM[,iW] <- levenshtein.distance(substr(Wds$phon[iW],1,1),substr(Wds$phon,1,1))
  }
  # estimate the "First Letter/Phoneme" Weighted Levenshtein Distance Matrix
  OFWM <- OLDM*OFLM
  PFWM <- PLDM*PFLM
  colnames(OFWM) <- Wds$ortho
  colnames(PFWM) <- Wds$ortho
  row.names(OFWM) <- Wds$ortho
  row.names(PFWM) <- Wds$ortho
  return(list('OLDM'=OLDM,'PLDM'=PLDM,'OFLM'=OFLM,'PFLM'=PFLM,
              'OFWM'=OFWM,'PFWM'=PFWM))
}
## ---------------------------

## read selected words
# words for 1-word trials
load(file=file.path(pdir,'Pilot3_words_and_pseudowords_1wordTrials.Rdata'))
## ---------------------------

## design 1-word trials (5 runs)
for (subj in subjects){
  sdir <- file.path(odir,subj)
  dir.create(sdir)
  # real words
  ComparisonP.1word <- rep(0,length(match.realwords))
  words.1word.assign <- words.1word.selected
  while (any(ComparisonP.1word < 0.1)){
    # randomly assign real words
    words.1word.assign$unitIdx <- sample(rep(c('run1','run2','run3','run4','run5'),each=NumOfWords.1word/nruns.1word))
    words.1word.match <- words.1word.assign[,match.realwords]
    # match variables between assigned real words
    Comparison.1word <- lapply(words.1word.match, function(x) kruskal.test(x,as.factor(words.1word.assign$unitIdx)))
    ComparisonP.1word <- unlist(lapply(Comparison.1word, function(x) x$p.value))
  }
  print(paste('#####Quick Check - 1-word##### The Comparison results are: P =',ComparisonP.1word))  # check the matches
  # pseudowords
  ComparisonP.pword <- rep(0,length(match.pseudowords))
  pwords.1word.assign <- pseudowords.1word.selected
  while (any(ComparisonP.pword < 0.1)){
    # randomly assign real words
    pwords.1word.assign$unitIdx <- sample(rep(c('run1','run2','run3','run4','run5'),each=NumOfWords.1word/nruns.1word))
    pwords.1word.match <- pwords.1word.assign[,match.pseudowords]
    # match variables between assigned real words
    Comparison.pword <- lapply(pwords.1word.match, function(x) kruskal.test(x,as.factor(pwords.1word.assign$unitIdx)))
    ComparisonP.pword <- unlist(lapply(Comparison.pword, function(x) x$p.value))
  }
  print(paste('#####Quick Check - pseudoword##### The Comparison results are: P =',ComparisonP.pword))  # check the matches
  # output 
  save(match.realwords,match.pseudowords,Comparison.1word,Comparison.pword,words.1word.assign,pwords.1word.assign,
       file=file.path(sdir,sprintf('Pilot3_%s_words_and_pseudowords_1wordTrials_byRuns.Rdata',subj)))
  write.csv(words.1word.assign,file=file.path(sdir,sprintf('Pilot3_%s_words_1wordTrials_byRuns.csv',subj)),row.names=FALSE)
  write.csv(pwords.1word.assign,file=file.path(sdir,sprintf('Pilot3_%s_pseudowords_1wordTrials_byRuns.csv',subj)),row.names=FALSE)
}
## ---------------------------