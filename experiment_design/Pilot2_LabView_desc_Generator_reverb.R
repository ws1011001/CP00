## ---------------------------
## [script name] Pilot2_LabView_desc_Generator_reverb.R
##
## SCRIPT to test the reverb correction method by comparing the original sounds and the 'reduced' versions.
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
wdir <- '/media/wang/BON/Projects/CP00/experiment_design/LabView_Scripts/Sound_Files'
pdir <- file.path(wdir,'Stimuli_Reverb_Correction')
setwd(pdir)
# read bad stimuli list
badstim <- read.table(file=file.path(pdir,'bad_reduced_words.txt'),stringsAsFactors=FALSE)$V1
badstim <- paste0(badstim,'_reduced')
nstim <- length(badstim)
# scan parameters
trigger.duration <- 0.082              # trigger duration in LabView in seconds, i.e. 82 ms  
triggers.slice <- 14
TR <- trigger.duration*triggers.slice  # 1148ms
aloc.dur.stimulus <- 10  # 820ms
aloc.dur.blank <- 15
## ---------------------------

## generate LabView script
# create LabView script (.desc) row-wise, time unit (trigger) is 67 ms
aloc.desc <- data.frame(CONDITION='Instruction',PHRASE='+',BITMAP='Noir',WAV='Rien',
                        DUREE=42,REPONSE1=0,REPONSE2=0,REPONSE3=0)
aloc.desc.wav <- as.vector(rbind(badstim,rep('Rien',nstim)))
aloc.desc.tmp <- data.frame(CONDITION=rep('BAD',nstim*2),                              # CONDITION
                            PHRASE   =rep('+',nstim*2),                                # PHRASE
                            BITMAP   =rep('Noir',nstim*2),                             # BITMAP
                            WAV      =rep('Rien',nstim*2),                             # WAV
                            DUREE    =rep(c(aloc.dur.stimulus,aloc.dur.blank),nstim),  # DUREE
                            REPONSE1 =rep(0,nstim*2),                                  # REPONSE1
                            REPONSE2 =rep(0,nstim*2),                                  # REPONSE2
                            REPONSE3 =rep(0,nstim*2))                                  # REPONSE2 
aloc.desc.tmp$WAV <- aloc.desc.wav
aloc.desc <- rbind(aloc.desc,aloc.desc.tmp)
# compensate TRs
ntriggers <- sum(as.numeric(aloc.desc$DUREE))
nTR <- ceiling(ntriggers/triggers.slice)
triggers.add <- nTR*triggers.slice - ntriggers
aloc.desc$DUREE[length(aloc.desc$DUREE)] <- as.numeric(aloc.desc$DUREE[length(aloc.desc$DUREE)]) + triggers.add
## ---------------------------

## output
# save R data
save(list=ls(),file=file.path(pdir,'Stimulation_task-ReverbReduced_Pilot2.Rdata'))
# output timings
sink(file=file.path(pdir,'Stimulation_task-ReverbReduced_Pilot2.stat'),append=FALSE)
print('For Reverb task with original stimuli :')
print(paste('The number of TRs is',nTR))
print(paste('The total scanning time should be',nTR*TR,'seconds or',nTR*TR/60,'minutes'))
sink()
# output LabView .desc
write.table(aloc.desc,file=file.path(pdir,'Stimulation_task-ReverbReduced_Pilot2.desc'),
            sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
write.table(aloc.desc,file=file.path(pdir,'Stimulation_task-ReverbReducedFr_Pilot2.desc'),
            sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1
## ---------------------------
