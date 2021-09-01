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
pdir <- file.path(wdir, 'Pilot3')
setwd(pdir)
odir <- file.path(pdir, 'AVA-1word')
# scan parameters
trigger.duration <- 0.082                # trigger duration in seconds for LabView, i.e. 82 ms  
triggers.slice <- 14                     # number of slices per trigger, which equals to N(slices) / N(multiband factors)
TR <- trigger.duration * triggers.slice  # 1148ms
# task parameters
subjects <- c('sub-01')  # generate a task sequence per subject. The data collection used the task sequence of sub-01 for all subjects.
ntrls <- 48              # 48 stimuli per run
nruns <- 5               # 5 runs
dur.stimulus <- 10       # 820ms
iti.range <- 37:51       # from 3034ms to 4182ms
va.seqs <- c(3,4,5,1,2)  # the sequence of runs for auditory stimuli
nTR <- 200               # make all of the 5 runs having 200 TRs
## ---------------------------

## generate LabView script
for (subj in subjects){
  sdir <- file.path(odir, subj)
  # read the individual stimuli list
  words <- read.csv(file = file.path(sdir, sprintf('Pilot3_%s_words_1wordTrials_byRuns.csv', subj)), stringsAsFactors = FALSE)
  pwords <- read.csv(file = file.path(sdir, sprintf('Pilot3_%s_pseudowords_1wordTrials_byRuns.csv', subj)), stringsAsFactors = FALSE) 
  # create fMRI experiment sequence
  cond.seqs <- list(NA)
  for (irun in 1:nruns){
    cond.rep <- 0
    while (cond.rep != ntrls){
      # randomized but no repeated conditions
      cond.trls <- as.vector(replicate(ntrls/4, sample(c('WV','WA','PV','PA'))))  
      cond.rep <- length(rle(cond.trls)$length)
    }
    cond.seqs[[irun]] <- cond.trls
  }
  # create LabView script (.desc) row-wise for each run, time unit (trigger) is 82 ms
  for (irun in 1:nruns){
    irunIdxV <- sprintf('run%d',irun)                  # visual words unit label for this run
    irunIdxA <- sprintf('run%d',va.seqs[irun])         # auditory words unit label
    irun.fseq <- cond.seqs[[irun]]                     # condition sequence for this run
    irun.wordsV <- words[words$unitIdx==irunIdxV,]     # visual words for this run
    irun.wordsA <- words[words$unitIdx==irunIdxA,]     # auditory words for this run 
    irun.pwordsV <- pwords[pwords$unitIdx==irunIdxV,]  # visual pseudowords for this run 
    irun.pwordsA <- pwords[pwords$unitIdx==irunIdxA,]  # auditory pseudowords for this run  
    # write script line by line
    irun.desc <- data.frame(CONDITION='BlankStart',PHRASE='+',BITMAP='Noir',WAV='Rien',
                            DUREE=56,REPONSE1=0,REPONSE2=0,REPONSE3=0)
    for (irun.tag in irun.fseq){
      irun.iti <- sample(iti.range)[1]
      switch(irun.tag,
             WV={
               irun.WV <- sample(1:dim(irun.wordsV)[1])[1]
               irun.desc.phr <- c(irun.wordsV[irun.WV,'ortho'],'+')
               irun.desc.tmp <- data.frame(CONDITION=c(irun.tag,'ITI'),                           # CONDITION
                                           PHRASE   =irun.desc.phr,                                # PHRASE
                                           BITMAP   =rep('Noir',2),                             # BITMAP
                                           WAV      =rep('Rien',2),                             # WAV
                                           DUREE    =c(dur.stimulus,irun.iti),  # DUREE
                                           REPONSE1 =c(2,0),                                  # REPONSE1
                                           REPONSE2 =c(0,0),                                  # REPONSE2
                                           REPONSE3 =c(0,0))                                  # REPONSE2 
               irun.wordsV <- irun.wordsV[-irun.WV,]
             },
             WA={
               irun.WA <- sample(1:dim(irun.wordsA)[1])[1]            
               irun.desc.wav <- c(iconv(irun.wordsA[irun.WA,'ortho'],to='ASCII//TRANSLIT'),'Rien')
               irun.desc.tmp <- data.frame(CONDITION=c(irun.tag,'ITI'),                           # CONDITION
                                           PHRASE   =c('Noir','+'),                                # PHRASE
                                           BITMAP   =rep('Noir',2),                             # BITMAP
                                           WAV      =irun.desc.wav,                             # WAV
                                           DUREE    =c(dur.stimulus,irun.iti),  # DUREE
                                           REPONSE1 =c(2,0),                                  # REPONSE1
                                           REPONSE2 =c(0,0),                                  # REPONSE2
                                           REPONSE3 =c(0,0))                                  # REPONSE2 
               irun.wordsA <- irun.wordsA[-irun.WA,]            
             },
             PV={
               irun.PV <- sample(1:dim(irun.pwordsV)[1])[1]
               irun.desc.phr <- c(irun.pwordsV[irun.PV,'v2written'],'+')
               irun.desc.tmp <- data.frame(CONDITION=c(irun.tag,'ITI'),                           # CONDITION
                                           PHRASE   =irun.desc.phr,                                # PHRASE
                                           BITMAP   =rep('Noir',2),                             # BITMAP
                                           WAV      =rep('Rien',2),                             # WAV
                                           DUREE    =c(dur.stimulus,irun.iti),  # DUREE
                                           REPONSE1 =c(3,0),                                  # REPONSE1
                                           REPONSE2 =c(0,0),                                  # REPONSE2
                                           REPONSE3 =c(0,0))                                  # REPONSE2 
               irun.pwordsV <- irun.pwordsV[-irun.PV,]
             },        
             PA={
               irun.PA <- sample(1:dim(irun.pwordsA)[1])[1]            
               irun.desc.wav <- c(irun.pwordsA[irun.PA,'sfname'],'Rien')
               irun.desc.tmp <- data.frame(CONDITION=c(irun.tag,'ITI'),                           # CONDITION
                                           PHRASE   =c('Noir','+'),                                # PHRASE
                                           BITMAP   =rep('Noir',2),                             # BITMAP
                                           WAV      =irun.desc.wav,                             # WAV
                                           DUREE    =c(dur.stimulus,irun.iti),  # DUREE
                                           REPONSE1 =c(3,0),                                  # REPONSE1
                                           REPONSE2 =c(0,0),                                  # REPONSE2
                                           REPONSE3 =c(0,0))                                  # REPONSE2 
               irun.pwordsA <- irun.pwordsA[-irun.PA,]  
             }
      )
      irun.desc <- rbind(irun.desc,irun.desc.tmp)
    } 
    # compensate TRs
    #irun.desc$DUREE[length(irun.desc$DUREE)] <- 140  # prolong the last ITI
    ntriggers <- sum(as.numeric(irun.desc$DUREE))
    #nTR <- ceiling(ntriggers/triggers.slice)
    triggers.add <- nTR*triggers.slice - ntriggers
    irun.desc$DUREE[length(irun.desc$DUREE)] <- as.numeric(irun.desc$DUREE[length(irun.desc$DUREE)]) + triggers.add
    # save R data
    save(list=ls(),file=file.path(sdir,sprintf('Stimulation_task-AudioVisAsso1word_Pilot3_%s_Run%d.Rdata',subj,irun)))
    # output timings
    sink(file=file.path(sdir,sprintf('Stimulation_task-AudioVisAsso1word_Pilot3_%s_Run%d.stat',subj,irun)),append=FALSE)
      print(paste('For RUN',irun,':'))     
      print(paste('The number of TRs is',nTR))
      print(paste('The total scanning time should be',nTR*TR,'seconds or',nTR*TR/60,'minutes'))
    sink()
    # output LabView .desc
    write.table(irun.desc,file=file.path(sdir,sprintf('Stimulation_task-AudioVisAsso1word_Pilot3_%s_Run%d.desc',subj,irun)),
                sep='\t',row.names=FALSE,quote=FALSE)  # UTF-8
    write.table(irun.desc,file=file.path(sdir,sprintf('Stimulation_task-AudioVisAsso1wordFr_Pilot3_%s_Run%d.desc',subj,irun)),
                sep='\t',row.names=FALSE,quote=FALSE,fileEncoding='latin1')  # ISO-8859-1 
  }
}
## ---------------------------