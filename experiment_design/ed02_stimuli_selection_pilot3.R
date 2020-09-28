## ---------------------------
## [script name] ed02_stimuli_selection_pilot3.R
##
## SCRIPT to re-select words for the third pilot (should be the formal collection) of the CP00 project.
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
library('psych')                 # describeBy()
# working path
wdir <- '/media/wang/BON/Projects/CP00/experiment_design/'
ldir <- file.path(wdir,'labview_scripts')
pdir <- file.path(ldir,'Pilot2')
odir <- file.path(ldir,'Pilot3')
# constant variables
match.realwords <- c('nbsyll','freqlivres','freqfilms2','nblettres','nbphons','old20','pld20','puphon')
match.pseudowords <- c('nbsyll','nblettres','nbphons')
NumOfWords.1word <- 60
NumOfWords.2word <- 144  # 12 trials per condition; 216 if 18 trials per condition
# load up 'bad' stimuli (https://mail.google.com/mail/u/0/#label/Projects%2FCP00/FMfcgxwJXLntgjdXndBhtGwmjMcmZRxC)
badstim <- read.table(file=file.path(ldir,'bad_words.txt'),stringsAsFactors=FALSE)$V1
## ---------------------------

## extract pseudowords for 1-word trials
fpse <- file.path(pdir,'Pilot2_pseudowords_candidates_1wordTrials.csv')
if (!file.exists(fpse)){
  # merge pseudowords
  pseudowords.selected <- read.csv(file.path(pdir,'Selected_Pseudowords_Candidates_N148.csv'),stringsAsFactors=FALSE)
  pseudowords.1word <- read.csv(file.path(pdir,'Selected_Pseudowords_Candidates_MVPA_N72.csv'),stringsAsFactors=FALSE)
  pseudowords.pool <- merge(pseudowords.1word,pseudowords.selected,by='sfname')
  # new word forms - v2written
  pseudowords.pool[pseudowords.pool$v2written=='','v2written'] <- pseudowords.pool[pseudowords.pool$v2written=='','pseudowords']
  # number of letters, number of phonmes, and number of syllables
  pseudowords.pool$nblettres <- nchar(pseudowords.pool$v2written)
  pseudowords.pool$nbphons <- nchar(pseudowords.pool$phon)
  pseudowords.pool$nbsyll <- pseudowords.pool$syll
  write.csv(pseudowords.pool,file=fpse,row.names=FALSE)
} else {
  pseudowords.pool <- read.csv(file=fpse,stringsAsFactors=FALSE)
}
pseudowords.pool <- pseudowords.pool[!pseudowords.pool$sfname %in% badstim,]  # should be 69 pseudowords
## ---------------------------

## match word features for 1-word trials
# load words used in pilot1 (16 units, 24 words per unit)
load(file.path(pdir,'Selected_Words_byUnits.Rdata'))  # words.cmr
# add sfname (remove dialects)
words.cmr$sfname <- iconv(words.cmr$ortho,to='ASCII//TRANSLIT')
# re-select words for 1-word trials with 4 units
ComparisonP.1word <- rep(0,length(match.pseudowords))
while (any(ComparisonP.1word < 0.1)){
  # prepare real words
  units.assignment <- sample(1:16)
  units.1word <- units.assignment[1:4]
  words.1word.pool <- words.cmr[words.cmr$units %in% units.1word,]
  # clean up bad words from the word pool
  words.1word.pool <- words.1word.pool[!words.1word.pool$sfname %in% badstim,]
  # randomly selected words and pseudowords
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

## re-match words for 2-word trials between 12 units with 12 words per unit
# prepare words
units.2word <- units.assignment[5:16]
words.2word.pool <- words.cmr[words.cmr$units %in% units.2word,]
ComparisonP.2word <- rep(0,length(match.realwords))
while (any(ComparisonP.2word < 0.1)){
  # make sure there is no bad words
  nbad <- 1
  while (nbad!=0){
    words.2word.pre <- words.2word.pool
    # remove 6 monosyllabic and 6 bisyllabic words from each 24 words unit
    for (iunit in units.2word){
      rm.mo <- which(words.2word.pre$units==iunit & words.2word.pre$nbsyll==1)[sample(1:12)[1:6]]
      rm.bi <- which(words.2word.pre$units==iunit & words.2word.pre$nbsyll==2)[sample(1:12)[1:6]]
      words.2word.pre <- words.2word.pre[-c(rm.mo,rm.bi),]
    }   
    nbad <- sum(words.2word.pre$sfname %in% badstim)
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

## organize 2-word stimuli by conditions
# assign the 12 matched units into 8 conditions with controlling the target variables
conditions.2word <- c('SISMa','SISMv','SIDMa','SIDMv','DISMa','DISMv','DIDMa','DIDMv') 
words.2word.selected$conditions <- rep('',NumOfWords.2word)
ComparisonP.2word.conds <- rep(0,length(match.realwords))
while (any(ComparisonP.2word.conds < 0.1)){
  randUnits <- sample(unique(words.2word.selected$units))
  for (i in 1:4){
    # assign the first 4 units to the 4 SI conditions
    words.2word.selected$conditions[words.2word.selected$units %in% randUnits[i]] <- conditions.2word[i]
    # assign the rest 8 units to the 4 DI conditions
    words.2word.selected$conditions[words.2word.selected$units %in% randUnits[(i*2+3):(i*2+4)]] <- conditions.2word[i+4]
  }
  # compare target variables across all conditions with Kruskal-Wallis Rank Sum Test
  Comparison.2word.conds <- lapply(words.2word.selected[,match.realwords],
                           function(x) kruskal.test(x,as.factor(words.2word.selected$conditions)))
  ComparisonP.2word.conds <- unlist(lapply(Comparison.2word.conds, function(x) x$p.value))
}
print(paste('#####Quick Check - Conditions##### The Comparison results are: P =',ComparisonP.2word.conds))
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
     file=file.path(odir,'Pilot3_words_and_pseudowords_1wordTrials.Rdata'))
write.csv(words.1word.selected,file=file.path(odir,'Pilot3_words_1wordTrials.csv'),row.names=FALSE)
write.csv(pseudowords.1word.selected,file=file.path(odir,'Pilot3_pseudowords_1wordTrials.csv'),row.names=FALSE)
# 1-word trials - statistics
sink(file=file.path(odir,'Pilot3_Statistics_1wordTrials.txt'))
print('#####Descriptive Statistics#####')
print(describeBy(match.1word,group=rep(c('w','p'),each=NumOfWords.1word)),digits=4)
print('#####Kruskal-Wallis Test Between Units#####')
print(Comparison.1word,digits=4)
sink()
# 2-word trials - save results
save(units.assignment,units.2word,words.cmr,words.2word.pool,words.2word.selected,
     file=file.path(odir,'Pilot3_words_2wordTrials.Rdata'))
write.csv(words.2word.selected,file=file.path(odir,'Pilot3_words_2wordTrials.csv'),row.names=FALSE)
# 2-word trials - statistics
sink(file=file.path(odir,'Pilot3_Statistics_2wordTrials.txt'))
print('#####Descriptive Statistics#####')
print(describeBy(words.2word.selected,group=words.2word.selected$units,digits=4))
print('#####Kruskal-Wallis Test Between Units#####')
print(Comparison.2word,digits=4)
print('#####Kruskal-Wallis Test Between Conditions#####')
print(Comparison.2word.conds,digits=4)
sink()
## ---------------------------