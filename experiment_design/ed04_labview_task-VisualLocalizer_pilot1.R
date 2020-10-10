## SCRIPT to convert fMRI experiment sequence into LabView sequence (.desc) for the two localizers
## and the main task in the CP00 study.
# By WS, 2019-12-14

# clean up
rm(list=ls())

# setup environments
wdir <- '.'
trigger.duration <- 0.067  # trigger duration in LabView in seconds, i.e. 67 ms  
triggers.slice <- 18
TR <- trigger.duration*triggers.slice

## the visual localizer - block design with catch trials
# create fMRI experiment sequence
vloc.create <- TRUE
if (vloc.create){
  # baseline, conditions, and catch trials
  vloc.cond.blks <- rep(c('Words','Consonants'),8)
  vloc.base.blks <- rep('Fixation',16)
  vloc.resp.trls <- sample(rep(c('none','catch'),8))  # randomized
  # combine blocks and trials
  vloc.fseq <- as.vector(rbind(vloc.cond.blks,vloc.base.blks,vloc.resp.trls))
}
# read the stimuli list
vloc.stimuli <- read.csv(file=file.path(wdir,'Stimuli_Visual_Localizer.csv'))
vloc.words <- as.vector(sample(vloc.stimuli[vloc.stimuli$type=='word','stimulus']))
vloc.consonants <- as.vector(sample(vloc.stimuli[vloc.stimuli$type=='consonant','stimulus']))
# create LabView script (.desc) row-wise, time unit (trigger) is 67 ms
ntrls <- 24  # 24 stimuli per block
vloc.dur.stimulus <- 5    # 335ms
vloc.dur.blank <- 2       # 134ms
vloc.dur.fixation <- 168  # 11256ms
vloc.dur.catch <- 5       # 335ms puls a jitter ranged from 13 to 23 triggers (1206 to 1876ms in total)
vloc.desc <- data.frame(CONDITION='Instruction',PHRASE='Détecter : ######',BITMAP='Noir',WAV='Rien',
                        DUREE=90,REPONSE1=0,REPONSE2=0,REPONSE3=0)
for (vloc.tag in vloc.fseq){
  switch(vloc.tag,
         Words={
           vloc.desc.phrase <- as.vector(rbind(vloc.words[1:ntrls],rep('Noir',ntrls)))
           vloc.desc.tmp <- data.frame(CONDITION=rep(vloc.tag,ntrls*2),                           # CONDITION
                                       PHRASE   =rep('Noir',ntrls*2),                             # PHRASE
                                       BITMAP   =rep('Noir',ntrls*2),                             # BITMAP
                                       WAV      =rep('Rien',ntrls*2),                             # WAV
                                       DUREE    =rep(c(vloc.dur.stimulus,vloc.dur.blank),ntrls),  # DUREE
                                       REPONSE1 =rep(0,ntrls*2),                                  # REPONSE1
                                       REPONSE2 =rep(0,ntrls*2),                                  # REPONSE2
                                       REPONSE3 =rep(0,ntrls*2))                                  # REPONSE2 
           vloc.desc.tmp$PHRASE <- vloc.desc.phrase
           vloc.words <- vloc.words[-c(1:ntrls)]
         },
         Consonants={
           vloc.desc.phrase <- as.vector(rbind(vloc.consonants[1:ntrls],rep('Noir',ntrls)))
           vloc.desc.tmp <- data.frame(CONDITION=rep(vloc.tag,ntrls*2),                          
                                       PHRASE   =rep('Noir',ntrls*2),                            
                                       BITMAP   =rep('Noir',ntrls*2),                            
                                       WAV      =rep('Rien',ntrls*2),                            
                                       DUREE    =rep(c(vloc.dur.stimulus,vloc.dur.blank),ntrls), 
                                       REPONSE1 =rep(0,ntrls*2),                                 
                                       REPONSE2 =rep(0,ntrls*2),                                 
                                       REPONSE3 =rep(0,ntrls*2))                                 
           vloc.desc.tmp$PHRASE <- vloc.desc.phrase
           vloc.consonants <- vloc.consonants[-c(1:ntrls)]          
         },
         catch={
           vloc.dur.catch.jitter <- sample(13:23)[1]  # to be checked: jitter distribution?
           vloc.desc.tmp <- rbind(c(vloc.tag,'######','Noir','Rien',vloc.dur.catch,2,0,0),
                                  c(vloc.tag,'+','Noir','Rien',vloc.dur.catch.jitter,0,0,0))
           vloc.desc.tmp <- as.data.frame(vloc.desc.tmp)
           names(vloc.desc.tmp) <- names(vloc.desc)
         },
         Fixation={
           vloc.desc.tmp <- data.frame(CONDITION=vloc.tag,
                                       PHRASE   ='+',
                                       BITMAP   ='Noir',
                                       WAV      ='Rien',
                                       DUREE    =vloc.dur.fixation,
                                       REPONSE1 =0,
                                       REPONSE2 =0,
                                       REPONSE3 =0)
         },
         none={
           next
         }
         )
  vloc.desc <- rbind(vloc.desc,vloc.desc.tmp)
}
# output LabView .desc
ntriggers <- sum(as.numeric(vloc.desc$DUREE))
nTR <- ceiling(ntriggers/triggers.slice)
triggers.add <- nTR*triggers.slice - ntriggers
vloc.desc$DUREE[length(vloc.desc$DUREE)] <- as.numeric(vloc.desc$DUREE[length(vloc.desc$DUREE)]) + triggers.add
sink(file=file.path(wdir,'Stimulation_task-VisualLocalizer_Pilot1.stat'),append=FALSE)
print('For Visual Localizer :')
print(paste('The number of TRs is',nTR))
print(paste('The total scanning time should be',nTR*TR,'seconds or',nTR*TR/60,'minutes'))
sink()
write.table(vloc.desc,file=file.path(wdir,'Stimulation_task-VisualLocalizer_Pilot1.desc'),sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
write.table(vloc.desc,file=file.path(wdir,'Stimulation_task-VisualLocalizerFr_Pilot1.desc'),sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1

