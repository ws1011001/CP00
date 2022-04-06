## ---------------------------
## [script name] psmeta_group_statistics_and_visualization.R
##
## SCRIPT to ...
##
## By Shuai Wang, [date] 2021-09-10
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
# load up packages
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
source('~/Projects/nitools/rcomparison.R')
source('~/Projects/nitools/rplot.R')
# setup working paths
mdir <- '/media/wang/BON/Projects/CP00'
wdir <- file.path(mdir, 'AudioVisAsso')
ddir <- file.path(wdir, 'derivatives')
rdir <- file.path(wdir, 'results')
vdir <- file.path(rdir, 'multivariate')
tdir <- file.path(rdir, 'repetition')
pdir <- file.path(mdir, 'manuscript', 'report')
# setup general parameters
n           <- 22  # number of subjects
# define data files
flocav <- file.path(rdir, 'activation', 'task-LocaVis1p75', 'ROIs_left-vOT_task-LocaVis1p75.csv')
flocaa <- file.path(rdir, 'activation', 'group_task-LocaAudio2p5_GLM.wPSC.wNR24a_PSC.csv')
fmvpac <- file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-Perm10000_classifier-selection_unimodal+crossmodal.csv') 
fmvpar <- file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-PermACC_unimodal+crossmodal_LOROCV.csv')
frepet <- file.path(tdir, 'group_task-AudioVisAssos2words_RSE_PSC+TENT.csv')
# read data
locav_xyz <- read.csv(file = flocav, stringsAsFactors = FALSE)
locaa_vot <- read.csv(file = flocaa, stringsAsFactors = FALSE)
mvpac_acc <- read.csv(file = fmvpac, stringsAsFactors = FALSE)
mvpar_acc <- read.csv(file = fmvpar, stringsAsFactors = FALSE)
repet_psc <- read.csv(file = frepet, stringsAsFactors = FALSE)
## ---------------------------

## Visual localizer
# PLOT individual peaks
png(filename = file.path(pdir, 'group_localizer-visual_individual-peaks.png'), width = 8, height = 6, unit = 'in', res = 300)
  scatter3D(locav_xyz$x, locav_xyz$y, locav_xyz$z, colvar = locav_xyz$T, pch = 20, cex = 3, main = 'Individual Peak Coordinates (N = 22)', bty = 'g',
            xlab = 'X', ylab = 'Y', zlab = 'Z', ticktype = 'detailed', clab = 'T value', clim = c(2, 7), col = ramp.col (col = c('yellow', 'red')))
dev.off()
## ---------------------------

## Auditory localizer
thisroi <- 'ilvOT-sph8mm'
locaa_roi <- locaa_vot[locaa_vot$ROI_label == thisroi,]
# Compare PSC for the ROI lvOT-visual
rcomparison_sy(locaa_roi, 'PSC', 'condition', c('words', 'pseudowords', 'scrambled'), 'participant_id')
# PLOT
p_locaa_vot_sig <- data.frame(sleft = c(1, 2), sright = c(3, 3), slabs = c('**', '***'), spos = c(0.65, 0.57),
                              labsize = 4, vjust = 0, stringsAsFactors = FALSE) 
p_locaa_vot <- rplot_box2(locaa_roi$PSC, locaa_roi$condition, bColor = c('gray40', 'gray60', 'gray80'), fColor = c('gray40', 'gray60', 'gray80'), 
                          gOrder = c('words', 'pseudowords', 'scrambled'), gLabel = c('Words', 'Pseudowords', 'Scrambled'), textSz = 15,
                          title = thisroi, aLabel = c('', 'Percent of Signal Change'), Yrange = c(-0.3, 0.7), Xangle = 90, sBars = p_locaa_vot_sig)
fplot <- file.path(rdir, sprintf('Auditory_PSC_%s.png', thisroi))
save_plot(filename = fplot, p_locaa_vot, base_height = 4, base_asp = 0.6)
## ---------------------------

## MVPA classifiers comparison
# get parameters
classifiers       <- c('LDA', 'SVClin', 'GNB', 'SVCrbf')
classifiers_label <- c('LDA', 'SVM-lin', 'GNB', 'SVM-RBF')
classifiers_color <- c('gray40', 'gray50', 'gray60', 'gray70')
# TEST
rcomparison_sy(mvpac_acc[mvpac_acc$modality == 'auditory2',], 'ACC', 'classifier', classifiers, 'participant_id')
# PLOT
fplot <- file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-ACC_classifiers_unimodal+crossmodal.png')
mvpac_acc_ps <- lapply(unique(mvpac_acc$modality), function(x)
                       rplot_box2(gdata = mvpac_acc[mvpac_acc$modality == x, 'ACC'], groups = mvpac_acc$classifier[mvpac_acc$modality == x],
                                  gOrder = classifiers, gLabel = classifiers_label, fColor = classifiers_color, aLabel = c(x, 'ACC'), Xangle = 90)
                       + ylim(c(0.3, 0.7)) + geom_hline(yintercept = 0.5, linetype = 'dashed'))
mvpac_acc_p <- plot_grid(plotlist = mvpac_acc_ps, align = 'h', nrow = 1)
save_plot(filename = fplot, mvpac_acc_p, base_height = 8, base_asp = 1)
## ---------------------------

## MVPA decoding ACC for each ROI
# get parameters
modalities       <- c('visual', 'auditory', 'visual2', 'auditory2')
modalities_label <- c('Vis.', 'Aud.', 'Vis-Aud', 'Aud-Vis')
colors_mods <- c('gold3', 'gold', 'seagreen4', 'seagreen1')
#mvpar_acc_rois <- c('lvOT-1', 'lvOT-2', 'lvOT-3', 'lvOT-4', 'lvOT-sph4mm', 'lvOT-sph5mm', 'lvOT-sph6mm', 
#                    'ilvOT', 'ilvOT-sph4mm', 'ilvOT-sph5mm', 'ilvOT-sph6mm', 
#                    'lvOT-visual', 'lvOT-visualonly', 'lvOT-auditory', 'lvOT-auditoryonly', 'lvOT-both', 
#                    'lSTG-auditory', 'rSTG-auditory')
mvpar_acc_rois <- unique(mvpar_acc$ROI_label)
# TEST
mvpar_acc_svclin <- mvpar_acc[mvpar_acc$classifier == 'SVClin',]
mvpar_acc_test1 <- sapply(mvpar_acc_rois, function(x)  # if ACC is greater than 50% for each modality 
                          rcomparison_p1(mvpar_acc_svclin[mvpar_acc_svclin$ROI_label == x,], 'modality', 'ACC', 0.5, 'greater', 10000),
                          simplify = FALSE, USE.NAMES = TRUE)
mvpar_acc_test2 <- sapply(mvpar_acc_rois, function(x)  # if ACCs are different between modalities
                          rcomparison_sy(mvpar_acc_svclin[mvpar_acc_svclin$ROI_label == x,], 'ACC', 'modality', modalities, 'participant_id'),
                          simplify = FALSE, USE.NAMES = TRUE)
# PLOT all ROIs
fplot <- file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-PermACC_unimodal+crossmodal.png')
mvpar_acc_ps <- lapply(mvpar_acc_rois, function(x)
                       rplot_box2(gdata = mvpar_acc_svclin[mvpar_acc_svclin$ROI_label == x, 'ACC'], 
                                  groups = mvpar_acc_svclin$modality[mvpar_acc_svclin$ROI_label == x],
                                  gOrder = modalities, gLabel = modalities_label, fColor = c('gray40', 'gray50', 'gray60', 'gray70'),
                                  aLabel = c(x, 'ACC'), Xangle = 90)
                       + ylim(c(0.3, 0.7)) + geom_hline(yintercept = 0.5, linetype = 'dashed'))
mvpar_acc_p <- plot_grid(plotlist = mvpar_acc_ps, nrow = 3, ncol = 6)
save_plot(filename = fplot, mvpar_acc_p, base_height = 12, base_asp = 0.8)
# PLOT each ROI
for (iroi in unique(mvpar_acc_svclin$ROI_label)){
  # extract data for this ROI
  mvpar_acc_iroi <- mvpar_acc_svclin[mvpar_acc_svclin$ROI_label == iroi,]
  # determine Y range
  p_acc_iroi_y <- round(c(min(mvpar_acc_iroi$ACC), max(mvpar_acc_iroi$ACC)), digits = 1) + c(-0.1, 0.2)
  # extract significance
  acc_test_iroi <- data.frame(val = sapply(modalities, function(x) mvpar_acc_test1[iroi][[1]][x][[1]]$p.value))
  acc_test_iroi$sig <- acc_test_iroi$val < 0.05
  if (sum(acc_test_iroi$sig) > 0){
    acc_test_iroi$lab <- rep('', 4)
    acc_test_iroi$lab[acc_test_iroi$val < 0.05] <- '*'
    acc_test_iroi$lab[acc_test_iroi$val < 0.01] <- '**' 
    acc_test_iroi$lab[acc_test_iroi$val < 0.001] <- '***'
    p_acc_iroi_sig <- data.frame(sleft = c(1:4)[acc_test_iroi$sig], sright = c(1:4)[acc_test_iroi$sig], slabs = acc_test_iroi$lab[acc_test_iroi$sig], 
                                 spos = rep(p_acc_iroi_y[2] - 0.08, sum(acc_test_iroi$sig)), labsize = 5, vjust = 1, stringsAsFactors = FALSE)   
  } else {
    p_acc_iroi_sig <- NULL
  }
  # boxplot
  p_acc_iroi <- rplot_box2(mvpar_acc_iroi$ACC, mvpar_acc_iroi$modality, title = iroi, bColor = colors_mods, fColor = colors_mods, 
                           gOrder = modalities, gLabel = modalities, aLabel = c('', 'Accuracy'), Xangle = 90, Yrange = p_acc_iroi_y, 
                           sBars = p_acc_iroi_sig) + geom_hline(yintercept = 0.5, linetype = 'dashed')
  # output figure
  fplot <- file.path(vdir, 'tvrMVPC', sprintf('group_task-AudioVisAssos1word_MVPA-ACC_ROI-%s_v1.0.png', iroi))
  save_plot(filename = fplot, p_acc_iroi, base_height = 5, base_asp = 0.6)
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
conditions <- c('SISMa', 'DISMa', 'SISMv', 'DISMv', 'SIDMa', 'DIDMa', 'SIDMv', 'DIDMv')
conditions_color <- c('gray', 'gray', 'cyan2', 'cyan2', 'red2', 'red2', 'palegreen', 'palegreen')
conditions_tests <- c('SISMa - DISMa = 0', 'SISMv - DISMv = 0', 'SIDMa - DIDMa = 0', 'SIDMv - DIDMv = 0')
FIRs <- c('IRF1', 'IRF2', 'IRF3', 'IRF4', 'IRF5', 'IRF6', 'IRF7', 'IRF8', 'IRF9')
# statistical tests
rse_psc_test <- sapply(unique(repet_psc$ROI_label), function(x) 
                       rcomparison_sy(repet_psc[repet_psc$ROI_label == x,], 'PSC', 'condition', conditions, 'participant_id'),
                       simplify = FALSE, USE.NAMES = TRUE)
rse_fir_test <- list()
for (ifir in FIRs){
  rse_fir_test[ifir][[1]] <- sapply(unique(repet_psc$ROI_label), function(x) 
                                    rcomparison_sy(repet_psc[repet_psc$ROI_label == x,], ifir, 'condition', conditions, 'participant_id', direc = 'less'),
                                    simplify = FALSE, USE.NAMES = TRUE)
}  

# PLOT PSC
for (iroi in unique(repet_psc$ROI_label)){
  # extract data for this ROI
  repet_psc_iroi <- repet_psc[repet_psc$ROI_label == iroi & repet_psc$condition %in% conditions,]
  # determine Y range
  p_rse_iroi_y <- round(c(min(repet_psc_iroi$PSC), max(repet_psc_iroi$PSC)), digits = 1) + c(-0.1, 0.2)
  # extract significance
  rse_test_iroi <- rse_psc_test[iroi][[1]]$PSC_PT
  rse_test_iroi <- rse_test_iroi[rse_test_iroi$Comparison %in% conditions_tests,]
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
  p_rse_iroi <- rplot_box2(repet_psc_iroi$PSC, repet_psc_iroi$condition, title = iroi,
                           bColor = conditions_color, fColor = conditions_color, gOrder = conditions, gLabel = conditions, 
                           aLabel = c('', 'Percent Signal Change'), Xangle = 90, Yrange = p_rse_iroi_y, sBars = p_rse_iroi_sig)
  # output figure
  fplot <- file.path(tdir, sprintf('group_task-AudioVisAssos2word_Repetition-PSC_ROI-%s_v1.0.png', iroi))
  save_plot(filename = fplot, p_rse_iroi, base_height = 6, base_asp = 0.6)
}
# PLOT FIR
for (iroi in unique(repet_psc$ROI_label)){
  # extract data for this ROI
  repet_fir_iroi <- repet_psc[repet_psc$ROI_label == iroi & repet_psc$condition %in% conditions,]
  repet_fir_iroi <- describeBy(repet_fir_iroi[,FIRs], group = repet_fir_iroi$condition)
  rse_fir_test_iroi <- lapply(rse_fir_test, function(x) x[iroi][[1]][2][[1]])
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
    p_rse_fir <- rplot_line(rse_fir_iroi$vars, rse_fir_iroi$mean, errs = rse_fir_iroi$se, group = rse_fir_iroi$condition,
                            pTitle = iroi, lColor = c('black', 'darkgray'), aLabel = c('Seconds', 'Percent Signal Change'), sLabel = p_rse_fir_sig)
    # output figure
    fplot <- file.path(tdir, 'FIR', sprintf('group_Repetition-FIR_ROI-%s_%s-%s-%s_v1.0.png', iroi, icond[1], icond[2], p_rse_fir_suf))
    save_plot(filename = fplot, p_rse_fir, base_height = 5, base_asp = 1)
  }
}
## ---------------------------
