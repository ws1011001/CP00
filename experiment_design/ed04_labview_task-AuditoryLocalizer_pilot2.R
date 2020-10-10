## ---------------------------
## [script name] 
##
## SCRIPT to ...
##
## By Shuai Wang, [date]
##
## ---------------------------
## Notes: always show a fixation
##   
##
## ---------------------------

## clean up
rm(list=ls())
## ---------------------------

## set environment (packages, functions, working path etc.)
# working path
wdir <- '/data/agora/Chotiga_VOTmultimod/experiment_design/LabView_Scripts/'
pdir <- file.path(wdir,'Pilot2')
setwd(pdir)
# scan parameters
trigger.duration <- 0.067              # trigger duration in LabView in seconds, i.e. 67 ms  
triggers.slice <- 18
TR <- trigger.duration*triggers.slice  # 1206ms
## ---------------------------

## create fMRI experiment sequence
cond.blks.num <- 32
aloc.create <- TRUE
if (aloc.create){
  # baseline, conditions, and catch trials
  aloc.cond.rep <- 0
  while (aloc.cond.rep!=cond.blks.num){
    # randomized but no repeated conditions
    aloc.cond.blks <- as.vector(replicate(cond.blks.num/4,sample(c('Words','Pseudowords','Vocoded','Rest'))))  
    aloc.cond.rep <- length(rle(aloc.cond.blks)$length)
  }
  aloc.resp.trls <- sample(rep(c('none','none','none','catch'),cond.blks.num/4))  # randomized
  # combine blocks and trials
  aloc.fseq <- as.vector(rbind(aloc.cond.blks,aloc.resp.trls))
}
## ---------------------------

## generate LabView script
# read the stimuli list
aloc.stimuli <- read.csv(file=file.path(wdir,'Stimuli_Auditory_Localizer.csv'))
aloc.words <- as.vector(sample(aloc.stimuli[aloc.stimuli$type=='word','stimulus']))
aloc.pseudowords <- as.vector(sample(aloc.stimuli[aloc.stimuli$type=='pseudoword','stimulus']))
aloc.vocoded <- as.vector(sample(aloc.stimuli[aloc.stimuli$type=='vocoded','stimulus']))
# set task parameters (in number of triggers)
ntrls <- 12              # 24 stimuli per block
aloc.dur.stimulus <- 12  # 804ms
aloc.dur.blank <- 3      # 201ms
aloc.dur.rest <- 180     # 12060ms
aloc.dur.catch <- 5      # 335ms puls a jitter ranged from 13 to 23 triggers (1206 to 1876ms in total)
#aloc.instruction <- 'écoutez attentivement. Détecter : le son "bip".'
# create LabView script (.desc) row-wise, time unit (trigger) is 67 ms
aloc.desc <- data.frame(CONDITION='Instruction',PHRASE='+',BITMAP='Noir',WAV='Rien',
                        DUREE=72,REPONSE1=0,REPONSE2=0,REPONSE3=0)
for (aloc.tag in aloc.fseq){
  switch(aloc.tag,
         Words={
           aloc.desc.wav <- as.vector(rbind(aloc.words[1:ntrls],rep('Rien',ntrls)))
           aloc.desc.tmp <- data.frame(CONDITION=rep(aloc.tag,ntrls*2),                           # CONDITION
                                       PHRASE   =rep('+',ntrls*2),                                # PHRASE
                                       BITMAP   =rep('Noir',ntrls*2),                             # BITMAP
                                       WAV      =rep('Rien',ntrls*2),                             # WAV
                                       DUREE    =rep(c(aloc.dur.stimulus,aloc.dur.blank),ntrls),  # DUREE
                                       REPONSE1 =rep(0,ntrls*2),                                  # REPONSE1
                                       REPONSE2 =rep(0,ntrls*2),                                  # REPONSE2
                                       REPONSE3 =rep(0,ntrls*2))                                  # REPONSE2 
           aloc.desc.tmp$WAV <- aloc.desc.wav
           aloc.words <- aloc.words[-c(1:ntrls)]
         },
         Pseudowords={
           aloc.desc.wav <- as.vector(rbind(aloc.pseudowords[1:ntrls],rep('Rien',ntrls)))
           aloc.desc.tmp <- data.frame(CONDITION=rep(aloc.tag,ntrls*2),                          
                                       PHRASE   =rep('+',ntrls*2),                            
                                       BITMAP   =rep('Noir',ntrls*2),                            
                                       WAV      =rep('Rien',ntrls*2),                            
                                       DUREE    =rep(c(aloc.dur.stimulus,aloc.dur.blank),ntrls), 
                                       REPONSE1 =rep(0,ntrls*2),                                 
                                       REPONSE2 =rep(0,ntrls*2),                                 
                                       REPONSE3 =rep(0,ntrls*2))                                 
           aloc.desc.tmp$WAV <- aloc.desc.wav
           aloc.pseudowords <- aloc.pseudowords[-c(1:ntrls)]          
         },
         Vocoded={
           aloc.desc.wav <- as.vector(rbind(aloc.vocoded[1:ntrls],rep('Rien',ntrls)))
           aloc.desc.tmp <- data.frame(CONDITION=rep(aloc.tag,ntrls*2),                          
                                       PHRASE   =rep('+',ntrls*2),                            
                                       BITMAP   =rep('Noir',ntrls*2),                            
                                       WAV      =rep('Rien',ntrls*2),                            
                                       DUREE    =rep(c(aloc.dur.stimulus,aloc.dur.blank),ntrls), 
                                       REPONSE1 =rep(0,ntrls*2),                                 
                                       REPONSE2 =rep(0,ntrls*2),                                 
                                       REPONSE3 =rep(0,ntrls*2))                                 
           aloc.desc.tmp$WAV <- aloc.desc.wav
           aloc.vocoded <- aloc.vocoded[-c(1:ntrls)]          
         },        
         catch={
           aloc.dur.catch.jitter <- sample(13:23)[1]  # to be checked: jitter distribution?          
           aloc.desc.tmp <- rbind(c(aloc.tag,'+','Noir','BEEP',aloc.dur.catch,2,0,0),
                                  c(aloc.tag,'+','Noir','Rien',aloc.dur.catch.jitter,0,0,0))
           aloc.desc.tmp <- as.data.frame(aloc.desc.tmp)
           names(aloc.desc.tmp) <- names(aloc.desc)
         },
         Rest={
           aloc.desc.tmp <- data.frame(CONDITION=aloc.tag,
                                       PHRASE   ='+',
                                       BITMAP   ='Noir',
                                       WAV      ='Rien',
                                       DUREE    =aloc.dur.rest,
                                       REPONSE1 =0,
                                       REPONSE2 =0,
                                       REPONSE3 =0)
         },
         none={
           next
         }
         )
  aloc.desc <- rbind(aloc.desc,aloc.desc.tmp)
}
# compensate TRs
ntriggers <- sum(as.numeric(aloc.desc$DUREE))
nTR <- ceiling(ntriggers/triggers.slice)
triggers.add <- nTR*triggers.slice - ntriggers
aloc.desc$DUREE[length(aloc.desc$DUREE)] <- as.numeric(aloc.desc$DUREE[length(aloc.desc$DUREE)]) + triggers.add
## ---------------------------

## output
# save R data
save(list=ls(),file=file.path(pdir,'Stimulation_task-AuditoryLocalizer_Pilot2.Rdata'))
# output timings
sink(file=file.path(pdir,'Stimulation_task-AuditoryLocalizer_Pilot2.stat'),append=FALSE)
print('For Auditory Localizer :')
print(paste('The number of TRs is',nTR))
print(paste('The total scanning time should be',nTR*TR,'seconds or',nTR*TR/60,'minutes'))
sink()
# output LabView .desc
write.table(aloc.desc,file=file.path(pdir,'Stimulation_task-AuditoryLocalizer_Pilot2.desc'),
            sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
write.table(aloc.desc,file=file.path(pdir,'Stimulation_task-AuditoryLocalizerFr_Pilot2.desc'),
            sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1
## ---------------------------

