## SCRIPT to convert fMRI experiment sequence into LabView sequence (.desc) for the two localizers
## and the main task in the CP00 study.
# By WS, 2019-12-14

# clean up
rm(list=ls())

# setup environments
wdir <- '.'
trigger.duration <- 0.067  # trigger duration in LabView in seconds, i.e. 67 ms  

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
           vloc.desc.tmp <- rbind(c(vloc.tag,'######','Noir','Rien',vloc.dur.catch,0,0,0),
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
write.table(vloc.desc,file=file.path(wdir,'Stimulation_task-VisualLocalizer_TEST.desc'),sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
write.table(vloc.desc,file=file.path(wdir,'Stimulation_task-VisualLocalizerFr_TEST.desc'),sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1


## the audiotry localizer - block design with catch trials
# create fMRI experiment sequence
aloc.create <- TRUE
if (aloc.create){
  # baseline, conditions, and catch trials
  aloc.cond.blks <- as.vector(replicate(8,sample(c('Words','Pseudowords','Vocoded'))))  # randomized
  aloc.base.blks <- rep('Rest',24)
  aloc.resp.trls <- sample(rep(c('none','catch'),12))                                   # randomized
  # combine blocks and trials
  aloc.fseq <- as.vector(rbind(aloc.cond.blks,aloc.base.blks,aloc.resp.trls))
}
# read the stimuli list
aloc.stimuli <- read.csv(file=file.path(wdir,'Stimuli_Auditory_Localizer.csv'))
aloc.words <- as.vector(sample(aloc.stimuli[aloc.stimuli$type=='word','stimulus']))
aloc.pseudowords <- as.vector(sample(aloc.stimuli[aloc.stimuli$type=='pseudoword','stimulus']))
aloc.vocoded <- as.vector(sample(aloc.stimuli[aloc.stimuli$type=='vocoded','stimulus']))
# create LabView script (.desc) row-wise, time unit (trigger) is 67 ms
ntrls <- 12  # 24 stimuli per block
aloc.dur.stimulus <- 12  # 804ms
aloc.dur.blank <- 3      # 201ms
aloc.dur.rest <- 180     # 12060ms
aloc.dur.catch <- 5      # 335ms puls a jitter ranged from 13 to 23 triggers (1206 to 1876ms in total)
aloc.desc <- data.frame(CONDITION='Détecter : le son "bip"',PHRASE='Noir',BITMAP='Noir',WAV='Rien',
                        DUREE=90,REPONSE1=0,REPONSE2=0,REPONSE3=0)
for (aloc.tag in aloc.fseq){
  switch(aloc.tag,
         Words={
           aloc.desc.wav <- as.vector(rbind(aloc.words[1:ntrls],rep('Noir',ntrls)))
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
           aloc.desc.wav <- as.vector(rbind(aloc.pseudowords[1:ntrls],rep('Noir',ntrls)))
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
           aloc.desc.wav <- as.vector(rbind(aloc.vocoded[1:ntrls],rep('Noir',ntrls)))
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
           aloc.desc.tmp <- rbind(c(aloc.tag,'Noir','Noir','BEEP',aloc.dur.catch,0,0,0),
                                  c(aloc.tag,'Noir','Noir','Rien',aloc.dur.catch.jitter,0,0,0))
           aloc.desc.tmp <- as.data.frame(aloc.desc.tmp)
           names(aloc.desc.tmp) <- names(aloc.desc)
         },
         Rest={
           aloc.desc.tmp <- data.frame(CONDITION=aloc.tag,
                                       PHRASE   ='Noir',
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
# output LabView .desc
write.table(aloc.desc,file=file.path(wdir,'Stimulation_task-AuditoryLocalizer_TEST.desc'),sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
write.table(aloc.desc,file=file.path(wdir,'Stimulation_task-AuditoryLocalizerFr_TEST.desc'),sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1


## the main task - ER-design with catch trials
trigger.duration <- 0.082  # trigger duration in LabView in seconds, i.e. 82 ms
# read fMRI experiment sequence
main.fseq.op <- read.table(file=file.path(wdir,'Optiaml_Sequence_optseq2_MainTask.par'),sep="")
names(main.fseq.op) <- c('time','event_id','duration','count','event_label')
hist(main.fseq.op$duration[main.fseq.op$event_id==0])
# create full event sequence
main.fseq.op$catch <- as.vector(rbind(rep('none',dim(main.fseq.op)[1]/2),sample(rep(c('catchA','catchV',rep('none',10)),dim(main.fseq.op)[1]/24))))
main.fseq.et <- data.frame(event=as.vector(rbind(as.vector(main.fseq.op$event_label),main.fseq.op$catch)),
                             duration=as.vector(rbind(main.fseq.op$duration,main.fseq.op$count)))
main.fseq.et <- main.fseq.et[main.fseq.et$event!='none',]
# read the stimuli list
main.trials <- read.csv(file=file.path(wdir,'Selected_Words_MainTask_byTrials.csv'))
main.sounds <- read.csv(file=file.path(wdir,'Stimuli_MainTaskAuditory.csv'))
main.trials.pool <- main.trials[,c('conditions','A1','A2','Ts')]
main.trials.pool$trlid <- 1:dim(main.trials.pool)[1]
# create LabView script (.desc), time unit (trigger) is 67 ms 
main.dur.word <- 10 # 820ms
main.dur.a1a2 <- 5  # 410ms 
main.dur.catch <- 30 # around 1.2 seconds to 1.8 seconds (82ms) 10% 
main.desc <- data.frame(CONDITION='FirstBreak',PHRASE='+',BITMAP='Noir',WAV='Rien',
                        DUREE=90,REPONSE1=0,REPONSE2=0,REPONSE3=0)
iti <- 1
for (main.tag in main.fseq.et$event){
  main.dur.iti <- main.fseq.et$duration[iti]
  if (main.tag=='NULL'){
    triggers.iti <- ceiling(main.dur.iti/trigger.duration)
    main.desc.tmp <- data.frame(CONDITION='ITI',
                                PHRASE   ='+',
                                BITMAP   ='Noir',
                                WAV      ='Rien',
                                DUREE    =triggers.iti,
                                REPONSE1 =0,
                                REPONSE2 =0,
                                REPONSE3 =0)   
  } else if (main.tag=='catchA'){
    main.desc.tmp <- rbind(c(main.tag,'+','Noir','BEEP',main.dur.catch/2,0,0,0),
                           c(main.tag,'+','Noir','Rien',main.dur.catch/2,0,0,0))
    main.desc.tmp <- as.data.frame(main.desc.tmp)
    names(main.desc.tmp) <- names(main.desc)
  } else if (main.tag=='catchV'){
    main.desc.tmp <- rbind(c(main.tag,'######','Noir','Rien',main.dur.catch/2,0,0,0),
                           c(main.tag,'+','Noir','Rien',main.dur.catch/2,0,0,0))
    main.desc.tmp <- as.data.frame(main.desc.tmp)
    names(main.desc.tmp) <- names(main.desc)   
  } else {
    main.trials.tmp <- main.trials.pool[main.trials.pool$conditions==main.tag,]
    main.trials.tmp <- main.trials.tmp[sample(1:dim(main.trials.tmp)[1])[1],]
    if (main.tag %in% c('SISMa','DISMa')){
      wav.a1 <- iconv(main.trials.tmp$A1,to='ASCII//TRANSLIT')  # replace French accent
      wav.a2 <- iconv(main.trials.tmp$A2,to='ASCII//TRANSLIT')
      wav.ts <- iconv(main.trials.tmp$Ts,to='ASCII//TRANSLIT')
      main.desc.wav <- as.vector(rbind(c(wav.a1,wav.a2,wav.ts),rep('Rien',3)))
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,6),                           # CONDITION
                                  PHRASE   =rep('Noir',6),                             # PHRASE
                                  BITMAP   =rep('Noir',6),                             # BITMAP
                                  WAV      =main.desc.wav,                             # WAV
                                  DUREE    =rep(c(main.dur.word,main.dur.a1a2),3),  # DUREE
                                  REPONSE1 =rep(0,6),                                  # REPONSE1
                                  REPONSE2 =rep(0,6),
                                  REPONSE3 =rep(0,6))                                  # REPONSE2 
    } else if (main.tag %in% c('SIDMa','DIDMa')){
      wav.a1 <- iconv(main.trials.tmp$A1,to='ASCII//TRANSLIT')  # replace French accent
      wav.a2 <- iconv(main.trials.tmp$A2,to='ASCII//TRANSLIT')
      main.desc.wav <- as.vector(rbind(c(wav.a1,wav.a2,'Rien'),rep('Rien',3)))
      main.desc.phr <- c(rep('Noir',4),as.character(main.trials.tmp$Ts),'Noir')
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,6),                           # CONDITION
                                  PHRASE   =main.desc.phr,                             # PHRASE
                                  BITMAP   =rep('Noir',6),                             # BITMAP
                                  WAV      =main.desc.wav,                             # WAV
                                  DUREE    =rep(c(main.dur.word,main.dur.a1a2),3),  # DUREE
                                  REPONSE1 =rep(0,6),                                  # REPONSE1
                                  REPONSE2 =rep(0,6),
                                  REPONSE3 =rep(0,6))# REPONSE2      
    } else if (main.tag %in% c('SIDMv','DIDMv')){
      wav.ts <- iconv(main.trials.tmp$Ts,to='ASCII//TRANSLIT')  # replace French accent
      main.desc.wav <- as.vector(rbind(c('Rien','Rien',wav.ts),rep('Rien',3)))
      main.desc.phr <- as.vector(rbind(c(as.character(main.trials.tmp$A1),as.character(main.trials.tmp$A2),'Noir'),rep('Noir',3)))
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,6),                           # CONDITION
                                  PHRASE   =main.desc.phr,                             # PHRASE
                                  BITMAP   =rep('Noir',6),                             # BITMAP
                                  WAV      =main.desc.wav,                             # WAV
                                  DUREE    =rep(c(main.dur.word,main.dur.a1a2),3),  # DUREE
                                  REPONSE1 =rep(0,6),                                  # REPONSE1
                                  REPONSE2 =rep(0,6),
                                  REPONSE3 =rep(0,6))# REPONSE2           
    } else {
      main.desc.phr <- as.vector(rbind(c(as.character(main.trials.tmp$A1),as.character(main.trials.tmp$A2),as.character(main.trials.tmp$Ts)),rep('Noir',3)))
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,6),                           # CONDITION
                                  PHRASE   =main.desc.phr,                             # PHRASE
                                  BITMAP   =rep('Noir',6),                             # BITMAP
                                  WAV      =rep('Rien',6),                             # WAV
                                  DUREE    =rep(c(main.dur.word,main.dur.a1a2),3),  # DUREE
                                  REPONSE1 =rep(0,6),                                  # REPONSE1
                                  REPONSE2 =rep(0,6),
                                  REPONSE3 =rep(0,6))# REPONSE2                
    }
    main.trials.pool <- main.trials.pool[main.trials.pool$trlid!=main.trials.tmp$trlid,]     
  }
  main.desc <- rbind(main.desc,main.desc.tmp)
  iti <- iti+1
}
# output LabView .desc with ISO-8859-1 (latin1) encoding
write.table(main.desc,file=file.path(wdir,'Stimulation_task-MainTaskFr.desc'),sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')