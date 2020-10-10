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
wdir <- '/media/wang/BON/Projects/CP00/experiment_design/labview_scripts/'
pdir <- file.path(wdir,'Pilot3')
setwd(pdir)
odir <- file.path(pdir,'AVA-2word')
# scan parameters
runs.num <- 2              # 2 runs
trigger.duration <- 0.082  # trigger duration in LabView in seconds, i.e. 82 ms  
triggers.slice <- 14       # 42 slices per TR, multiband factor = 3
TR <- trigger.duration*triggers.slice
# task parameters
catch.percent <- 1/12
main.dur.word <- 10  # 820ms
main.dur.a1a2 <- 3   # 246ms
# function - convert ITI from Pilot1 to Pilot3
iti_p1p2 <- function (x){ ceiling(20*((5.6*2-x)/5.6))+1 }
## ---------------------------

## create fMRI experiment sequence
# read optseq2 sequence
main.fseq.op <- read.table(file=file.path(wdir,'optseq2_MainTask_Pilot1.par'),sep="")
main.fseq.op <- main.fseq.op[1:(dim(main.fseq.op)[1]/2),]  # reduce 50% trials based on Pilot1
names(main.fseq.op) <- c('time','event_id','duration','count','event_label')
hist(main.fseq.op$duration[main.fseq.op$event_id==0])
# create full event sequence
trials.num <- dim(main.fseq.op)[1]/2
catch.run <- c(rep(c('catchAA','catchVV','catchAV','catchVA'),trials.num*catch.percent/(4*runs.num)),rep('none',trials.num*(1-catch.percent)/runs.num))
main.fseq.op$catch <- as.vector(rbind(rep('none',trials.num),c(sample(catch.run),sample(catch.run))))
main.fseq.et <- data.frame(event=as.vector(rbind(as.vector(main.fseq.op$event_label),main.fseq.op$catch)),
                           duration=as.vector(rbind(main.fseq.op$duration,main.fseq.op$count)))
main.fseq.et <- main.fseq.et[main.fseq.et$event!='none',]
## ---------------------------

## generate LabView script
# read the stimuli list
main.trials <- read.csv(file=file.path(pdir,'Pilot3_words_2wordTrials_byTrials.csv'))
main.trials.pool <- main.trials[,c('conditions','A1','A2')]
main.trials.pool$trlid <- 1:dim(main.trials.pool)[1]
main.catch.pool <- main.trials.pool
main.pseudowords <- read.csv(file=file.path(wdir,'Stimuli_Auditory_Localizer.csv'))
main.pseudowords <- main.pseudowords[main.pseudowords$type=='pseudoword',]
# create LabView script (.desc), time unit (trigger) is 82 ms 
main.desc <- data.frame(CONDITION='BlankStart',PHRASE='+',BITMAP='Noir',WAV='Rien',
                        DUREE=56,REPONSE1=0,REPONSE2=0,REPONSE3=0)
iti <- 1
for (main.tag in main.fseq.et$event){
  main.dur.iti <- main.fseq.et$duration[iti]
  if (main.tag=='NULL'){
    triggers.iti <- ceiling(main.dur.iti/trigger.duration)+iti_p1p2(main.dur.iti)
    main.desc.tmp <- data.frame(CONDITION='ITI',
                                PHRASE   ='+',
                                BITMAP   ='Noir',
                                WAV      ='Rien',
                                DUREE    =triggers.iti,
                                REPONSE1 =0,
                                REPONSE2 =0,
                                REPONSE3 =0)   
  } else if (main.tag=='catchAA'){
    main.trials.tmp <- main.catch.pool[main.catch.pool$conditions %in% c('SISMa','DISMa'),]
    main.trials.tmp <- main.trials.tmp[sample(1:dim(main.trials.tmp)[1])[1],]
    main.catchAA.tmp <- c(iconv(main.trials.tmp$A1,to='ASCII//TRANSLIT'),  # replace French accent
                          iconv(main.trials.tmp$A2,to='ASCII//TRANSLIT'))
    main.catchAA.pw <- main.pseudowords$stimulus[sample(1:96)][1]
    pw <- sample(1:2)[1]
    main.catchAA.tmp[pw] <- as.character(main.catchAA.pw)
    main.desc.wav <- as.vector(rbind(main.catchAA.tmp,rep('Rien',2)))
    main.dur.catch <- sample(12:16)[1]
    main.desc.tmp <- data.frame(CONDITION=rep(main.tag,4),                  # CONDITION
                                PHRASE   =rep('Noir',4),                    # PHRASE
                                BITMAP   =rep('Noir',4),                    # BITMAP
                                WAV      =main.desc.wav,                    # WAV
                                DUREE    =c(main.dur.word,main.dur.a1a2,
                                            main.dur.word,main.dur.catch),  # DUREE
                                REPONSE1 =rep(0,4),                         
                                REPONSE2 =rep(0,4),                         
                                REPONSE3 =rep(0,4))                         
    main.desc.tmp$REPONSE1[c(1,3)[pw]] <- 2  # correct repsonse
  } else if (main.tag=='catchVV'){
    main.trials.tmp <- main.catch.pool[main.catch.pool$conditions %in% c('SISMv','DISMv'),]
    main.trials.tmp <- main.trials.tmp[sample(1:dim(main.trials.tmp)[1])[1],]
    main.catchVV.tmp <- c(as.character(main.trials.tmp$A1),
                          as.character(main.trials.tmp$A2))
    main.catchVV.pw <- main.pseudowords$stimulus[sample(1:96)][1]
    pw <- sample(1:2)[1]
    main.catchVV.tmp[pw] <- as.character(main.catchVV.pw)
    main.desc.phr <- as.vector(rbind(main.catchVV.tmp,rep('Noir',2)))
    main.dur.catch <- sample(12:16)[1]   
    main.desc.tmp <- data.frame(CONDITION=rep(main.tag,4),                  # CONDITION
                                PHRASE   =main.desc.phr,                    # PHRASE
                                BITMAP   =rep('Noir',4),                    # BITMAP
                                WAV      =rep('Rien',4),                    # WAV
                                DUREE    =c(main.dur.word,main.dur.a1a2,
                                            main.dur.word,main.dur.catch),  # DUREE
                                REPONSE1 =rep(0,4),                         
                                REPONSE2 =rep(0,4),
                                REPONSE3 =rep(0,4))
    main.desc.tmp$REPONSE1[c(1,3)[pw]] <- 2  # correct repsonse   
  } else if (main.tag=='catchAV'){
    main.trials.tmp <- main.catch.pool[main.catch.pool$conditions %in% c('SIDMa','DIDMa'),]
    main.trials.tmp <- main.trials.tmp[sample(1:dim(main.trials.tmp)[1])[1],]
    main.catchAV.tmp <- c(iconv(main.trials.tmp$A1,to='ASCII//TRANSLIT'),  # replace French accent
                          as.character(main.trials.tmp$A2))
    main.catchAV.pw <- main.pseudowords$stimulus[sample(1:96)][1]
    pw <- sample(1:2)[1]
    main.catchAV.tmp[pw] <- as.character(main.catchAV.pw)
    main.desc.wav <- c(main.catchAV.tmp[1],rep('Rien',3))
    main.desc.phr <- c(rep('Noir',2),main.catchAV.tmp[2],'Noir')
    main.dur.catch <- sample(12:16)[1]   
    main.desc.tmp <- data.frame(CONDITION=rep(main.tag,4),                  # CONDITION
                                PHRASE   =main.desc.phr,                    # PHRASE
                                BITMAP   =rep('Noir',4),                    # BITMAP
                                WAV      =main.desc.wav,                    # WAV
                                DUREE    =c(main.dur.word,main.dur.a1a2,
                                            main.dur.word,main.dur.catch),  # DUREE
                                REPONSE1 =rep(0,4),                        
                                REPONSE2 =rep(0,4),
                                REPONSE3 =rep(0,4))
    main.desc.tmp$REPONSE1[c(1,3)[pw]] <- 2  # correct repsonse   
  } else if (main.tag=='catchVA'){
    main.trials.tmp <- main.catch.pool[main.catch.pool$conditions %in% c('SIDMv','DIDMv'),]
    main.trials.tmp <- main.trials.tmp[sample(1:dim(main.trials.tmp)[1])[1],]
    main.catchVA.tmp <- c(as.character(main.trials.tmp$A1),
                          iconv(main.trials.tmp$A2,to='ASCII//TRANSLIT'))  # replace French accent
    main.catchVA.pw <- main.pseudowords$stimulus[sample(1:96)][1]
    pw <- sample(1:2)[1]    
    main.catchVA.tmp[pw] <- as.character(main.catchVA.pw)   
    main.desc.phr <- c(main.catchVA.tmp[1],rep('Noir',3))
    main.desc.wav <- c(rep('Rien',2),main.catchVA.tmp[2],'Rien')
    main.dur.catch <- sample(12:16)[1]   
    main.desc.tmp <- data.frame(CONDITION=rep(main.tag,4),                  # CONDITION
                                PHRASE   =main.desc.phr,                    # PHRASE
                                BITMAP   =rep('Noir',4),                    # BITMAP
                                WAV      =main.desc.wav,                    # WAV
                                DUREE    =c(main.dur.word,main.dur.a1a2,
                                            main.dur.word,main.dur.catch),  # DUREE
                                REPONSE1 =rep(0,4),                        
                                REPONSE2 =rep(0,4),
                                REPONSE3 =rep(0,4))
    main.desc.tmp$REPONSE1[c(1,3)[pw]] <- 2  # correct repsonse   
  } else {
    main.trials.tmp <- main.trials.pool[main.trials.pool$conditions==main.tag,]
    main.trials.tmp <- main.trials.tmp[sample(1:dim(main.trials.tmp)[1])[1],]
    if (main.tag %in% c('SISMa','DISMa')){
      wav.a1 <- iconv(main.trials.tmp$A1,to='ASCII//TRANSLIT')  # replace French accent
      wav.a2 <- iconv(main.trials.tmp$A2,to='ASCII//TRANSLIT')
      main.desc.wav <- c(wav.a1,'Rien',wav.a2,'Rien')
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,4),                 # CONDITION
                                  PHRASE   =rep('Noir',4),                   # PHRASE
                                  BITMAP   =rep('Noir',4),                   # BITMAP
                                  WAV      =main.desc.wav,                   # WAV
                                  DUREE    =c(main.dur.word,main.dur.a1a2,
                                              main.dur.word,main.dur.a1a2),  # DUREE
                                  REPONSE1 =rep(0,4),                               
                                  REPONSE2 =rep(0,4),                               
                                  REPONSE3 =rep(0,4))                               
    } else if (main.tag %in% c('SIDMa','DIDMa')){
      wav.a1 <- iconv(main.trials.tmp$A1,to='ASCII//TRANSLIT')  # replace French accent
      main.desc.wav <- c(wav.a1,rep('Rien',3))
      main.desc.phr <- c(rep('Noir',2),as.character(main.trials.tmp$A2),'Noir')
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,4),                 # CONDITION
                                  PHRASE   =main.desc.phr,                   # PHRASE
                                  BITMAP   =rep('Noir',4),                   # BITMAP
                                  WAV      =main.desc.wav,                   # WAV
                                  DUREE    =c(main.dur.word,main.dur.a1a2,
                                              main.dur.word,main.dur.a1a2),  # DUREE
                                  REPONSE1 =rep(0,4),                         
                                  REPONSE2 =rep(0,4),
                                  REPONSE3 =rep(0,4))
    } else if (main.tag %in% c('SIDMv','DIDMv')){
      wav.a2 <- iconv(main.trials.tmp$A2,to='ASCII//TRANSLIT')  # replace French accent
      main.desc.wav <- c(rep('Rien',2),wav.a2,'Rien')
      main.desc.phr <- c(as.character(main.trials.tmp$A1),rep('Noir',3))
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,4),                 # CONDITION
                                  PHRASE   =main.desc.phr,                   # PHRASE
                                  BITMAP   =rep('Noir',4),                   # BITMAP
                                  WAV      =main.desc.wav,                   # WAV
                                  DUREE    =c(main.dur.word,main.dur.a1a2,
                                              main.dur.word,main.dur.a1a2),  # DUREE
                                  REPONSE1 =rep(0,4),                       
                                  REPONSE2 =rep(0,4),
                                  REPONSE3 =rep(0,4))
    } else {  # SISMv and DISMv
      main.desc.phr <- c(as.character(main.trials.tmp$A1),'Noir',as.character(main.trials.tmp$A2),'Noir')
      main.desc.tmp <- data.frame(CONDITION=rep(main.tag,4),                 # CONDITION
                                  PHRASE   =main.desc.phr,                   # PHRASE
                                  BITMAP   =rep('Noir',4),                   # BITMAP
                                  WAV      =rep('Rien',4),                   # WAV
                                  DUREE    =c(main.dur.word,main.dur.a1a2,
                                              main.dur.word,main.dur.a1a2),  # DUREE
                                  REPONSE1 =rep(0,4),                       
                                  REPONSE2 =rep(0,4),
                                  REPONSE3 =rep(0,4))  
    }
    main.trials.pool <- main.trials.pool[main.trials.pool$trlid!=main.trials.tmp$trlid,]     
  }
  main.desc <- rbind(main.desc,main.desc.tmp)
  iti <- iti+1
}
# split the main task into 2 runs, and make the duration as a multiple of TRs
main.desc.run.lines <- (dim(main.desc)[1]-1)/runs.num
for (irun in 1:runs.num){
  main.desc.irun.lines <- (main.desc.run.lines*(irun-1)+2):(main.desc.run.lines*irun+1)
  main.desc.irun <- rbind(main.desc[1,],main.desc[main.desc.irun.lines,])
  # make sure that 1) the total duration is a multiple of TRs and 2) the last ITI is ~11 seconds
  main.desc.irun$DUREE[main.desc.run.lines+1] <- 140
  ntriggers <- sum(as.numeric(main.desc.irun$DUREE))
  nTR <- ceiling(ntriggers/triggers.slice)
  triggers.add <- nTR*triggers.slice - ntriggers
  main.desc.irun$DUREE[main.desc.run.lines+1] <- as.numeric(main.desc.irun$DUREE[main.desc.run.lines+1]) + triggers.add 
  # output the LabView .desc
  write.table(main.desc.irun,file=file.path(odir,sprintf('Stimulation_task-AudioVisAsso2word_Pilot3_Run%d.desc',irun)),
              sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
  write.table(main.desc.irun,file=file.path(odir,sprintf('Stimulation_task-AudioVisAsso2wordFr_Pilot3_Run%d.desc',irun)),
              sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1 
  sink(file=file.path(odir,sprintf('Stimulation_task-AudioVisAsso2word_Pilot3_Run%d.stat',irun)),append=FALSE)
    print(paste('For RUN',irun,':'))
    print(paste('The number of TRs is',nTR))
    print(paste('The total scanning time should be',nTR*TR,'seconds or',nTR*TR/60,'minutes'))
  sink()
}
## ---------------------------

# save R data
save(list=ls(),file=file.path(odir,'Stimulation_task-AudioVisAsso2word_Pilot3.Rdata'))
