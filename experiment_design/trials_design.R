## SCRIPT to assign words to trials within the same condition. 
## Based on the output of stimuli_selection_v3.R
# By WS, 2019-11-08.

## assignment criteria: - control the first letter to be different
##                      - orthographic and phonological distance between 
##                        adjacent words are matched across conditions


# clean up
rm(list=ls())

# setup environment
library('vwr')                             # levenshtein.distance()
library('psych')                           # describeBy()
library('ggplot2')                         # violin plot
library('cowplot')                         # plot_grid()
wdir <- 'Words_Selection_2019_1107_1915/'  # the working directory
LDM <- function(Wds){                      
  # LDM(), Levenshtein Distance Matrix
  # Wds must has two cols, one is the orthography, the other is the phonological
  # labels, i.e. Wds$ortho, Wds$phon
  NumOfWds <- dim(Wds)[1]
  # 
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


# read the words list
load(file=file.path(wdir,'Selected_Words_byConditions.Rdata'))

# generate trials for each DI condition
keepNumbOfSylls <- TRUE  # keep the number of sylls constant within a trial
firstLetterA1Ts <- TRUE  # make the first letter between A1 and Ts are different
NumOfTrls <- 24
new.trials <- cmr.trials
for (i in 1:4){
  # calculate distance matrices
  iDI <- cmr.conditions[4+i]
  iWds <- words.cmr[words.cmr$conditions==iDI,c('ortho','phon')]
  iLDM <- LDM(iWds)
  iOWM <- iLDM$OFWM   # OWM, Orthographic first-letter-Weighted Distance Matrix
  if (keepNumbOfSylls){
    iSylls <- words.cmr[words.cmr$conditions==iDI,'nbsyll']
    iSCM <- iSylls %*% t(iSylls)  # SCM, number of Sylls Constant Matrix
    iSCM[iSCM==2] <- 0
    iSCM[iSCM==4] <- 1
    iOWM <- iOWM*iSCM
  }
  # select words for each trial
  iTrls <- new.trials[new.trials$conditions==iDI,]
  for (j in 1:NumOfTrls){
    nW <- dim(iWds)[1]                      # number of words in the pool
    jW <- sample(1:nW)[1]                   # randomly select a word (should be A2)
    jN <- order(iOWM[,jW],decreasing=TRUE)  # sort other words by their OLD with A2
    # generate a trial by selecting the first two farest neighbours
    if (firstLetterA1Ts){
      k <- 2
      while (iOWM[jN[1],jN[k]]==0){
        k <- k+1
      }
    } else {
      k <- 2
    }
    iTrls[j,c('A1','A2','Ts')] <- iWds$ortho[c(jN[1],jW,jN[k])]
    iTrls[j,c('pA1','pA2','pTs')] <- iWds$phon[c(jN[1],jW,jN[k])]    
    iTrls[j,c('OLD.A1A2','OLD.A1Ts','OLD.A2Ts')] <- c(iOWM[jN[1],jW],iOWM[jN[1],jN[k]],iOWM[jW,jN[k]])
    # remove selected words
    iWds <- iWds[-c(jN[1],jW,jN[k]),] 
    iOWM <- iOWM[-c(jN[1],jW,jN[k]),-c(jN[1],jW,jN[k])]
  }
  new.trials[new.trials$conditions==iDI,] <- iTrls
}

# compare trial-wise means (i.e. OLD, PLD) across the four DI conditions
#new.trials$OLD.A1A2 <- mapply(levenshtein.distance,new.trials$A1,new.trials$A2)
#new.trials$OLD.A1Ts <- mapply(levenshtein.distance,new.trials$A1,new.trials$Ts)
#new.trials$OLD.A2Ts <- mapply(levenshtein.distance,new.trials$A2,new.trials$Ts)
new.trials$OLD.mean <- rowMeans(new.trials[,c('OLD.A1A2','OLD.A1Ts','OLD.A2Ts')])
new.trials$PLD.A1A2 <- mapply(levenshtein.distance,new.trials$pA1,new.trials$pA2)
new.trials$PLD.A1Ts <- mapply(levenshtein.distance,new.trials$pA1,new.trials$pTs)
new.trials$PLD.A2Ts <- mapply(levenshtein.distance,new.trials$pA2,new.trials$pTs)
new.trials$PLD.mean <- rowMeans(new.trials[,c('PLD.A1A2','PLD.A1Ts','PLD.A2Ts')])
DI.trials <-new.trials[seq(NumOfTrls*4+1,NumOfTrls*8),
                       c('conditions','OLD.A1A2','OLD.A2Ts','OLD.A1Ts','OLD.mean','PLD.A1A2','PLD.A2Ts','PLD.A1Ts','PLD.mean')]
DistComparison <- lapply(DI.trials[,-1],function(x) kruskal.test(x,DI.trials$conditions))

# save the new trial list
save(new.trials,DI.trials,DistComparison,file=file.path(wdir,'Selected_Words_byConditions_newTrials.Rdata'))
write.csv(new.trials,file=file.path(wdir,'Selected_Words_byConditions_newTrials.csv'),row.names=FALSE)

# output the statistics by conditions 
sink(file=file.path(wdir,'Statistics_byConditions_newTrials.txt'))
print('#####Descriptive Statistics#####')
print(describeBy(DI.trials,group=DI.trials$conditions),digits=4)
print('#####Kruskal-Wallis Test Between DI Conditions - OLD and PLD#####')
print(DistComparison,digits=4)
sink()
p.o12 <- ggplot(data=DI.trials,aes(x=conditions,y=OLD.A1A2))+xlab('Conditions')+ylab('OLD between A1 and A2')+geom_violin(trim=FALSE,color='gray')+geom_boxplot(width=0.2)+theme_grey(base_size=24)
p.o2t <- ggplot(data=DI.trials,aes(x=conditions,y=OLD.A2Ts))+xlab('Conditions')+ylab('OLD between A2 and Test')+geom_violin(trim=FALSE,color='gray')+geom_boxplot(width=0.2)+theme_grey(base_size=24)
p.o1t <- ggplot(data=DI.trials,aes(x=conditions,y=OLD.A1Ts))+xlab('Conditions')+ylab('OLD between A1 and Test')+geom_violin(trim=FALSE,color='gray')+geom_boxplot(width=0.2)+theme_grey(base_size=24)
p.old <- ggplot(data=DI.trials,aes(x=conditions,y=OLD.mean))+xlab('Conditions')+ylab('mean OLD')+geom_violin(trim=FALSE,color='gray')+geom_boxplot(width=0.2)+theme_grey(base_size=24)
p.p12 <- ggplot(data=DI.trials,aes(x=conditions,y=PLD.A1A2))+xlab('Conditions')+ylab('PLD between A1 and A2')+geom_violin(trim=FALSE,color='gray')+geom_boxplot(width=0.2)+theme_grey(base_size=24)
p.p2t <- ggplot(data=DI.trials,aes(x=conditions,y=PLD.A2Ts))+xlab('Conditions')+ylab('PLD between A2 and Test')+geom_violin(trim=FALSE,color='gray')+geom_boxplot(width=0.2)+theme_grey(base_size=24)
p.p1t <- ggplot(data=DI.trials,aes(x=conditions,y=PLD.A1Ts))+xlab('Conditions')+ylab('PLD between A1 and Test')+geom_violin(trim=FALSE,color='gray')+geom_boxplot(width=0.2)+theme_grey(base_size=24)
p.pld <- ggplot(data=DI.trials,aes(x=conditions,y=PLD.mean))+xlab('Conditions')+ylab('mean PLD')+geom_violin(trim=FALSE,color='gray')+geom_boxplot(width=0.2)+theme_grey(base_size=24)
cairo_pdf(filename=file.path(wdir,'Statistics_byConditions_newTrials.pdf'),width=32,height=16)
plot_grid(p.o12,p.o2t,p.o1t,p.old,p.p12,p.p2t,p.p1t,p.pld,labels='AUTO',nrow=2)
dev.off()

## check number of syllables
#check.trials <- new.trials
#check.sylls <- words.cmr[,c('ortho','nbsyll')]
#check.sylls <- dplyr::rename(check.sylls,!!c('A1'='ortho','A1nbs'='nbsyll'))
#check.trials <- merge(check.trials,check.sylls,by.x='A1')
#check.sylls <- dplyr::rename(check.sylls,!!c('A2'='A1','A2nbs'='A1nbs'))
#check.trials <- merge(check.trials,check.sylls,by.x='A2')
#check.sylls <- dplyr::rename(check.sylls,!!c('Ts'='A2','Tsnbs'='A2nbs'))
#check.trials <- merge(check.trials,check.sylls,by.x='Ts')