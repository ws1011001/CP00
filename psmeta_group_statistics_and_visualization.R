## ---------------------------
## [script name] psmeta_group_statistics_and_visualization.R
## SCRIPT to ...
##
## By Shuai Wang, [date] 2021-09-10
## ---------------------------
## Notes:
## ---------------------------

## clean up
rm(list=ls())
## ---------------------------

## Set environment (packages, functions, working path etc.)
# Load up packages
library(stringr)
library(psych)
library(plyr)  # ddply()
library(plotrix)  # std.errors()
library(DescTools)
library(rmatio)  # read.mat()
library(reshape2)  # melt()
library(ggplot2)
library(cowplot)
library(plot3D)    # scatter3D()
library(EnvStats)  # oneSamplePermutationTest()
source('~/Projects/_nitools/rcomparison.R')
source('~/Projects/_nitools/rplot.R')
# Setup working paths
mdir <- '/media/wang/BON/Projects/CP00'
wdir <- file.path(mdir, 'AudioVisAsso')
ddir <- file.path(wdir, 'derivatives')
rdir <- file.path(wdir, 'results')
vdir <- file.path(rdir, 'multivariate')
tdir <- file.path(rdir, 'repetition')
pdir <- file.path(mdir, 'manuscript', 'report')
# setup general parameters
n <- 22  # number of subjects
# define data files
fsubject <- file.path(mdir, 'participants.tsv')
fbehava1 <- file.path(rdir, 'group_task-AudioVisAssos1word_events_stats.tsv')
fmnilocv <- file.path(rdir, 'activation', '1.task-LocaVis1p75', 'group_space-MNI152NLin2009cAsym_mask-ilvOT-coordinates.csv')
fpsclocv <- file.path(rdir, 'activation', '1.task-LocaVis1p75', 'group_task-LocaVis1p75_GLM.wBIM.wPSC.wNR24a_PSC.csv')
fpscloca <- file.path(rdir, 'activation', 'group_task-LocaAudio2p5_GLM.wPSC.wNR24a_PSC.csv')
fpscava1 <- file.path(rdir, 'activation', 'group_task-AudioVisAssos1word_GLM.wBIM.wPSC.wNR24a_PSC.csv')
fmvpasel <- file.path(rdir, 'multivariate', 'group_task-AudioVisAssos1word_MVPA-Perm10000_classifier-selection_unimodal+crossmodal.csv') 
fmvparoi <- file.path(rdir, 'multivariate', 'group_task-AudioVisAssos1word_MVPA-ST3-PermACC_unimodal+crossmodal_L2ROCV.csv')
df_acc_rois <- read.csv(file=fmvparoi, stringsAsFactors=FALSE)
fpscrses <- file.path(tdir, 'group_task-AudioVisAssos2words_RSE_PSC+TENT.csv')
# read data
df_sub_info <- read.csv(file=fsubject, stringsAsFactors=FALSE, sep='\t')
df_sub_behv <- read.csv(file=fbehava1, stringsAsFactors=FALSE, sep='\t')
df_mni_locv <- read.csv(file=fmnilocv, stringsAsFactors=FALSE)
df_psc_locv <- read.csv(file=fpsclocv, stringsAsFactors=FALSE)
df_psc_loca <- read.csv(file=fpscloca, stringsAsFactors=FALSE)
df_psc_ava1 <- read.csv(file=fpscava1, stringsAsFactors=FALSE)
df_acc_clfs <- read.csv(file=fmvpasel, stringsAsFactors=FALSE)
df_psc_rses <- read.csv(file=fpscrses, stringsAsFactors=FALSE)
## ---------------------------

## Subject information
df_sub_info <- df_sub_info[4:25,]
describeBy(df_sub_info)
## ---------------------------

## Visual localizer (Coordinates and PSC)
# plot individual peaks (MNI space)
fplot <- file.path(rdir, 'activation', 'group_task-LocaVis1p75_individual-peaks_N18.png')
png(filename = fplot, width = 8, height = 6, unit = 'in', res = 300)
  scatter3D(df_mni_locv$x, df_mni_locv$y, df_mni_locv$z, colvar = df_mni_locv$T, pch = 20, cex = 3, main = 'Individual Peak Coordinates (MNI)', bty = 'g',
            xlab = 'X', ylab = 'Y', zlab = 'Z', ticktype = 'detailed', clab = 'T value', clim = c(3, 7), col = ramp.col (col = c('yellow', 'red')))
dev.off()
# Select individuals according to T-value
subjs <- df_mni_locv$participant_id[df_mni_locv$T > df_mni_locv$T001]
# Compare PSCs for individual ROIs
thisroi <- 'ilvOT-sph8mm'
df_psc_locv_thisroi <- df_psc_locv[df_psc_locv$ROI_label==thisroi & df_psc_locv$participant_id %in% subjs,]
rcomparison_sy(df_psc_locv_thisroi, 'PSC', 'condition', c('words', 'consonants'), 'participant_id')
# plot comparisons
p_signs <- data.frame(sleft = c(1), sright = c(2), slabs = c('***'), spos = c(1.85),
                              labsize = 4, vjust = 0, stringsAsFactors = FALSE) 
p <- rplot_box2(df_psc_locv_thisroi$PSC, df_psc_locv_thisroi$condition, bColor = c('gray40', 'gray80'), fColor = c('gray40', 'gray80'), 
                gOrder = c('words', 'consonants'), gLabel = c('Words', 'Consonants'), textSz = 15, title = 'Individual ROI', 
                aLabel = c('', 'Percent Signal Change'), Yrange = c(-0.1, 2), sBars = p_signs)
fplot <- file.path(rdir, 'activation', sprintf('group_task-LocaVis1p75_PSC_%s.png', thisroi))
save_plot(filename = fplot, p, base_height = 4, base_asp = 0.6)
## ---------------------------

## Auditory localizer (PSC)
thisroi <- 'ilvOT-sph8mm'#'lvOT-visual'#
if (substr(thisroi, 1, 1) == 'i'){
  df_psc_loca_thisroi <- df_psc_loca[df_psc_loca$ROI_label==thisroi & df_psc_loca$participant_id %in% subjs,]
} else {
  df_psc_loca_thisroi <- df_psc_loca[df_psc_loca$ROI_label==thisroi,]
}
# compare PSC for ROIs
rcomparison_sy(df_psc_loca_thisroi, 'PSC', 'condition', c('words', 'pseudowords', 'scrambled'), 'participant_id')
# plot comparisons
#p_signs <- data.frame(sleft=c(1, 2), sright=c(3, 3), slabs=c('**', '***'), spos=c(0.58, 0.5), labsize=4, vjust=0, stringsAsFactors=FALSE)  # lvOT-visual 
p_signs <- data.frame(sleft=c(1, 2), sright=c(3, 3), slabs=c('**', '**'), spos=c(0.68, 0.6), labsize=4, vjust=0, stringsAsFactors=FALSE)  # ilvOT-sph8mm
p <- rplot_box2(df_psc_loca_thisroi$PSC, df_psc_loca_thisroi$condition, bColor=c('gray40', 'gray60', 'gray80'), fColor=c('gray40', 'gray60', 'gray80'), 
                gOrder=c('words', 'pseudowords', 'scrambled'), gLabel=c('Words', 'Pseudowords', 'Scrambled'), textSz=15, title='Individual ROI', 
                aLabel=c('', 'Percent Signal Change'), Yrange=c(-0.3, 0.7), Xangle=30, Xvjust=0.7, sBars=p_signs)
fplot <- file.path(rdir, 'activation', sprintf('group_task-LocaAudio2p5_PSC_%s.png', thisroi))
save_plot(filename = fplot, p, base_height = 4, base_asp = 0.7)
## ---------------------------

## AVA-1word task (PSC)
# get parameters
stimuli       <- c('WA', 'WV', 'PA', 'PV')
stimuli_color <- c('lightblue4', 'darkseagreen4', 'lightblue1', 'darkseagreen1')
#rois <- unique(df_psc_ava1$ROI_label)
ava1_rois_grp <- c('lvOT-visual', 'rvOT-visual')
ava1_rois_ind <- c('ilvOT-sph4mm', 'ilvOT-sph5mm', 'ilvOT-sph6mm', 'ilvOT-sph7mm', 'ilvOT-sph8mm', 'ilvOT')
# test if PSC is different from zero
df_psc_ava1_test1 <- sapply(rois, function(x)  # if ACC is greater than 50% for each modality 
                            rcomparison_p1(df_psc_ava1[df_psc_ava1$ROI_label == x,], 'condition', 'PSC', nperm = 10000),
                            simplify = FALSE, USE.NAMES = TRUE)
# compare conditions
df_psc_ava1_test2 <- sapply(rois, function(x)  # if ACCs are different between modalities
                            rcomparison_sy(df_psc_ava1[df_psc_ava1$ROI_label == x,], 'PSC', 'condition', stimuli, 'participant_id'),
                            simplify = FALSE, USE.NAMES = TRUE)
# plot tests for each ROI
for (iroi in rois){
  # extract data for this ROI
  df_psc_ava1_iroi <- df_psc_ava1[df_psc_ava1$ROI_label == iroi,]
  p_Y <- round(c(min(df_psc_ava1_iroi$PSC), max(df_psc_ava1_iroi$PSC)), digits = 1) + c(-0.05, 0.1)  # determine Y range
  # extract significance
  p_P <- data.frame(val = sapply(stimuli, function(x) df_psc_ava1_test1[iroi][[1]][x][[1]]$p.value))
  p_P$val <- p.adjust(p_P$val, method = 'fdr')
  p_P$sig <- p_P$val < 0.05
  if (sum(p_P$sig) > 0){
    p_P$lab <- rep('', 4)
    p_P$lab[p_P$val < 0.05] <- '*'
    p_P$lab[p_P$val < 0.01] <- '**' 
    p_P$lab[p_P$val < 0.001] <- '***'
    p_signs <- data.frame(sleft = c(1:4)[p_P$sig], sright = c(1:4)[p_P$sig], slabs = p_P$lab[p_P$sig], 
                          spos = rep(p_Y[2] - 0.04, sum(p_P$sig)), labsize = 5, vjust = 1, stringsAsFactors = FALSE)   
  } else {
    p_signs <- NULL
  }
  # boxplot
  p <- rplot_box2(df_psc_ava1_iroi$PSC, df_psc_ava1_iroi$condition, title = iroi, bColor = stimuli_color, fColor = stimuli_color, 
                  gOrder = stimuli, gLabel = stimuli, aLabel = c('', 'Percent Signal Change'), Yrange = p_Y, sBars = p_signs)
  # output figure
  fplot <- file.path(rdir, 'activation', sprintf('group_task-AudioVisAssos1word_PSC_ROI-%s_v1.0.png', iroi))
  save_plot(filename = fplot, p, base_height = 5, base_asp = 0.6)
}
## ---------------------------

## MVPA classifiers comparison
# get parameters
classifiers       <- c('LDA', 'SVClin', 'GNB', 'SVCrbf')
classifiers_label <- c('LDA', 'SVM-lin', 'GNB', 'SVM-RBF')
classifiers_color <- c('gray40', 'gray50', 'gray60', 'gray70')
# compare classifiers for each decoding modality
df_acc_clfs_test <- sapply(unique(df_acc_clfs$modality), function(x)  # if ACCs are different between modalities
                           rcomparison_sy(df_acc_clfs[df_acc_clfs$modality == x,], 'ACC', 'classifier', classifiers, 'participant_id'),
                           simplify = FALSE, USE.NAMES = TRUE)
# plot comparisons
fplot <- file.path(rdir, 'multivariate', 'group_task-AudioVisAssos1word_MVPA_classifier-selection.png')
ps <- lapply(unique(df_acc_clfs$modality), function(x)
                    rplot_box2(gdata = df_acc_clfs[df_acc_clfs$modality == x, 'ACC'], groups = df_acc_clfs$classifier[df_acc_clfs$modality == x],
                               gOrder = classifiers, gLabel = classifiers_label, fColor = classifiers_color, aLabel = c(x, 'ACC'), Xangle = 90)
                    + ylim(c(0.3, 0.7)) + geom_hline(yintercept = 0.5, linetype = 'dashed'))
p <- plot_grid(plotlist = ps, align = 'h', nrow = 1)
save_plot(filename = fplot, p, base_height = 8, base_asp = 1)
## Notes: SVC-lin is selected because no classifiers are obviously better than it.
## ---------------------------

## MVPA decoding ACC for each ROI
# get parameters
modalities       <- c('visual', 'auditory', 'visual2', 'auditory2')
modalities_label <- c('Visual', 'Auditory', 'Vis2Aud', 'Aud2Vis')
modalities_color <- c('gold3', 'gold', 'seagreen4', 'seagreen1')
#rois <- unique(df_acc_rois$ROI_label)
rois <- c('lvOT-visual', 'ilvOT-sph8mm')
#rois <- c('ilvOT-sph4mm', 'ilvOT-sph5mm', 'ilvOT-sph6mm', 'ilvOT-sph7mm', 'ilvOT-sph8mm')
#rois <- c('lvOT-1', 'lvOT-2', 'lvOT-3', 'lvOT-4', 'lvOT-sph4mm', 'lvOT-sph5mm', 'lvOT-sph6mm', 
#          'ilvOT', 'ilvOT-sph4mm', 'ilvOT-sph5mm', 'ilvOT-sph6mm', 
#          'lvOT-visual', 'lvOT-visualonly', 'lvOT-auditory', 'lvOT-auditoryonly', 'lvOT-both', 
#          'lSTG-auditory', 'rSTG-auditory')
# test if ACC is greater than 50%
df_acc_rois_svclin <- df_acc_rois[df_acc_rois$classifier == 'SVClin' & df_acc_rois$participant_id %in% subjs,]
#df_acc_rois_svclin <- df_acc_rois[df_acc_rois$classifier == 'SVClin',]
df_acc_rois_test1 <- sapply(rois, function(x)  # if ACC is greater than 50% for each modality 
                            rcomparison_p1(df_acc_rois_svclin[df_acc_rois_svclin$ROI_label==x,], 'modality', 'ACC', 0.5, 'greater', 10000),
                            simplify=FALSE, USE.NAMES=TRUE)
#df_acc_rois_test1 <- sapply(rois, function(x)  # if ACC is greater than 50% for each modality 
#                            rcomparison_p1(df_acc_rois_svclin[df_acc_rois_svclin$ROI_label==x,], 'modality', 'ACC', 0.5, 'two.side', 10000),
#                            simplify=FALSE, USE.NAMES=TRUE)
#df_acc_rois_test2 <- sapply(rois, function(x)  # if ACCs are different between modalities
#                          rcomparison_sy(df_acc_rois_svclin[df_acc_rois_svclin$ROI_label == x,], 'ACC', 'modality', modalities, 'participant_id'),
#                          simplify = FALSE, USE.NAMES = TRUE)
# plot tests for all ROIs
fplot <- file.path(rdir, 'multivariate', 'group_task-AudioVisAssos1word_MVPA-ST3-ACC_SVClin.png')
ps <- lapply(rois, function(x)
             rplot_box2(gdata=df_acc_rois_svclin[df_acc_rois_svclin$ROI_label==x, 'ACC'], groups=df_acc_rois_svclin$modality[df_acc_rois_svclin$ROI_label==x],
                        gOrder=modalities, gLabel=modalities_label, fColor=modalities_color, aLabel=c(x, 'ACC'), Xangle=90)
             + ylim(c(0.3, 0.7)) + geom_hline(yintercept=0.5, linetype='dashed'))
p <- plot_grid(plotlist=ps, nrow=2, ncol=3)
save_plot(filename=fplot, p, base_height=8, base_asp=0.9)
# plot tests for each ROI
for (iroi in rois){
  # extract data for this ROI
  df_acc_iroi <- df_acc_rois_svclin[df_acc_rois_svclin$ROI_label==iroi,]
  #p_Y <- round(c(min(df_acc_iroi$ACC), max(df_acc_iroi$ACC)), digits=1) + c(-0.1, 0.2)  # determine Y range
  p_Y <- c(0.45, 0.65)
  # extract significance
  p_P <- data.frame(val=sapply(modalities, function(x) df_acc_rois_test1[iroi][[1]][x][[1]]$p.value))
  p_P$sig <- p_P$val < 0.05
  if (sum(p_P$sig) > 0){
    p_P$lab <- rep('', 4)
    p_P$lab[p_P$val < 0.05] <- '*'
    p_P$lab[p_P$val < 0.01] <- '**' 
    p_P$lab[p_P$val < 0.001] <- '***'
    p_signs <- data.frame(sleft=c(1:4)[p_P$sig], sright=c(1:4)[p_P$sig], slabs=p_P$lab[p_P$sig], 
                          spos=rep(p_Y[2] - 0.01, sum(p_P$sig)), labsize=5, vjust=1, stringsAsFactors=FALSE)   
  } else {
    p_signs <- NULL
  }
  # boxplot
  p <- rplot_box2(df_acc_iroi$ACC, df_acc_iroi$modality, title = iroi, bColor = modalities_color, fColor = modalities_color, 
                  gOrder = modalities, gLabel = modalities_label, aLabel = c('', 'Accuracy'), Xangle = 90, Yrange = p_Y, sBars = p_signs)+
       geom_hline(yintercept = 0.5, linetype = 'dashed')
  # output figure
  fplot <- file.path(rdir, 'multivariate', sprintf('group_task-AudioVisAssos1word_MVPA-ST1-ACC_ROI-%s.png', iroi))
  save_plot(filename = fplot, p, base_height = 5, base_asp = 0.6)
}
## ---------------------------

## ROI-based RSA
rdm_models <- c('amodal lexico', 'audmod nolexi', 'audmod lexico', 'vismod nolexi', 'vismod lexico', 'mmodal nolexi', 'mmodal lexico')
rdm_models_label <- c('Amodal lexicon-sensitive', 'Auditory lexicon-insensitive', 'Auditory lexicon-sensitive', 
                      'Visual lexicon-insensitive', 'Visual lexicon-sensitive', 'Multimodal lexicon-insensitive', 'Multimodal lexicon-sensitive')
rdm_models_color <- c('gray', 'cyan1', 'cyan3', 'gold1', 'gold3', 'orchid1', 'orchid3')
rdm_rois <- c('lvOT-Bouhali2019-gGM', 'lvOT-visual', 'lvOT-auditory', 'lSTG-auditory', 'rSTG-auditory', 'ilvOT', 'ilvOT-sph4mm')
rdm_rois_label <- c('lvOT-Bouhali2019', 'gvLVOT', 'gaLVOT', 'gaLSTG', 'gaRSTG', 'ivLVOT', 'ivLVOT (4mm)')
names(rdm_rois_label) <- rdm_rois
# extract correlation data
rdm_cor_group <- data.frame(v1 = character(), v2 = factor(), v3 = factor(), v4 = numeric())
for (i in 1:n){
  # reshape correlation data
  frdms <- file.path(vdir, 'tvrRSA', sprintf('sub-%02d_RDMs-correlatons.mat', i))
  rdm_data <- read.mat(frdms)
  rdm_cor1 <- as.matrix(rdm_data$RDMsCorr$Z[[1]])
  rdm_size <- dim(rdm_cor1)[1]
  rdm_cor1[seq(1, rdm_size * rdm_size, rdm_size + 1)] <- NA
  rdm_name <- unlist(lapply(rdm_data$RDMsCorr$M$name, function (x) strsplit(x, split = ' | ', fixed = TRUE)[[1]][[1]]))
  colnames(rdm_cor1) <- rdm_name
  rownames(rdm_cor1) <- rdm_name
  rdm_cor2 <- melt(rdm_cor1)
  # group correlation data
  rdm_cor_group <- rbind(rdm_cor_group, cbind(rep(sprintf('sub-%02d', i), rdm_size^2), rdm_cor2), deparse.level = 0)
}
names(rdm_cor_group) <- c('participant_id', 'rdm1', 'rdm2', 'z')
# plot correlation matrix of models
rdm_cor_models <- rdm_cor2[rdm_cor2$Var1 %in% rdm_models & rdm_cor2$Var2 %in% rdm_models,]
rdm_cor_models$Var1 <- factor(rdm_cor_models$Var1, levels = rdm_models)
rdm_cor_models$Var2 <- factor(rdm_cor_models$Var2, levels = rdm_models)
rdm_cor_models$value <- FisherZInv(rdm_cor_models$value)  # convert Fisher-z to rho
p_rdm_models <- rplot_heatmap(rdm_cor_models, zrange = c(-0.5, 1.0), colors = 'Blue-Red', xLabel = rdm_models_label, ctitle = 'Spearman\nCorrelation')
save_plot(filename = file.path(vdir, 'group_task-AudioVisAssos1word_RSA-models-correlations_v1.0.png'), p_rdm_models, base_height = 10, base_asp = 1)
# compare models for each ROI
rdm_cor_limits <- list(c(0, 0.15), c(-0.03, 0.05), c(-0.03, 0.05), c(-0.1, 0.35), c(-0.1, 0.5), c(-0.03, 0.05), c(-0.03, 0.05))
names(rdm_cor_limits) <- rdm_rois
for (iroi in rdm_rois){
  # group data for this ROI
  rdm_iroi <- rdm_cor_group[rdm_cor_group$rdm1 == iroi & rdm_cor_group$rdm2 %in% rdm_models, ]
  # summarize statistics
  rdm_iroi_desc <- ddply(rdm_iroi, .(rdm2), summarize, mean = mean(z), std = std.error(z))
  cat(sprintf('The range of correlation values is %f to %f for ROI %s. \n', min(rdm_iroi_desc$mean), max(rdm_iroi_desc$mean), iroi))
  # plot correlations (Fisher-z)
  p_iroi <- rplot_barI(x = 1:length(rdm_models), y = rdm_iroi_desc$mean, errs = rdm_iroi_desc$std, yLimit = rdm_cor_limits[iroi][[1]],
                       f = 1:length(rdm_models), fPalette = rdm_models_color, gLabel = rdm_models_label, Xangle = 90, Xvjust = 0.5,
                       aLabel = c('RDM Models', 'Correlation (Fisher-z)'), title = rdm_rois_label[iroi])
  # add images and output figure
  p_imgs_pos <- rdm_cor_limits[iroi][[1]][1] - (rdm_cor_limits[iroi][[1]][2] - rdm_cor_limits[iroi][[1]][1]) * 0.15
  png(filename = file.path(pdir, sprintf('group_RSA-models_ROI-%s_correlation.png', iroi)), width = 4, height = 6, unit = 'in', res = 300)
    rplot_Ximages(p_iroi, imgs, ypos = p_imgs_pos)
  dev.off()
}
## ---------------------------

## Repetition Suppression Effect (RSE)
# get parameters
#rse_rois_grp <- c('lvOT-visual', 'rvOT-visual', 'lSTG-auditory', 'rSTG-auditory')
rse_rois_grp <- unique(df_psc_rses$ROI_label)
#rse_rois_ind <- c('ilvOT-gm-sph4mm', 'ilvOT-gm-sph5mm', 'ilvOT-gm-sph6mm', 'ilvOT-gm-sph7mm', 'ilvOT-gm-sph8mm',
#                  'ilvOT-sph4mm', 'ilvOT-sph5mm', 'ilvOT-sph6mm', 'ilvOT-sph7mm', 'ilvOT-sph8mm', 'ilvOT')
#rse_rois_ind <- c('ilvOT-sph6mm', 'ilvOT-sph7mm', 'ilvOT-sph8mm')
conditions <- c('SISMa', 'DISMa', 'SISMv', 'DISMv', 'SIDMa', 'DIDMa', 'SIDMv', 'DIDMv')
conditions_color <- c('gold2', 'gold2', 'cyan3', 'cyan3', 'orange2', 'orange2', 'palegreen', 'palegreen')
conditions_tests <- c('SISMa - DISMa = 0', 'SISMv - DISMv = 0', 'SIDMa - DIDMa = 0', 'SIDMv - DIDMv = 0')
FIRs <- c('IRF1', 'IRF2', 'IRF3', 'IRF4', 'IRF5', 'IRF6', 'IRF7', 'IRF8', 'IRF9')
# PSC tests with group ROIs
rse_psc_test_grp <- sapply(rse_rois_grp, function(x) 
                           rcomparison_sy(df_psc_rses[df_psc_rses$ROI_label==x,], 'PSC', 'condition', conditions, 'participant_id', direc='less'),
                           simplify=FALSE, USE.NAMES=TRUE)
# PSC tests with individual ROIs
df_psc_rses_ind <- df_psc_rses[df_psc_rses$participant_id %in% subjs,]  # N = 18
rse_psc_test_ind <- sapply(rse_rois_ind, function(x) 
                           rcomparison_sy(df_psc_rses_ind[df_psc_rses_ind$ROI_label==x,], 'PSC', 'condition', conditions, 'participant_id', direc='less'),
                           simplify=FALSE, USE.NAMES=TRUE)
# FIR tests
rse_fir_test_grp <- list()
for (ifir in FIRs){
  rse_fir_test_grp[ifir][[1]] <- sapply(rse_rois_grp, function(x) 
                                        rcomparison_sy(df_psc_rses[df_psc_rses$ROI_label==x,], ifir, 'condition', conditions, 'participant_id', direc='less'),
                                        simplify=FALSE, USE.NAMES=TRUE)
}
rse_fir_test_ind <- list()
for (ifir in FIRs){
  rse_fir_test_ind[ifir][[1]] <- sapply(rse_rois_ind, function(x) 
                                        rcomparison_sy(df_psc_rses_ind[df_psc_rses_ind$ROI_label==x,], ifir, 'condition', conditions, 'participant_id', direc='less'),
                                        simplify=FALSE, USE.NAMES=TRUE)
}  

# PLOT PSC
#rse_rois <- c(rse_rois_grp, rse_rois_ind)
rse_rois <- rse_rois_grp
rse_labels <- c('SameAA', 'DiffAA', 'SameVV', 'DiffVV', 'SameAV', 'DiffAV', 'SameVA', 'DiffVA')
for (iroi in rse_rois){
  # extract data for this ROI
  if (substr(iroi, 1, 1) == 'i'){  # individual ROIs
    df_psc_rses_iroi <- df_psc_rses_ind[df_psc_rses_ind$ROI_label == iroi & df_psc_rses_ind$condition %in% conditions,]
    rse_psc_test <- rse_psc_test_ind
  } else {
    df_psc_rses_iroi <- df_psc_rses[df_psc_rses$ROI_label == iroi & df_psc_rses$condition %in% conditions,]
    rse_psc_test <- rse_psc_test_grp
  }
  ititle <- iroi
  if (iroi == 'gm-AAL3-lOG'){ ititle <- 'left Occipital'}
  if (iroi == 'gm-AAL3-rOG'){ ititle <- 'right Occipital'} 
  if (iroi == 'lvOT-visual'){ ititle <- 'Group ROI' } 
  if (iroi == 'ilvOT-sph8mm'){ ititle <- 'Individual ROI' }
  if (iroi == 'Cohen-2004-sph7mm'){ ititle <- 'LIMA (7mm)' }
  if (iroi == 'Cohen-2004-sph8mm'){ ititle <- 'LIMA (8mm)' }
  # determine Y range
  p_rse_iroi_y <- round(c(min(df_psc_rses_iroi$PSC), max(df_psc_rses_iroi$PSC)), digits = 1) + c(-0.1, 0.2)
  # extract significance
  rse_test_iroi <- rse_psc_test[iroi][[1]]$PSC_PT
  rse_test_iroi <- rse_test_iroi[rse_test_iroi$Comparison %in% conditions_tests,]
  #rse_test_iroi$p.value <- p.adjust(rse_test_iroi$p.value, method='hochberg')
  rse_test_iroi$sig <- rse_test_iroi$p.value < 0.05
  if (sum(rse_test_iroi$sig) > 0){
    rse_test_iroi$lab <- rep('', 4)
    rse_test_iroi$lab[rse_test_iroi$p.value < 0.05] <- '*'
    rse_test_iroi$lab[rse_test_iroi$p.value < 0.01] <- '**' 
    rse_test_iroi$lab[rse_test_iroi$p.value < 0.001] <- '***'
    p_rse_iroi_sig <- data.frame(sleft = c(1, 3, 5, 7)[rse_test_iroi$sig], sright = c(2, 4, 6, 8)[rse_test_iroi$sig], 
                                 slabs = rse_test_iroi$lab[rse_test_iroi$sig], spos = rep(p_rse_iroi_y[2] - 0.08, sum(rse_test_iroi$sig)), 
                                 labsize = 5, vjust = 0.5, stringsAsFactors = FALSE)   
  } else {
    p_rse_iroi_sig <- NULL
  }
  # boxplot
  p_rse_iroi <- rplot_box2(df_psc_rses_iroi$PSC, df_psc_rses_iroi$condition, title = ititle,
                           bColor = conditions_color, fColor = conditions_color, gOrder = conditions, gLabel = rse_labels, 
                           aLabel = c('', 'Percent Signal Change'), Xangle = 90, Yrange = p_rse_iroi_y, sBars = p_rse_iroi_sig)
  # output figure
  fplot <- file.path(tdir, sprintf('group_task-AudioVisAssos2word_Repetition-PSC_ROI-%s_v1.0.png', iroi))
  save_plot(filename = fplot, p_rse_iroi, base_height = 5, base_asp = 0.6)
}
# PLOT FIR
for (iroi in rse_rois){
  # extract data for this ROI
  if (substr(iroi, 1, 1) == 'i'){  # individual ROIs
    repet_fir_iroi <- df_psc_rses_ind[df_psc_rses_ind$ROI_label == iroi & df_psc_rses_ind$condition %in% conditions,]
    rse_fir_test_iroi <- lapply(rse_fir_test_ind, function(x) x[iroi][[1]][2][[1]])
  } else {
    repet_fir_iroi <- df_psc_rses[df_psc_rses$ROI_label == iroi & df_psc_rses$condition %in% conditions,]   
    rse_fir_test_iroi <- lapply(rse_fir_test_grp, function(x) x[iroi][[1]][2][[1]])
  }
  repet_fir_iroi <- describeBy(repet_fir_iroi[,FIRs], group = repet_fir_iroi$condition)
  # plot FIR curve for each test
  for (itest in conditions_tests){
    cat(sprintf('Extract significance for the test %s. \n', itest))
    icond <- strsplit(itest, split = ' |-|=')[[1]][c(1, 4)]
    # extract plot data  
    rse_fir_iroi <- rbind(repet_fir_iroi[icond[1]][[1]], repet_fir_iroi[icond[2]][[1]])
    rse_fir_iroi$condition <- rep(icond, each = length(FIRs))
    # extract significance
    isign <- unlist(lapply(rse_fir_test_iroi, function(x) as.numeric(x$p.value[x$Comparison == itest])))  # uncorrected
    #isign <- p.adjust(unlist(lapply(rse_fir_test_iroi, function(x) as.numeric(x$p.value[x$Comparison == itest]))), method = 'fdr')  # FDR corrected
    rse_fir_iroi$pval <- isign  
    rse_fir_iroi$lab <- ''
    rse_fir_iroi$lab[rse_fir_iroi$pval < 0.05] <- '*'
    rse_fir_iroi$lab[rse_fir_iroi$pval < 0.01] <- '**' 
    rse_fir_iroi$lab[rse_fir_iroi$pval < 0.001] <- '***'
    if (any(isign < 0.05)){
      p_rse_fir_y <- round(max(rse_fir_iroi$mean + rse_fir_iroi$se), digits = 1) * 1.2
      p_rse_fir_sig <- data.frame(x = which(isign < 0.05), y = rep(p_rse_fir_y, length(which(isign < 0.05))),
                                  labels = rse_fir_iroi$lab[which(isign < 0.05)], size = 4, color = 'blue')   
      p_rse_fir_suf <- 'sig'
    } else {
      p_rse_fir_sig <- NULL
      p_rse_fir_suf <- 'non'
    }
    # lineplot
    p_rse_fir_code <- substr(rse_fir_iroi$condition[1], 3, 5)
    switch (p_rse_fir_code,
      SMa={ rse_fir_iroi$condition <- str_replace_all(rse_fir_iroi$condition, c('DISMa'='DiffAA', 'SISMa'='SameAA'))},
      SMv={ rse_fir_iroi$condition <- str_replace_all(rse_fir_iroi$condition, c('DISMv'='DiffVV', 'SISMv'='SameVV'))},
      DMa={ rse_fir_iroi$condition <- str_replace_all(rse_fir_iroi$condition, c('DIDMa'='DiffAV', 'SIDMa'='SameAV'))},
      DMv={ rse_fir_iroi$condition <- str_replace_all(rse_fir_iroi$condition, c('DIDMv'='DiffVA', 'SIDMv'='SameVA'))},
    )
    p_rse_fir <- rplot_line(rse_fir_iroi$vars, rse_fir_iroi$mean, errs=rse_fir_iroi$se, group=rse_fir_iroi$condition, #pTitle=iroi,
                            lColor=c('black', 'darkgray'), aLabel=c('Seconds', 'Percent Signal Change'), sLabel=p_rse_fir_sig)
    # output figure
    fplot <- file.path(tdir, 'FIR', sprintf('group_Repetition-FIR_ROI-%s_%s-%s-%s_v1.0.png', iroi, icond[1], icond[2], p_rse_fir_suf))
    save_plot(filename = fplot, p_rse_fir, base_height = 4, base_asp = 1)
  }
}
## ---------------------------
