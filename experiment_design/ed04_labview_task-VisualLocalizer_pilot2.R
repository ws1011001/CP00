## ---------------------------
## [script name] 
##
## SCRIPT to ...
##
## By Shuai Wang, [date]
##
## ---------------------------
## Notes:
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
trigger.duration <- 0.082              # trigger duration in LabView in seconds, i.e. 82 ms  
triggers.slice <- 14
TR <- trigger.duration*triggers.slice  # 1148ms
## ---------------------------

## create fMRI experiment sequence
vloc.create <- TRUE
if (vloc.create){
  # baseline, conditions, and catch trials
  vloc.cond.blks <- sample(rep(c('Words','Consonants'),8))  # randomized
  vloc.resp.trls <- sample(rep(c('none','catch'),8))        # randomized
  vloc.base.blks <- rep('Fixation',16)
  # combine blocks and trials
  vloc.fseq <- as.vector(rbind(vloc.cond.blks,vloc.base.blks,vloc.resp.trls))
}
## ---------------------------

## generate LabView script
# read the stimuli list
vloc.stimuli <- read.csv(file=file.path(wdir,'Stimuli_Visual_Localizer_TEST82msSequence.csv'))
vloc.words <- as.vector(sample(vloc.stimuli[vloc.stimuli$type=='word','stimulus']))
vloc.consonants <- as.vector(sample(vloc.stimuli[vloc.stimuli$type=='consonant','stimulus']))
# set task parameters (in number of triggers)
ntrls <- 24               # 24 stimuli per block
vloc.dur.stimulus <- 4    # 328ms
vloc.dur.blank <- 2       # 164ms
vloc.dur.fixation <- 144  # 11808ms
vloc.dur.catch <- 4       # 328ms puls a jitter ranged from 15 to 18 triggers (1230 to 1804ms in total)
#vloc.instruction <- 'Lisez silencieusement. Détecter : ######'
# create LabView script (.desc) row-wise, time unit (trigger) is 82 ms
vloc.desc <- data.frame(CONDITION='BlankStart',PHRASE='+',BITMAP='Noir',WAV='Rien',
                        DUREE=56,REPONSE1=0,REPONSE2=0,REPONSE3=0)
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
           vloc.dur.catch.jitter <- sample(15:18)[1]  # to be checked: jitter distribution?
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
# compensate TRs
ntriggers <- sum(as.numeric(vloc.desc$DUREE))
nTR <- ceiling(ntriggers/triggers.slice)
triggers.add <- nTR*triggers.slice - ntriggers
vloc.desc$DUREE[length(vloc.desc$DUREE)] <- as.numeric(vloc.desc$DUREE[length(vloc.desc$DUREE)]) + triggers.add
## ---------------------------

## output
# save R data
save(list=ls(),file=file.path(pdir,'Stimulation_task-VisualLocalizer_Pilot2.Rdata'))
# output timings
sink(file=file.path(pdir,'Stimulation_task-VisualLocalizer_Pilot2.stat'),append=FALSE)
print('For Visual Localizer :')
print(paste('The number of TRs is',nTR))
print(paste('The total scanning time should be',nTR*TR,'seconds or',nTR*TR/60,'minutes'))
sink()
# output LabView .desc
write.table(vloc.desc,file=file.path(pdir,'Stimulation_task-VisualLocalizer_Pilot2.desc'),
            sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
write.table(vloc.desc,file=file.path(pdir,'Stimulation_task-VisualLocalizerFr_Pilot2.desc'),
            sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1
## ---------------------------





