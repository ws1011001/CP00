## SCRIPT to select words as stimuli for the localizer tasks and the repetition task in the CP00 
## fMRI study.
## Lexique query: number of letters      [3,6]
##                number of syllables    [1,2]
##                word frequency (books) > 5
##                no homophone words
## Variables to be matched across eight conditions: number of letters, number of phonemes, 50% 
## monosyllable and 50% bisyllable, and word frequency.
## Variables to be controled for each single trial: orthographic/phonological distance between 
## adjacent words.
# BY WS, 2019-10-29.

# clean up
rm(list=ls())

# setup environments
library('psych')      # describeBy()
library('anticlust')  # anticlustering()
library('vwr')
library('MatchIt')    # matchit()


# read the queried words dataset
lexique.words <- read.csv('Lexique_Words.csv')
words.all <- lexique.words[order(lexique.words$nbsyll),]

# select words for the cross-modal repetition task
NumOfWdsUnit <- 24  # split 8 conditions into 16 units with equal number of words
NumOfUnits <- 16    # SI conditions: 4x1; DI conditions: 4x3; 16 units in total
NumOfWds <- NumOfWdsUnit*NumOfUnits  # total number of words

while (any(VarComparisonP < 0.1)){
  # generate random index
  randIdxMo <- sample(c(rep(1,NumOfWds/2),rep(0,sum(words.all$nbsyll==1)-NumOfWds/2)))
  randIdxBi <- sample(c(rep(1,NumOfWds/2),rep(0,sum(words.all$nbsyll==2)-NumOfWds/2))) 
  randIdx <- as.logical(c(randIdxMo,randIdxBi))
  # pre-select words randomly with target variables
  words.pre <- words.all[randIdx,c('freqlivres','nblettres','nbphons','nbsyll')]
  # split the pre-selected words into $NumOfUnits matched units
  words.sel <- anticlustering(features=words.pre[,-4],K=NumOfUnits,
                              objective='variance',categories=words.pre[,4])
  # compare target variables across all units with Kruskal-Wallis Rank Sum Test
  VarComparison <- lapply(words.pre, function(x) kruskal.test(x,as.factor(words.sel)))
  VarComparisonP <- unlist(lapply(VarComparison, function(x) x$p.value))
}
print(paste('#####Quick Check##### The Comparison results are: P =',VarComparisonP))
cmrIdx <- randIdx  # cmr, cross-modal repetition; the indices of the matched words
words.cmr <- words.all[cmrIdx,]  
words.cmr$units <- words.sel
words.cmr <- words.cmr[order(words.cmr$units),]
save(words.cmr,cmrIdx,words.sel,file='Selected_Words.Rdata')
describeBy(words.cmr,group=words.cmr$units)


# calculate orthographic distance and phonological distance for each pair of words
dist.ortho <- matrix(NA,NumOfWds,NumOfWds)
dist.phono <- matrix(NA,NumOfWds,NumOfWds)
for (iW in 1:NumOfWds){
  dist.ortho[,iW] <- levenshtein.distance(words.cmr$ortho[iW],words.cmr$ortho)
  dist.phono[,iW] <- levenshtein.distance(words.cmr$phon[iW],words.cmr$phon) 
}
colnames(dist.ortho) <- words.cmr$ortho
row.names(dist.ortho) <- words.cmr$ortho
write.csv(dist.ortho,file='orthogrphic_distance_matrix.csv')
colnames(dist.phono) <- words.cmr$ortho
row.names(dist.phono) <- words.cmr$ortho
write.csv(dist.phono,file='phonological_distance_matrix.csv')

# assign the matched units into 8 conditions for the cross-modal repetition task
cmr.conditions <- c('SISMa','SISMv','SIDMa','SIDMv','DISMa','DISMv','DIDMa','DIDMv') 
cmrTask <- data.frame('conditions'=rep(cmr.conditions,each=NumOfWdsUnit),
                      'A1'=words.cmr$ortho[words.cmr$units %in% c(1:8)],
                      'A2'=words.cmr$ortho[words.cmr$units %in% c(1:4,9:12)],
                      'Ts'=words.cmr$ortho[words.cmr$units %in% c(1:4,13:16)],
                      'pA1'=words.cmr$phon[words.cmr$units %in% c(1:8)],
                      'pA2'=words.cmr$phon[words.cmr$units %in% c(1:4,9:12)],
                      'pTs'=words.cmr$phon[words.cmr$units %in% c(1:4,13:16)])
cmrTask$OLD.A1A2 <- mapply(levenshtein.distance,cmrTask$A1,cmrTask$A2)
cmrTask$OLD.A1Ts <- mapply(levenshtein.distance,cmrTask$A1,cmrTask$Ts)
cmrTask$OLD.A2Ts <- mapply(levenshtein.distance,cmrTask$A2,cmrTask$Ts)
cmrTask$OLD.mean <- rowMeans(cmrTask[,c('OLD.A1A2','OLD.A1Ts','OLD.A2Ts')])
cmrTask$PLD.A1A2 <- mapply(levenshtein.distance,cmrTask$pA1,cmrTask$pA2)
cmrTask$PLD.A1Ts <- mapply(levenshtein.distance,cmrTask$pA1,cmrTask$pTs)
cmrTask$PLD.A2Ts <- mapply(levenshtein.distance,cmrTask$pA2,cmrTask$pTs)
cmrTask$PLD.mean <- rowMeans(cmrTask[,c('PLD.A1A2','PLD.A1Ts','PLD.A2Ts')])
write.csv(cmrTask,file='Selected_Words_Conditions.csv',row.names=FALSE)

# compare trial-wise OLD or PLD between the four DI conditions
cmr.DIs <- seq(NumOfWdsUnit*4+1,NumOfWdsUnit*8)
DistanceComparison <- lapply(cmrTask[cmr.DIs,c('OLD.mean','PLD.mean')],
                             function(x) kruskal.test(x,cmrTask$conditions[cmr.DIs]))
cairo_pdf(filename='Distance_Comparison_DI_conditions.pdf',width=8,height=12)
par(mfrow=c(2,1))  # plot comparison with boxplot
boxplot(OLD.mean~conditions,data=cmrTask,main='OLD (Kruskal-Wallis Test)')
text(x=2,y=1,labels=paste('P (DI) =',round(DistanceComparison$OLD.mean$p.value,digits=2)))
boxplot(PLD.mean~conditions,data=cmrTask,main='PLD (Kruskal-Wallis Test)')
text(x=2,y=1,labels=paste('P (DI) =',round(DistanceComparison$PLD.mean$p.value,digits=2)))
dev.off()

# compare three target variables across conditions
words.cmr$conditions <- rep(NA,NumOfWds)
words.cmr$conditions[words.cmr$units==1] <- cmr.conditions[1]
words.cmr$conditions[words.cmr$units==2] <- cmr.conditions[2]
words.cmr$conditions[words.cmr$units==3] <- cmr.conditions[3]
words.cmr$conditions[words.cmr$units==4] <- cmr.conditions[4]
words.cmr$conditions[words.cmr$units %in% c(5,9,13)] <- cmr.conditions[5]
words.cmr$conditions[words.cmr$units %in% c(6,10,14)] <- cmr.conditions[6]
words.cmr$conditions[words.cmr$units %in% c(7,11,15)] <- cmr.conditions[7]
words.cmr$conditions[words.cmr$units %in% c(8,12,16)] <- cmr.conditions[8]
VarComparisonConditions <- lapply(words.cmr[,c('freqlivres','nblettres','nbphons')],
                                  function(x) kruskal.test(x,as.factor(words.cmr$conditions)))
cairo_pdf(filename='Comparison_All_Conditions.pdf')
par(mfrow=c(3,1))
boxplot(freqlivres~conditions,data=words.cmr,main='Word Frequency (Kruskal-Wallis Test)')
text(x=5,y=500,labels=paste('P =',round(VarComparisonConditions$freqlivres$p.value,digits=2)))
boxplot(nblettres~conditions,data=words.cmr,main='Number of Letters (Kruskal-Wallis Test)')
text(x=6,y=3.5,labels=paste('P =',round(VarComparisonConditions$nblettres$p.value,digits=2)))
boxplot(nbphons~conditions,data=words.cmr,main='Number of Phonemes (Kruskal-Wallis Test)')
text(x=6,y=5.5,labels=paste('P =',round(VarComparisonConditions$nbphons$p.value,digits=2)))
dev.off()
write.csv(words.cmr,file='Selected_Words_Info.csv',row.names=FALSE)
sink(file='Selected_Words_Conditions_Statistics.txt')
describeBy(words.cmr,group=words.cmr$conditions)
sink()



