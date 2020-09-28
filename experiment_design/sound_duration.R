## SCRIPT to calculate the duratuon of sound files.
# By WS, 2019-12-10.

# clean up
rm(list=ls())

# set environments
library('tuneR')
library('seewave')
wdir <- '/data/agora/Chotiga - Intermod2/CP00/stimuli_selection/'
sdir <- file.path(wdir,'Sound_Files')

# read sound files info
sf <- read.csv(file=file.path(sdir,'SoundLength.csv'))
nf <- dim(sf)[1]

# calculate duration
v2length <- rep(0,nf)
for (i in 1:nf){
  wavf <- paste0(sf$NameSelectedFile[i],'.wav')    # file name in .wav format
  wavo <- readWave(filename=file.path(sdir,'Selected_Stimuli_191209',wavf))  # wave object
  wavd <- duration(wavo)                           # duration in seconds
  sprintf('The duration of sould file %s is %f seconds.\n',wavf,wavd)
  v2length[i] <- wavd
}

# update sound files info
sf$v2length <- v2length
write.csv(sf,file=file.path(sdir,'SoundLength_v2.csv'),row.names=FALSE)