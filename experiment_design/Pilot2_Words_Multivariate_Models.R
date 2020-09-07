## Pilot2 - create RSA models and trial labels

rm(list=ls())

library('vwr')    # levenshtein.distance()
library('R.matlab')
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
# working path
wdir <- '/home/wang/Documents/Projects/SWAP/LabView_Scripts'
pdir <- file.path(wdir,'Pilot2')
setwd(pdir)

# read stimuli
words <- read.csv(file=file.path(pdir,'Pilot2_words_1wordTrials_byRuns.csv'),stringsAsFactors=FALSE)
words$sfname <- iconv(words$ortho,to='ASCII//TRANSLIT')
pwords <- read.csv(file=file.path(pdir,'Pilot2_pseudowords_1wordTrials_byRuns.csv'),stringsAsFactors=FALSE)

# read LabView scripts
run1 <- read.table(file=file.path(pdir,'Stimulation_task-AudioVisAsso1word_Pilot2_Run1.desc'),header=TRUE,stringsAsFactors=FALSE)
run2 <- read.table(file=file.path(pdir,'Stimulation_task-AudioVisAsso1word_Pilot2_Run2.desc'),header=TRUE,stringsAsFactors=FALSE)
run3 <- read.table(file=file.path(pdir,'Stimulation_task-AudioVisAsso1word_Pilot2_Run3.desc'),header=TRUE,stringsAsFactors=FALSE)
run4 <- read.table(file=file.path(pdir,'Stimulation_task-AudioVisAsso1word_Pilot2_Run4.desc'),header=TRUE,stringsAsFactors=FALSE)
run5 <- read.table(file=file.path(pdir,'Stimulation_task-AudioVisAsso1word_Pilot2_Run5.desc'),header=TRUE,stringsAsFactors=FALSE)

# organize stimuli in task order
WA.sfname <- c(run1$WAV[run1$CONDITION=='WA'],
               run2$WAV[run2$CONDITION=='WA'],
               run3$WAV[run3$CONDITION=='WA'],
               run4$WAV[run4$CONDITION=='WA'],
               run5$WAV[run5$CONDITION=='WA'])
WA.ortho <- as.character(sapply(WA.sfname, function(x) words$ortho[words$sfname==x]))
WA.phon  <- as.character(sapply(WA.sfname, function(x) words$phon[words$sfname==x]))

WV.ortho <- c(run1$PHRASE[run1$CONDITION=='WV'],
              run2$PHRASE[run2$CONDITION=='WV'],
              run3$PHRASE[run3$CONDITION=='WV'],
              run4$PHRASE[run4$CONDITION=='WV'],
              run5$PHRASE[run5$CONDITION=='WV'])
WV.phon  <- as.character(sapply(WV.ortho, function(x) words$phon[words$ortho==x]))

PA.sfname <- c(run1$WAV[run1$CONDITION=='PA'],
               run2$WAV[run2$CONDITION=='PA'],
               run3$WAV[run3$CONDITION=='PA'],
               run4$WAV[run4$CONDITION=='PA'],
               run5$WAV[run5$CONDITION=='PA'])
PA.ortho <- as.character(sapply(PA.sfname, function(x) pwords$v2written[pwords$sfname==x]))
PA.phon  <- as.character(sapply(PA.sfname, function(x) pwords$phon[pwords$sfname==x]))

PV.ortho <- c(run1$PHRASE[run1$CONDITION=='PV'],
              run2$PHRASE[run2$CONDITION=='PV'],
              run3$PHRASE[run3$CONDITION=='PV'],
              run4$PHRASE[run4$CONDITION=='PV'],
              run5$PHRASE[run5$CONDITION=='PV'])
PV.phon  <- as.character(sapply(PV.ortho, function(x) pwords$phon[pwords$v2written==x]))

# create RSA models (rank models) for words
words.sort <- c(order(WA.ortho),order(WV.ortho)+60)
words.task <- data.frame(ortho=c(WA.ortho,WV.ortho),phon=c(WA.phon,WV.phon))
words.ldms <- LDM(words.task)
colnames(words.ldms$OLDM) <- c(paste0('WA_',WA.ortho),paste0('WV_',WV.ortho))
colnames(words.ldms$PLDM) <- c(paste0('WA_',WA.ortho),paste0('WV_',WV.ortho))

model.VisualCodingAbstract <- matrix(1,120,120)
model.VisualCodingAbstract[61:120,61:120] <- 0.1
diag(model.VisualCodingAbstract) <- 0

model.VisualCodingOLD <- words.ldms$OLDM * model.VisualCodingAbstract
model.VisualCodingOLD[1:120,1:60] <- 1
model.VisualCodingOLD[1:60,61:120] <- 1
diag(model.VisualCodingOLD) <- 0

model.AuditoryCodingAbstract <- matrix(1,120,120)
model.AuditoryCodingAbstract[1:60,1:60] <- 0.1
diag(model.AuditoryCodingAbstract) <- 0

model.AuditoryCodingPLD <- words.ldms$PLDM * model.AuditoryCodingAbstract
model.AuditoryCodingPLD[61:120,1:120] <- 1
model.AuditoryCodingPLD[1:60,61:120] <- 1
diag(model.AuditoryCodingPLD) <- 0

model.MultimodalGeoMean <- sqrt(words.ldms$OLDM * words.ldms$PLDM) * 0.1
model.MultimodalAthMean <- (words.ldms$OLDM + words.ldms$PLDM)/2 * 0.1

model.HeteromodalAbstract <- model.VisualCodingAbstract * model.AuditoryCodingAbstract
model.HeteromodalXLD <- model.VisualCodingOLD * model.AuditoryCodingPLD

writeMat(con=file.path(pdir,'Pilot2_RSA_models_words.mat'),
         words_order=words.sort,
         words_OLD=words.ldms$OLDM*0.1,
         words_PLD=words.ldms$PLDM*0.1,        
         words_AuditoryCodingAbstract=model.AuditoryCodingAbstract,
         words_AuditoryCodingPLD=model.AuditoryCodingPLD,
         words_VisualCodingAbstract=model.VisualCodingAbstract,
         words_VisualCodingOLD=model.VisualCodingOLD,
         words_MultimodalAthMean=model.MultimodalAthMean,
         words_MultimodalGeoMean=model.MultimodalGeoMean,
         words_HeteromodalAbstract=model.HeteromodalAbstract,
         words_HeteromodalXLD=model.HeteromodalXLD)

# create RSA models (rank models) for pseudowords
pwords.sort <- c(order(PA.ortho),order(PV.ortho)+60)
pwords.task <- data.frame(ortho=c(PA.ortho,PV.ortho),phon=c(PA.phon,PV.phon))
pwords.ldms <- LDM(pwords.task)
colnames(pwords.ldms$OLDM) <- c(paste0('PA_',PA.ortho),paste0('PV_',PV.ortho))
colnames(pwords.ldms$PLDM) <- c(paste0('PA_',PA.ortho),paste0('PV_',PV.ortho))

model.VisualCodingOLD <- pwords.ldms$OLDM * model.VisualCodingAbstract
model.VisualCodingOLD[1:120,1:60] <- 1
model.VisualCodingOLD[1:60,61:120] <- 1
diag(model.VisualCodingOLD) <- 0

model.AuditoryCodingPLD <- pwords.ldms$PLDM * model.AuditoryCodingAbstract
model.AuditoryCodingPLD[61:120,1:120] <- 1
model.AuditoryCodingPLD[1:60,61:120] <- 1
diag(model.AuditoryCodingPLD) <- 0

model.MultimodalGeoMean <- sqrt(pwords.ldms$OLDM * pwords.ldms$PLDM) * 0.1
model.MultimodalAthMean <- (pwords.ldms$OLDM + pwords.ldms$PLDM)/2 * 0.1

model.HeteromodalXLD <- model.VisualCodingOLD * model.AuditoryCodingPLD

writeMat(con=file.path(pdir,'Pilot2_RSA_models_pseudowords.mat'),
         pwords_order=pwords.sort,
         pwords_OLD=pwords.ldms$OLDM*0.1,
         pwords_PLD=pwords.ldms$PLDM*0.1,        
         pwords_AuditoryCodingAbstract=model.AuditoryCodingAbstract,
         pwords_AuditoryCodingPLD=model.AuditoryCodingPLD,
         pwords_VisualCodingAbstract=model.VisualCodingAbstract,
         pwords_VisualCodingOLD=model.VisualCodingOLD,
         pwords_MultimodalAthMean=model.MultimodalAthMean,
         pwords_MultimodalGeoMean=model.MultimodalGeoMean,
         pwords_HeteromodalAbstract=model.HeteromodalAbstract,
         pwords_HeteromodalXLD=model.HeteromodalXLD)

# extract trial labels for MVPA
labels <- data.frame(stimuli=c(WA.ortho,WV.ortho,PA.ortho,PV.ortho),
                     conditions=rep(c('WA','WV','PA','PV'),each=60),
                     lexicon=rep(c('word','pseudoword'),each=120),
                     vistrain=rep(c(0,-1,0,-1),each=60),  # for PredefinedSplit() in sklearn
                     audtrain=rep(c(-1,0,-1,0),each=60),  # for PredefinedSplit() in sklearn                 
                     runs=rep(rep(c('run1','run2','run3','run4','run5'),each=12),4))
write.csv(labels,file=file.path(pdir,'trial_labels.csv'),row.names=FALSE)