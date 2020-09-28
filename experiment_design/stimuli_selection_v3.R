## SCRIPT to select words as stimuli for the cross-modal repetition task in the fMRI study - CP00.
# BY WS, 2019-11-07.

## Lexique query: number of letters      [3,6]
##                number of syllables    [1,2]
##                word frequency (books) > 5
##                word frequency (oral)  > 2
##                no homophone words

## Variables to be matched across eight conditions (Target Variables): number of letters, number of 
## phonemes, 50% monosyllable and 50% bisyllable, word frequency (freqlivres and freqfilms2), OLD20, PLD20 and 
## Uniqueness Point for spoken words (puphon).
## Notes: - Distance measures (i.e. OLD20 and PLD20) are more precise than the number of ortho. or
##          phono. neighbours.
##        - Uniqueness Point might be meaningless for reading, therefore only puphon was included.
##        - Exact ortho. and phono. distance between words were calucated for each trial of the DI
##          conditions, and the trial-wise means were compared across the DI conditions. See the
##          corresponding results (i.e.) to make sure there is no significant differences.

## ???Variables to be controled for each single trial: orthographic/phonological distance between 
## adjacent words.


# clean up
rm(list=ls())

# setup environments
library('psych')                 # describeBy()
library('anticlust')             # anticlustering()
library('vwr')                   # levenshtein.distance()
library('MatchIt')               # matchit()
library('PerformanceAnalytics')  # chart.Correlation()
library('mailR')                 # send.mail()
rdir <- paste0('Words_Selection_',
               format(Sys.time(),"%Y_%m%d_%H%M"))  # results directory
dir.create(path=rdir)                              # save all results into this directory


# send email to my Gmail once the codes start
send.mail(from='ws1011001@163.com',to='ws1011001@gmail.com',
          subject='Words Selection Start!',
          body=paste('Start the job at',Sys.time(),'Please check it at the PC in the O.S.'),
          smtp=list(host.name='smtp.163.com',port=465,
                    user.name='ws1011001@163.com',
                    passwd='122388myn',
                    ssl=T),
          authenticate=T,send=T)


# read the queried words dataset
lexique.words <- read.csv('Lexique_Words_v3.csv')
words.all <- lexique.words[order(lexique.words$nbsyll),]
words.all <- words.all[words.all$freqfilms2>2,]  # remove words with oral frequency < 2

# check words that contain special letters in French 
charsFrench <- 'à|â|ä|æ|ç|è|é|ê|ë|î|ï|ô|œ|ù|û|ü'
charsFrenchIdx <- grepl(charsFrench,words.all$ortho)
words.all$charsFrench <- charsFrenchIdx

# backup the word pool
save(words.all,file='Lexique_Words_v4.Rdata')

# choose the number of words and the target variables
NumOfWdsUnit <- 24                   # split 8 conditions into 16 units with equal number of words
NumOfUnits <- 16                     # SI conditions: 4x1; DI conditions: 4x3; 16 units in total
NumOfWds <- NumOfWdsUnit*NumOfUnits  # total number of words
#VarMatched <- c('nbsyll','freqlivres','freqfilms2','nblettres','nbphons','voisphon','voisorth','puorth','puphon')
VarMatched <- c('nbsyll','freqlivres','freqfilms2','nblettres','nbphons','old20','pld20','puphon')

# check the relationships between the target variables for all words
cairo_pdf(filename=file.path(rdir,'Spearman_Correlations_Between_Target_Variables_All_Words.pdf'),
          width=length(VarMatched),height=length(VarMatched))
chart.Correlation(words.all[,VarMatched],histogram=TRUE,method='spearman')  
dev.off()

# select words and match variables
UnitComparisonP <- rep(0,length(VarMatched))
while (any(UnitComparisonP < 0.1)){
  # generate random index
  randIdxMo <- sample(c(rep(1,NumOfWds/2),rep(0,sum(words.all$nbsyll==1)-NumOfWds/2)))
  randIdxBi <- sample(c(rep(1,NumOfWds/2),rep(0,sum(words.all$nbsyll==2)-NumOfWds/2))) 
  randIdx <- as.logical(c(randIdxMo,randIdxBi))
  # pre-select words randomly with target variables
  words.pre <- words.all[randIdx,VarMatched]
  # split the pre-selected words into $NumOfUnits matched units
  words.sel <- anticlustering(features=words.pre[,-1],K=NumOfUnits,
                              objective='variance',categories=words.pre[,1])
  # compare target variables across all units with Kruskal-Wallis Rank Sum Test
  UnitComparison <- lapply(words.pre, function(x) kruskal.test(x,as.factor(words.sel)))
  UnitComparisonP <- unlist(lapply(UnitComparison, function(x) x$p.value))
}

# check the matches and save the results
print(paste('#####Quick Check - Units##### The Comparison results are: P =',UnitComparisonP))
cmrIdx <- randIdx                                # cmr stands for the cross-modal repetition task
words.cmr <- words.all[cmrIdx,]  
words.cmr$units <- words.sel
words.cmr <- words.cmr[order(words.cmr$units),]  # sort words by units
save(words.cmr,cmrIdx,words.sel,UnitComparison,file=file.path(rdir,'Selected_Words_byUnits.Rdata'))

# output the statistics by units
sink(file=file.path(rdir,'Statistics_byUnits.txt'))
print('#####Descriptive Statistics#####')
print(describeBy(words.cmr,group=words.cmr$units),digits=4)
print('#####Kruskal-Wallis Test Between Units#####')
print(UnitComparison,digits=4)
sink()


# assign the 16 matched units into 8 conditions with controlling the target variables
cmr.conditions <- c('SISMa','SISMv','SIDMa','SIDMv','DISMa','DISMv','DIDMa','DIDMv') 
words.cmr$conditions <- rep('',NumOfWds)
words.cmr$unitIdx <- rep(0,NumOfWds)
CondComparisonP <- rep(0,length(VarMatched))
while (any(CondComparisonP < 0.1)){
  randUnits <- sample(1:NumOfUnits)
  for (i in 1:4){
    # assign the first 4 units to the 4 SI conditions
    words.cmr$conditions[words.cmr$units %in% randUnits[i]] <- cmr.conditions[i]
    # assign the rest 12 units to the 4 DI conditions
    words.cmr$conditions[words.cmr$units %in% randUnits[(i*3+2):(i*3+4)]] <- cmr.conditions[i+4]
    # generate index that assign units to contidtions
    words.cmr$unitIdx[words.cmr$units==randUnits[i]] <- i
    words.cmr$unitIdx[words.cmr$units==randUnits[i*3+2]] <- i*3+2
    words.cmr$unitIdx[words.cmr$units==randUnits[i*3+3]] <- i*3+3
    words.cmr$unitIdx[words.cmr$units==randUnits[i*3+4]] <- i*3+4   
  }
  # compare target variables across all conditions with Kruskal-Wallis Rank Sum Test
  CondComparison <- lapply(words.cmr[,VarMatched],
                           function(x) kruskal.test(x,as.factor(words.cmr$conditions)))
  CondComparisonP <- unlist(lapply(CondComparison, function(x) x$p.value))
}
print(paste('#####Quick Check - Conditions##### The Comparison results are: P =',CondComparisonP))

# generate the trial list for experimental presentation
words.cmr <- words.cmr[order(words.cmr$unitIdx),]  # sort word by unit index
cmr.trials <- data.frame('conditions'=rep(cmr.conditions,each=NumOfWdsUnit),
                         'A1'=words.cmr$ortho[words.cmr$unitIdx %in% c(1:4,5,8,11,14)],
                         'A2'=words.cmr$ortho[words.cmr$unitIdx %in% c(1:4,6,9,12,15)],
                         'Ts'=words.cmr$ortho[words.cmr$unitIdx %in% c(1:4,7,10,13,16)],
                         'pA1'=words.cmr$phon[words.cmr$unitIdx %in% c(1:4,5,8,11,14)],
                         'pA2'=words.cmr$phon[words.cmr$unitIdx %in% c(1:4,6,9,12,15)],
                         'pTs'=words.cmr$phon[words.cmr$unitIdx %in% c(1:4,7,10,13,16)],
                         'cA1'=words.cmr$conditions[words.cmr$unitIdx %in% c(1:4,5,8,11,14)],
                         'cA2'=words.cmr$conditions[words.cmr$unitIdx %in% c(1:4,6,9,12,15)],
                         'cTs'=words.cmr$conditions[words.cmr$unitIdx %in% c(1:4,7,10,13,16)])

# compare trial-wise means (i.e. OLD, PLD) across the four DI conditions
cmr.trials$OLD.A1A2 <- mapply(levenshtein.distance,cmr.trials$A1,cmr.trials$A2)
cmr.trials$OLD.A1Ts <- mapply(levenshtein.distance,cmr.trials$A1,cmr.trials$Ts)
cmr.trials$OLD.A2Ts <- mapply(levenshtein.distance,cmr.trials$A2,cmr.trials$Ts)
cmr.trials$OLD.mean <- rowMeans(cmr.trials[,c('OLD.A1A2','OLD.A1Ts','OLD.A2Ts')])
cmr.trials$PLD.A1A2 <- mapply(levenshtein.distance,cmr.trials$pA1,cmr.trials$pA2)
cmr.trials$PLD.A1Ts <- mapply(levenshtein.distance,cmr.trials$pA1,cmr.trials$pTs)
cmr.trials$PLD.A2Ts <- mapply(levenshtein.distance,cmr.trials$pA2,cmr.trials$pTs)
cmr.trials$PLD.mean <- rowMeans(cmr.trials[,c('PLD.A1A2','PLD.A1Ts','PLD.A2Ts')])
cmr.DIs <- seq(NumOfWdsUnit*4+1,NumOfWdsUnit*8)  # create index for the 4 DI conditions
DistComparison <- lapply(cmr.trials[cmr.DIs,c('OLD.mean','PLD.mean')],
                         function(x) kruskal.test(x,cmr.trials$conditions[cmr.DIs]))

# save the matched words and the trial list 
save(words.cmr,cmr.conditions,CondComparison,cmr.trials,DistComparison,
     file=file.path(rdir,'Selected_Words_byConditions.Rdata'))
write.csv(words.cmr,file=file.path(rdir,'Selected_Words_byConditions.csv'),row.names=FALSE)
write.csv(cmr.trials,file=file.path(rdir,'Selected_Words_byTrials.csv'),row.names=FALSE)

# output the statistics by conditions
sink(file=file.path(rdir,'Statistics_byConditions.txt'))
print('#####Descriptive Statistics#####')
print(describeBy(words.cmr,group=words.cmr$conditions),digits=4)
print('#####Kruskal-Wallis Test Between Conditions#####')
print(CondComparison,digits=4)
print('#####Kruskal-Wallis Test Between DI Conditions - OLD and PLD#####')
print(DistComparison,digits=4)
sink()
cairo_pdf(filename=file.path(rdir,'Statistics_byConditions.pdf'),width=8,height=40)
par(mfrow=c(10,1))
boxplot(nbsyll~conditions,data=words.cmr,
        main=paste('Number of Syllables', 
                   '(Kruskal-Wallis Test',
                   'P =',round(CondComparison$nbsyll$p.value,digits=2),')'))
boxplot(freqlivres~conditions,data=words.cmr,
        main=paste('Word Frequency Books', 
                   '(Kruskal-Wallis Test',
                   'P =',round(CondComparison$freqlivres$p.value,digits=2),')'))
boxplot(freqfilms2~conditions,data=words.cmr,
        main=paste('Word Frequency Subtitles', 
                   '(Kruskal-Wallis Test',
                   'P =',round(CondComparison$freqfilms2$p.value,digits=2),')'))
boxplot(nblettres~conditions,data=words.cmr,
        main=paste('Number of Letters', 
                   '(Kruskal-Wallis Test',
                   'P =',round(CondComparison$nblettres$p.value,digits=2),')'))
boxplot(nbphons~conditions,data=words.cmr,
        main=paste('Number of Phonemes', 
                   '(Kruskal-Wallis Test',
                   'P =',round(CondComparison$nbphons$p.value,digits=2),')'))
boxplot(old20~conditions,data=words.cmr,
        main=paste('OLD20', 
                   '(Kruskal-Wallis Test',
                   'P =',round(CondComparison$old20$p.value,digits=2),')'))
boxplot(pld20~conditions,data=words.cmr,
        main=paste('PLD20', 
                   '(Kruskal-Wallis Test',
                   'P =',round(CondComparison$pld20$p.value,digits=2),')'))
boxplot(puphon~conditions,data=words.cmr,
        main=paste('Uniqueness Point Phonology', 
                   '(Kruskal-Wallis Test',
                   'P =',round(CondComparison$puphon$p.value,digits=2),')'))
boxplot(OLD.mean~conditions,data=cmr.trials,
        main=paste('trial-wise mean OLD', 
                   '(Kruskal-Wallis Test for DIs',
                   'P =',round(DistComparison$OLD.mean$p.value,digits=2),')'))
boxplot(PLD.mean~conditions,data=cmr.trials,
        main=paste('trial-wise mean PLD', 
                   '(Kruskal-Wallis Test for DIs',
                   'P =',round(DistComparison$PLD.mean$p.value,digits=2),')'))
dev.off()

# send email to my Gmail once the codes end
send.mail(from='ws1011001@163.com',to='ws1011001@gmail.com',
          subject='Words Selection Done!',
          body=paste('Finish the job at',Sys.time(),'Please check it at the PC in the O.S.'),
          smtp=list(host.name='smtp.163.com',port=465,
                    user.name='ws1011001@163.com',
                    passwd='122388myn',
                    ssl=T),
          authenticate=T,send=T)


###### Backup Codes ######
#cairo_pdf(filename='Statistics_byConditions.pdf',width=8,height=length(VarMatched)+2)
#par(mfrow=c(length(VarMatched)+2,1)) 
#for (i in 1:length(VarMatched)){
#  boxplot(OLD.mean~conditions,data=cmrTask,main='OLD (Kruskal-Wallis Test)')
#  text(x=2,y=1,labels=paste('P (DI) =',round(DistanceComparison$OLD.mean$p.value,digits=2))) 
#}
#boxplot(OLD.mean~conditions,data=cmrTask,main='OLD (Kruskal-Wallis Test)')
#text(x=2,y=1,labels=paste('P (DI) =',round(DistanceComparison$OLD.mean$p.value,digits=2)))
#boxplot(PLD.mean~conditions,data=cmrTask,main='PLD (Kruskal-Wallis Test)')
#text(x=2,y=1,labels=paste('P (DI) =',round(DistanceComparison$PLD.mean$p.value,digits=2)))
#dev.off()


#cairo_pdf(filename='Comparison_All_Conditions.pdf')
#par(mfrow=c(3,1))
#boxplot(freqlivres~conditions,data=words.cmr,main='Word Frequency (Kruskal-Wallis Test)')
#text(x=5,y=500,labels=paste('P =',round(VarComparisonConditions$freqlivres$p.value,digits=2)))
#boxplot(nblettres~conditions,data=words.cmr,main='Number of Letters (Kruskal-Wallis Test)')
#text(x=6,y=3.5,labels=paste('P =',round(VarComparisonConditions$nblettres$p.value,digits=2)))
#boxplot(nbphons~conditions,data=words.cmr,main='Number of Phonemes (Kruskal-Wallis Test)')
#text(x=6,y=5.5,labels=paste('P =',round(VarComparisonConditions$nbphons$p.value,digits=2)))
#dev.off()


## calculate orthographic distance and phonological distance for each pair of words
#dist.ortho <- matrix(NA,NumOfWds,NumOfWds)
#dist.phono <- matrix(NA,NumOfWds,NumOfWds)
#for (iW in 1:NumOfWds){
#  dist.ortho[,iW] <- levenshtein.distance(words.cmr$ortho[iW],words.cmr$ortho)
#  dist.phono[,iW] <- levenshtein.distance(words.cmr$phon[iW],words.cmr$phon) 
#}
#colnames(dist.ortho) <- words.cmr$ortho
#row.names(dist.ortho) <- words.cmr$ortho
#write.csv(dist.ortho,file='orthogrphic_distance_matrix.csv')
#colnames(dist.phono) <- words.cmr$ortho
#row.names(dist.phono) <- words.cmr$ortho
#write.csv(dist.phono,file='phonological_distance_matrix.csv')
