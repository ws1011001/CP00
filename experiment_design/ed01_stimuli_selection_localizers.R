## SCRIPT to select words for the localizer tasks in the fMRI study - CP00.
# BY WS, 2019-11-25

# clean up
rm(list=ls())

# setup environments
`%!in%`=Negate(`%in%`)
rdir <- '/data/agora/Chotiga_VOTmultimod/experiment_design/stimuli_selection/Words_Selection_2019_1107_1915/'  # the word list used for the RS task

# read the word lists
load('Lexique_Words_v4.Rdata')                             # the full word pool
load(file.path(rdir,'Selected_Words_byConditions.Rdata'))  # the word list for the RS task

# select words for the two localizer tasks - visual-vOT and auditory
# criteria: number of letters                    [5,6]
#           word frequency (both books and oral) > 5
words.rem <- words.all[words.all$ortho %!in% words.cmr$ortho 
                       & words.all$nblettres %in% c(5,6)
                       & words.all$freqfilms2 > 5,]
num.vis <- 192  # number of words for the visual localizer
num.aud <- 96   # number of words for the auditory localizer
num.nul <- dim(words.rem)[1]-num.vis-num.aud
VarMatched <- c('nbsyll','freqlivres','freqfilms2','nblettres','nbphons','old20','pld20','puphon')
LocaComparisonP <- rep(0,length(VarMatched))
while (any(LocaComparisonP < 0.1)){
  randWds <- sample(c(rep(1,num.vis),rep(2,num.aud),rep(0,num.nul)))
  words.pre <- words.rem[randWds!=0,VarMatched]
  LocaComparison <- lapply(words.pre, function(x) kruskal.test(x,as.factor(randWds[randWds!=0])))
  LocaComparisonP <- unlist(lapply(LocaComparison, function(x) x$p.value))
}

# check the matches and save the rsults
print(paste('#####Quick Check - Localizers##### The Comparison results are: P =',LocaComparisonP))
words.rem$locaIdx <- randWds                          
words.loc <- words.rem[words.rem$locaIdx!=0,]
words.vis <- words.loc[words.loc$locaIdx==1,]
words.aud <- words.loc[words.loc$locaIdx==2,]
save(words.rem,words.loc,words.vis,words.aud,LocaComparison,file=file.path(rdir,'Selected_Words_byLocalizers.Rdata'))
sink(file=file.path(rdir,'Statistics_byLocalizers.txt'))
print('#####Descriptive Statistics#####')
print(describeBy(words.loc,group=words.loc$locaIdx),digits=4)
print('#####Kruskal-Wallis Test Between Units#####')
print(LocaComparison,digits=4)
sink()

# output the word lists
write.csv(words.vis,file=file.path(rdir,'Selected_Words_VisualLocalizer.csv'),row.names=FALSE)
write.csv(words.aud,file=file.path(rdir,'Selected_Words_AduitoryLocalizer.csv'),row.names=FALSE)

# generate consonants from real words for the visual localizer
# consonants in the real words list: b,c,ç,d,f,g,h,j,k,l,m,n,p,q,r,s,t,v,x (not include w and z)
words.vis <- read.csv(file=file.path(rdir,'Selected_Words_VisualLocalizer.csv'))
ortho.vis <- words.vis$ortho
ortho.sum <- table(unlist(strsplit(as.vector(ortho.vis), ""), use.names=FALSE)) 
conso.sum <- as.data.frame(ortho.sum)
conso.sum <- conso.sum[conso.sum$Var1 %in% c('b','c','ç','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','x'),]
consonants.vis <- sapply(words.vis$nblettres, 
                         function(x) paste(sample(x=conso.sum$Var1,size=x,
                                                  replace=FALSE,prob=conso.sum$Freq/sum(conso.sum$Freq)),
                                           collapse=''))
consonants.vis.sum <- as.data.frame(table(unlist(strsplit(as.vector(consonants.vis), ""), use.names=FALSE)))
stimuli.vis <- data.frame(stimulus=c(as.vector(ortho.vis),consonants.vis),type=c(rep('word',192),rep('consonant',192)))
write.csv(stimuli.vis,file=file.path(rdir,'Stimuli_Visual_Localizer.csv'),row.names=FALSE)

# summarize the phonemes of the auditory words
words.aud <- read.csv(file=file.path(rdir,'Selected_Words_AduitoryLocalizer.csv'))
phons.aud <- words.aud$phon
phons.sum <- table(unlist(strsplit(as.vector(phons.aud), ""), use.names=FALSE))

# select pseudowords to keep the same set of phonemes with the real words
pwords <- read.csv(file=file.path(rdir,'Selected_Pseudowords_Candidates.csv'))
phons.pwords <- unique(as.vector(pwords$phon))
pwords.sum <- table(unlist(strsplit(phons.pwords, ""), use.names=FALSE))
# Solution I
while (abs.sum>=80){
  pwords.tmp <- phons.pwords[sample(1:length(phons.pwords))][1:96]  
  pwords.sum <- table(unlist(strsplit(pwords.tmp, ""), use.names=FALSE)) 
  sel.inse <- intersect(names(phons.sum),names(pwords.sum))
  sel.diff <- setdiff(union(names(phons.sum),names(pwords.sum)),sel.inse)
  abs.inse <- abs(as.numeric(phons.sum[sel.inse] - pwords.sum[sel.inse]))
  abs.diff <- abs(na.omit(c(as.numeric(phons.sum[sel.diff]),as.numeric(pwords.sum[sel.diff]))))
  abs.sum <- sum(abs.inse)+sum(abs.diff)
}
sel.pwords <- pwords[pwords$phon %in% pwords.tmp,]
wilcox.test(sel.pwords$syll,words.aud$nbsyll)  # p=0.6665
stimuli.aud <- data.frame(stimulus=c(as.vector(words.aud$orthoND),as.vector(sel.pwords$sfname),paste0(sel.pwords$sfname,'_vocoded')),
                          type=c(rep('word',96),rep('pseudoword',96),rep('vocoded',96)))
write.csv(sel.pwords,file=file.path(rdir,'Selected_Pseudowords.csv'),row.names=FALSE)
write.csv(stimuli.aud,file=file.path(rdir,'Stimuli_Auditory_Localizer.csv'),row.names=FALSE)
# Solution II
pwords.pool <- phons.pwords
phons.clean <- setdiff(names(pwords.sum),names(phons.sum))
for (k in 1:length(phons.clean)){
  pwords.rm <- pwords.pool[grep(phons.clean[k],pwords.pool)]
  pwords.pool <- setdiff(pwords.pool,pwords.rm)
}
pwords.list <- c()
pwords.list.sum <- NULL
for (i in 1:length(phons.sum)){
  phon.name <- names(phons.sum)[i]                          # phonetic symbol
  if (phon.name %in% names(pwords.list.sum)){
    phon.numb <- phons.sum[i]-pwords.list.sum[phon.name]                                 # required number of pseudowords
  } else {
    phon.numb <- phons.sum[i]
  }
  if (phon.numb!=0){
    pwords.tmp <- pwords.pool[grep(phon.name,pwords.pool,fixed=TRUE)]   # select pseudowords by the phonetic symbol 
    sel.diff <- -1
    while (any(sel.diff<0) | any(sel.diff[1:i]!=0)){          # not good, do it again
      pwords.sel <- c(pwords.tmp[sample(1:length(pwords.tmp))][1:phon.numb])
      pwords.sel.sum <- table(unlist(strsplit(c(pwords.list,pwords.sel), ""), use.names=FALSE))
      sel.diff <- as.numeric(phons.sum[names(pwords.sel.sum)] - pwords.sel.sum)
    }
    print(sel.diff)
    pwords.list <- c(pwords.list,pwords.sel)
    pwords.list.sum <- table(unlist(strsplit(pwords.list, ""), use.names=FALSE))
    pwords.pool <- setdiff(pwords.pool,pwords.tmp)   
  }

  if (length(pwords.list)>=96){
    break()
  }
}
candidates_token <- format(Sys.time(),"%Y_%m%d_%H%M")
write.table(pwords.list,file=file.path(rdir,paste0('Pseudowords_candidates_',candidates_token,'.txt')),
            row.names=FALSE,col.names=FALSE,quote=FALSE)
sink(file=file.path(rdir,paste0('Pseudowords_phonemes_',candidates_token,'.txt')))
print('##### Real Words - Phonemes #####')
phons.sum
print('##### Pseudowords - Phonemes #####')
pwords.list.sum
print('##### Real Words > Pseudowords - Phonemes #####')
phons.sum[names(pwords.list.sum)] - pwords.list.sum
sink()

# select another set of words for the visual localizer
VisComparisonP <- rep(0,length(VarMatched))
while (any(VisComparisonP < 0.15)){
  words.rem.vis <- rbind(words.rem[words.rem$locaIdx %in% c(0,2),],words.vis[as.logical(sample(rep(c(0,1),each=96))),])
  randWds <- sample(c(rep(1,num.vis),rep(0,dim(words.rem.vis)[1]-num.vis)))
  words.pre <- rbind(words.rem.vis[randWds!=0,VarMatched],words.vis[,VarMatched])
  VisComparison <- lapply(words.pre, function(x) wilcox.test(x[1:num.vis],x[(num.vis+1):2*num.vis]))
  VisComparisonP <- unlist(lapply(VisComparison, function(x) x$p.value))
  print(VisComparisonP)
}
words.vis2 <- words.rem.vis[randWds==1,]
write.csv(words.vis2,file=file.path(rdir,'Selected_Words_VisualLocalizer_TEST82msSequence.csv'),row.names=FALSE)
ortho.vis <- words.vis2$ortho
ortho.sum <- table(unlist(strsplit(as.vector(ortho.vis), ""), use.names=FALSE)) 
conso.sum <- as.data.frame(ortho.sum)
conso.sum <- conso.sum[conso.sum$Var1 %in% c('b','c','ç','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','x'),]
consonants.vis <- sapply(words.vis2$nblettres, 
                         function(x) paste(sample(x=conso.sum$Var1,size=x,
                                                  replace=FALSE,prob=conso.sum$Freq/sum(conso.sum$Freq)),
                                           collapse=''))
consonants.vis.sum <- as.data.frame(table(unlist(strsplit(as.vector(consonants.vis), ""), use.names=FALSE)))
stimuli.vis <- data.frame(stimulus=c(as.vector(ortho.vis),consonants.vis),type=c(rep('word',192),rep('consonant',192)))
write.csv(stimuli.vis,file=file.path(rdir,'Stimuli_Visual_Localizer_TEST82msSequence.csv'),row.names=FALSE)
