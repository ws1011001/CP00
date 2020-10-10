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
# constant variables
match.realwords <- c('nbsyll','freqlivres','freqfilms2','nblettres','nbphons','old20','pld20','puphon')
match.pseudowords <- c('nbsyll','nblettres','nbphons')
NumOfWords.1word <- 60
nruns.1word <- 5
keepNumbOfSylls <- TRUE  # keep the number of sylls constant within a trial
firstLetterDiff <- TRUE  # make the first letter between the two words are different
NumOfTrls <- 12  # 12 trials for Pilot3 (and formal collection); 18 trials for Pilot2
conditions.2word <- c('SISMa','SISMv','SIDMa','SIDMv','DISMa','DISMv','DIDMa','DIDMv') 
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
# words for 2-word trials
load(file=file.path(pdir,'Pilot3_words_2wordTrials.Rdata'))
## ---------------------------

## design 1-word trials (5 runs)
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
     file=file.path(pdir,'Pilot3_words_and_pseudowords_1wordTrials_byRuns.Rdata'))
write.csv(words.1word.assign,file=file.path(pdir,'Pilot3_words_1wordTrials_byRuns.csv'),row.names=FALSE)
write.csv(pwords.1word.assign,file=file.path(pdir,'Pilot3_pseudowords_1wordTrials_byRuns.csv'),row.names=FALSE)
## ---------------------------

## design 2-word trials
words.2word.selected <- read.csv(file=file.path(pdir,'Pilot3_words_2wordTrials.csv'),stringsAsFactors=FALSE)
# generate trials
words.2word.trials <- data.frame('conditions'=rep(conditions.2word,each=NumOfTrls),
                                 'A1'=rep('',NumOfTrls*length(conditions.2word)),
                                 'A2'=rep('',NumOfTrls*length(conditions.2word)),
                                 'pA1'=rep('',NumOfTrls*length(conditions.2word)),
                                 'pA2'=rep('',NumOfTrls*length(conditions.2word)),
                                 'cA1'=rep('',NumOfTrls*length(conditions.2word)),
                                 'cA2'=rep('',NumOfTrls*length(conditions.2word)),
                                 'OLD.A1A2'=rep(0,NumOfTrls*length(conditions.2word)),
                                 'PLD.A1A2'=rep(0,NumOfTrls*length(conditions.2word)),
                                 stringsAsFactors=FALSE)
# generate trials for each condition
for (i in 1:4){
  # generate trials for each SI condition
  iSI <- conditions.2word[i]
  iWds <- words.2word.selected[words.2word.selected$conditions==iSI,c('ortho','phon')]
  iTrls <- words.2word.trials[words.2word.trials$conditions==iSI,]
  jWs <- sample(1:NumOfTrls)
  for (j in 1:NumOfTrls){
    jW <- jWs[j]  # randomly select a word
    iTrls[j,c('A1','A2')] <- iWds$ortho[c(jW,jW)]
    iTrls[j,c('pA1','pA2')] <- iWds$phon[c(jW,jW)]
    iTrls[j,c('cA1','cA2')] <- c(iSI,iSI) 
    iTrls[j,c('OLD.A1A2')] <- 0  
    iTrls[j,c('PLD.A1A2')] <- 0
  }
  words.2word.trials[words.2word.trials$conditions==iSI,] <- iTrls 
  # generate trials for each DI condition
  iDI <- conditions.2word[4+i]
  iWds <- words.2word.selected[words.2word.selected$conditions==iDI,c('ortho','phon')]
  iTrls <- words.2word.trials[words.2word.trials$conditions==iDI,]
  iLDM <- LDM(iWds)
  iOLDM <- iLDM$OLDM
  iPLDM <- iLDM$PLDM
  iOWM <- iLDM$OFWM   # OWM, Orthographic first-letter-Weighted Distance Matrix
  if (keepNumbOfSylls){
    iSylls <- words.2word.selected[words.2word.selected$conditions==iDI,'nbsyll']
    iSCM <- iSylls %*% t(iSylls)  # SCM, number of Sylls Constant Matrix
    iSCM[iSCM==2] <- 0
    iSCM[iSCM==4] <- 1
    iOWM <- iOWM*iSCM
  }
  if (firstLetterDiff){
    fOWM <- rep(0,NumOfTrls)
  } else {
    fOWM <- 0
  }
  while (any(fOWM==0)){
    for (j in 1:NumOfTrls){
      nW <- dim(iWds)[1]                      # number of words
      jW <- sample(1:nW)[1]                   # randomly select a word (should be A1)
      jN <- order(iOWM[,jW],decreasing=TRUE)  # sort other words by their OLD with A1
      # generate a trial by selecting the first two farest neighbours
      k <- 1
      iTrls[j,c('A1','A2')] <- iWds$ortho[c(jW,jN[k])]
      iTrls[j,c('pA1','pA2')] <- iWds$phon[c(jW,jN[k])]    
      iTrls[j,c('cA1','cA2')] <- c(iDI,iDI)
      iTrls[j,c('OLD.A1A2')] <- iOLDM[jW,jN[k]]
      iTrls[j,c('PLD.A1A2')] <- iPLDM[jW,jN[k]]   
      # remove selected words
      fOWM[j] <- iOWM[jW,jN[k]]
      iWds <- iWds[-c(jW,jN[k]),] 
      iOWM <- iOWM[-c(jW,jN[k]),-c(jW,jN[k])]
      iOLDM <- iOLDM[-c(jW,jN[k]),-c(jW,jN[k])]     
      iPLDM <- iPLDM[-c(jW,jN[k]),-c(jW,jN[k])]      
    }   
  }
  words.2word.trials[words.2word.trials$conditions==iDI,] <- iTrls
}
# compare OLD and PLD for four DI conditions
conditions.DI <- conditions.2word[5:8]
words.2word.trials.DI <- words.2word.trials[words.2word.trials$conditions %in% conditions.DI,]
Comparison.2word.OLD <- kruskal.test(words.2word.trials.DI$OLD.A1A2,as.factor(words.2word.trials.DI$conditions))
Comparison.2word.PLD <- kruskal.test(words.2word.trials.DI$PLD.A1A2,as.factor(words.2word.trials.DI$conditions))
# output 2-word trials
write.csv(words.2word.trials,file=file.path(pdir,'Pilot3_words_2wordTrials_byTrials.csv'),row.names=FALSE)
save(words.2word.trials,words.2word.trials.DI,Comparison.2word.OLD,Comparison.2word.PLD,
     file=file.path(pdir,'Pilot3_words_2wordTrials_byTrials.Rdata'))
## ---------------------------