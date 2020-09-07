## SCRIPT to convert fMRI experiment sequence into LabView sequence (.desc) for the two localizers
## and the main task in the CP00 study.
# By WS, 2019-12-14

# clean up
rm(list=ls())

# setup environments
wdir <- '.'
runs.num <- 4              # 4 runs
trigger.duration <- 0.082  # trigger duration in LabView in seconds, i.e. 82 ms  
triggers.slice <- 16       # 48 slices per TR, multiband factor = 3
TR <- trigger.duration*triggers.slice

## the main task - ER-design with catch trials
# read fMRI experiment sequence
main.fseq.op <- read.table(file=file.path(wdir,'optseq2_MainTask_Pilot1.par'),sep="")
names(main.fseq.op) <- c('time','event_id','duration','count','event_label')
hist(main.fseq.op$duration[main.fseq.op$event_id==0])
# create full event sequence
catch.percent <- 1/6
trials.num <- dim(main.fseq.op)[1]/2
catch.run <- rep(c('catchA','catchV',rep('none',2/catch.percent-2)),trials.num*catch.percent/(2*runs.num))
main.fseq.op$catch <- as.vector(rbind(rep('none',trials.num),
                                      c(sample(catch.run),sample(catch.run),sample(catch.run),sample(catch.run))))
main.fseq.et <- data.frame(event=as.vector(rbind(as.vector(main.fseq.op$event_label),main.fseq.op$catch)),
                             duration=as.vector(rbind(main.fseq.op$duration,main.fseq.op$count)))
main.fseq.et <- main.fseq.et[main.fseq.et$event!='none',]
# read the stimuli list
main.trials <- read.csv(file=file.path(wdir,'Selected_Words_MainTask_byTrials.csv'))
main.sounds <- read.csv(file=file.path(wdir,'Stimuli_MainTaskAuditory.csv'))
main.trials.pool <- main.trials[,c('conditions','A1','A2','Ts')]
main.trials.pool$trlid <- 1:dim(main.trials.pool)[1]
# create LabView script (.desc), time unit (trigger) is 82 ms 
main.dur.word <- 10  # 820ms
main.dur.a1a2 <- 5   # 410ms 
main.dur.catch <- 4  # 328ms puls a jitter ranged from 11 to 19 triggers (1230 to 1886ms in total)
main.desc <- data.frame(CONDITION='Instruction',PHRASE='Détecter : ###### et le son "bip"',BITMAP='Noir',WAV='Rien',
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
    main.dur.catch.jitter <- sample(11:19)[1]  # to be checked: jitter distribution?
    main.desc.tmp <- rbind(c(main.tag,'+','Noir','BEEP',main.dur.catch,2,0,0),  # press 2 to detect BEEP sound
                           c(main.tag,'+','Noir','Rien',main.dur.catch.jitter,0,0,0))
    main.desc.tmp <- as.data.frame(main.desc.tmp)
    names(main.desc.tmp) <- names(main.desc)
  } else if (main.tag=='catchV'){
    main.dur.catch.jitter <- sample(11:19)[1]  # to be checked: jitter distribution?   
    main.desc.tmp <- rbind(c(main.tag,'######','Noir','Rien',main.dur.catch,2,0,0),  # press 2 to detect ######
                           c(main.tag,'+','Noir','Rien',main.dur.catch.jitter,0,0,0))
    main.desc.tmp <- as.data.frame(main.desc.tmp)
    names(main.desc.tmp) <- names(main.desc)   
  } else {
    main.trials.tmp <- main.trials.pool[main.trials.pool$conditions==main.tag,]
    main.trials.tmp <- main.trials.tmp[sample(1:dim(main.trials.tmp)[1])[1],]
    main.dur.a2ts <- sample(5:8)[1]
    if (main.tag %in% c('SISMa','DISMa')){
      wav.a1 <- iconv(main.trials.tmp$A1,to='ASCII//TRANSLIT')  # replace French accent
      wav.a2 <- iconv(main.trials.tmp$A2,to='ASCII//TRANSLIT')
      wav.ts <- iconv(main.trials.tmp$Ts,to='ASCII//TRANSLIT')
      main.desc.wav <- as.vector(rbind(c(wav.a1,wav.a2,wav.ts),rep('Rien',3)))
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,6),                        # CONDITION
                                  PHRASE   =rep('Noir',6),                          # PHRASE
                                  BITMAP   =rep('Noir',6),                          # BITMAP
                                  WAV      =main.desc.wav,                          # WAV
                                  DUREE    =c(main.dur.word,main.dur.a1a2,main.dur.word,main.dur.a2ts,main.dur.word,main.dur.a1a2),  # DUREE
                                  REPONSE1 =rep(0,6),                               # REPONSE1
                                  REPONSE2 =rep(0,6),                               # REPONSE2 
                                  REPONSE3 =rep(0,6))                               # REPONSE3    
    } else if (main.tag %in% c('SIDMa','DIDMa')){
      wav.a1 <- iconv(main.trials.tmp$A1,to='ASCII//TRANSLIT')  # replace French accent
      wav.a2 <- iconv(main.trials.tmp$A2,to='ASCII//TRANSLIT')
      main.desc.wav <- as.vector(rbind(c(wav.a1,wav.a2,'Rien'),rep('Rien',3)))
      main.desc.phr <- c(rep('Noir',4),as.character(main.trials.tmp$Ts),'Noir')
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,6),                           # CONDITION
                                  PHRASE   =main.desc.phr,                             # PHRASE
                                  BITMAP   =rep('Noir',6),                             # BITMAP
                                  WAV      =main.desc.wav,                             # WAV
                                  DUREE    =c(main.dur.word,main.dur.a1a2,main.dur.word,main.dur.a2ts,main.dur.word,main.dur.a1a2),  # DUREE
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
                                  DUREE    =c(main.dur.word,main.dur.a1a2,main.dur.word,main.dur.a2ts,main.dur.word,main.dur.a1a2),  # DUREE
                                  REPONSE1 =rep(0,6),                                  # REPONSE1
                                  REPONSE2 =rep(0,6),
                                  REPONSE3 =rep(0,6))# REPONSE2           
    } else {
      main.desc.phr <- as.vector(rbind(c(as.character(main.trials.tmp$A1),as.character(main.trials.tmp$A2),as.character(main.trials.tmp$Ts)),rep('Noir',3)))
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,6),                           # CONDITION
                                  PHRASE   =main.desc.phr,                             # PHRASE
                                  BITMAP   =rep('Noir',6),                             # BITMAP
                                  WAV      =rep('Rien',6),                             # WAV
                                  DUREE    =c(main.dur.word,main.dur.a1a2,main.dur.word,main.dur.a2ts,main.dur.word,main.dur.a1a2),  # DUREE
                                  REPONSE1 =rep(0,6),                                  # REPONSE1
                                  REPONSE2 =rep(0,6),
                                  REPONSE3 =rep(0,6))# REPONSE2                
    }
    main.trials.pool <- main.trials.pool[main.trials.pool$trlid!=main.trials.tmp$trlid,]     
  }
  main.desc <- rbind(main.desc,main.desc.tmp)
  iti <- iti+1
}

# split the main task into 4 runs, and make the duration as a multiple of TRs
main.desc.run.lines <- (dim(main.desc)[1]-1)/runs.num
for (irun in 1:runs.num){
  main.desc.irun.lines <- (main.desc.run.lines*(irun-1)+2):(main.desc.run.lines*irun+1)
  main.desc.irun <- rbind(main.desc[1,],main.desc[main.desc.irun.lines,])
  ntriggers <- sum(as.numeric(main.desc.irun$DUREE))
  nTR <- ceiling(ntriggers/triggers.slice)
  triggers.add <- nTR*triggers.slice - ntriggers
  main.desc.irun$DUREE[main.desc.run.lines+1] <- as.numeric(main.desc.irun$DUREE[main.desc.run.lines+1]) + triggers.add 
  # output the LabView .desc
  write.table(main.desc.irun,file=file.path(wdir,sprintf('Stimulation_task-MainTask_Pilot1_Run%d.desc',irun)),
              sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
  write.table(main.desc.irun,file=file.path(wdir,sprintf('Stimulation_task-MainTaskFr_Pilot1_Run%d.desc',irun)),
              sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1 
  sink(file=file.path(wdir,'Stimulation_task-MainTask_Pilot1.stat'),append=TRUE)
  print(paste('For RUN',irun,':'))
  print(paste('The number of TRs is',nTR))
  print(paste('The total scanning time should be',nTR*TR,'seconds or',nTR*TR/60,'minutes'))
  sink()
}
#ntriggers <- sum(as.numeric(main.desc$DUREE))
#nTR <- ceiling(ntriggers/triggers.slice)
#triggers.add <- nTR*triggers.slice - ntriggers
#main.desc$DUREE[-1] <- as.numeric(main.desc$DUREE[-1]) + triggers.add

## output LabView .desc
#sink(file=file.path(wdir,'Stimulation_task-MainTask_Pilot1.stat'))
#sprintf('The number of TRs is %d.',nTR)
#sprintf('The total scanning time should be %f seconds, or %f min.',nTR*TR,nTR*TR/60)
#sink()
#write.table(main.desc,file=file.path(wdir,'Stimulation_task-MainTask_Pilot1.desc'),sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
#write.table(main.desc,file=file.path(wdir,'Stimulation_task-MainTaskFr_Pilot1.desc'),sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1