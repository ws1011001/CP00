## ---------------------------
## Pilot2_Words_Selection.R
##
## SCRIPT to re-select words for the second pilot of the CP00 project.
##
## By Shuai Wang, 31-05-2020
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
library('psych')                 # describeBy()
# working path
wdir <- '/data/agora/Chotiga_VOTmultimod/experiment_design/LabView_Scripts/'
pdir <- file.path(wdir,'Pilot2')
setwd(pdir)
# constant variables
match.realwords <- c('nbsyll','freqlivres','freqfilms2','nblettres','nbphons','old20','pld20','puphon')
match.pseudowords <- c('nbsyll','nblettres','nbphons')
NumOfWords.1word <- 60
NumOfWords.2word <- 216
## ---------------------------

## extract pseudowords info for 1-word trials
# merge pseudowords
pseudowords.selected <- read.csv(file.path(pdir,'Selected_Pseudowords_Candidates.csv'),stringsAsFactors=FALSE)
pseudowords.1word <- read.csv(file.path(pdir,'pseudowords_1wordTrials.csv'),stringsAsFactors=FALSE)
pseudowords.pool <- merge(pseudowords.1word,pseudowords.selected,by='sfname')
# new word forms - v2written
pseudowords.pool[pseudowords.pool$v2written=='','v2written'] <- pseudowords.pool[pseudowords.pool$v2written=='','pseudowords']
# number of letters, number of phonmes, and number of syllables
pseudowords.pool$nblettres <- nchar(pseudowords.pool$v2written)
pseudowords.pool$nbphons <- nchar(pseudowords.pool$phon)
pseudowords.pool$nbsyll <- pseudowords.pool$syll
write.csv(pseudowords.pool,file=file.path(pdir,'Pilot2_pseudowords_candidates_1wordTrials.csv'),row.names=FALSE)
## ---------------------------

## match word features for 1-word trials
# load words used in pilot1 (16 units, 24 words per unit)
load(file.path(pdir,'Selected_Words_byUnits.Rdata'))  # words.cmr
# re-select words for 1-word trials with 4 units
ComparisonP.1word <- rep(0,length(match.pseudowords))
while (any(ComparisonP.1word < 0.1)){
  # prepare real words
  units.assignment <- sample(1:16)
  units.1word <- units.assignment[1:4]
  words.1word.pool <- words.cmr[words.cmr$units %in% units.1word,]
  words.1word.sel <- sample(1:dim(words.1word.pool)[1])[1:NumOfWords.1word]
  words.1word.pre <- words.1word.pool[words.1word.sel,match.pseudowords]
  # prepare pseudowords
  pseudowords.1word.sel <- sample(1:dim(pseudowords.pool)[1])[1:NumOfWords.1word]
  pseudowords.1word.pre <- pseudowords.pool[pseudowords.1word.sel,match.pseudowords]
  # match variables between selected real words and pseudowords
  match.1word <- rbind(words.1word.pre,pseudowords.1word.pre)
  Comparison.1word <- lapply(match.1word, function(x) kruskal.test(x,as.factor(rep(c('w','p'),each=NumOfWords.1word))))
  ComparisonP.1word <- unlist(lapply(Comparison.1word, function(x) x$p.value))
}
words.1word.selected <- words.1word.pool[words.1word.sel,]
pseudowords.1word.selected <- pseudowords.pool[pseudowords.1word.sel,]
# check the matches
print(paste('#####Quick Check - 1-word##### The Comparison results are: P =',ComparisonP.1word))
## ---------------------------

## re-match words for 2-word trials between 12 units with 18 words per unit
# prepare words
units.2word <- units.assignment[5:16]
words.2word.pool <- words.cmr[words.cmr$units %in% units.2word,]
ComparisonP.2word <- rep(0,length(match.realwords))
while (any(ComparisonP.2word < 0.1)){
  words.2word.pre <- words.2word.pool
  # remove 3 monosyllabic and 3 bisyllabic words from each unit
  for (iunit in units.2word){
    rm.mo <- which(words.2word.pre$units==iunit & words.2word.pre$nbsyll==1)[sample(1:12)[1:3]]
    rm.bi <- which(words.2word.pre$units==iunit & words.2word.pre$nbsyll==2)[sample(1:12)[1:3]]
    words.2word.pre <- words.2word.pre[-c(rm.mo,rm.bi),]
  }
  # match variables between 12 new units
  match.2word <- words.2word.pre[,match.realwords]
  Comparison.2word <- lapply(match.2word, function(x) kruskal.test(x,as.factor(words.2word.pre$units)))
  ComparisonP.2word <- unlist(lapply(Comparison.2word, function(x) x$p.value))  
  
}
words.2word.selected <- words.2word.pre
# check the matches
print(paste('#####Quick Check - 2-word##### The Comparison results are: P =',ComparisonP.2word))
## ---------------------------

## control variables between 1-word trials and 2-word trials
Comparison.1wordvs2word <- lapply(rbind(words.1word.selected[,match.realwords],words.2word.selected[,match.realwords]),
                                  function(x) kruskal.test(x,as.factor(c(rep('1w',NumOfWords.1word),rep('2w',NumOfWords.2word)))))
print(paste('#####Quick Check - 1-word vs. 2-word##### The Comparison results are: P =',
            unlist(lapply(Comparison.1wordvs2word, function(x) x$p.value))))
Comparison.pseudowordvs2word <- lapply(rbind(pseudowords.1word.selected[,match.pseudowords],words.2word.selected[,match.pseudowords]),
                                       function(x) kruskal.test(x,as.factor(c(rep('1p',NumOfWords.1word),rep('2w',NumOfWords.2word)))))
print(paste('#####Quick Check - 1-pseudoword vs. 2-word##### The Comparison results are: P =',
            unlist(lapply(Comparison.pseudowordvs2word, function(x) x$p.value))))
## ---------------------------

## output statistics and save results
# 1-word trials - save results
save(units.assignment,units.1word,words.cmr,pseudowords.pool,words.1word.selected,pseudowords.1word.selected,
     file=file.path(pdir,'Pilot2_words_and_pseudowords_1wordTrials.Rdata'))
write.csv(words.1word.selected,file=file.path(pdir,'Pilot2_words_1wordTrials.csv'),row.names=FALSE)
write.csv(pseudowords.1word.selected,file=file.path(pdir,'Pilot2_pseudowords_1wordTrials.csv'),row.names=FALSE)
# 1-word trials - statistics
sink(file=file.path(pdir,'Pilot2_Statistics_1wordTrials.txt'))
print('#####Descriptive Statistics#####')
print(describeBy(match.1word,group=rep(c('w','p'),each=NumOfWords.1word)),digits=4)
print('#####Kruskal-Wallis Test Between Units#####')
print(Comparison.1word,digits=4)
sink()
# 2-word trials - save results
save(units.assignment,units.2word,words.cmr,words.2word.pool,words.2word.selected,
     file=file.path(pdir,'Pilot2_words_2wordTrials.Rdata'))
write.csv(words.2word.selected,file=file.path(pdir,'Pilot2_words_2wordTrials.csv'),row.names=FALSE)
# 2-word trials - statistics
sink(file=file.path(pdir,'Pilot2_Statistics_2wordTrials.txt'))
print('#####Descriptive Statistics#####')
print(describeBy(words.2word.selected,group=words.2word.selected$units,digits=4))
print('#####Kruskal-Wallis Test Between Units#####')
print(Comparison.2word,digits=4)
sink()
## ---------------------------