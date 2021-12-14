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
library(rmatio)
library(reshape2)
library(ggplot2)
library(cowplot)
library(plot3D)
library(EnvStats)  # oneSamplePermutationTest()
source('~/Projects/nitools/rcomparison.R')
source('~/Projects/nitools/rplot.R')
# setup working paths
mdir <- '/media/wang/BON/Projects/CP00'
wdir <- file.path(mdir, 'AudioVisAsso')
ddir <- file.path(wdir, 'derivatives')
rdir <- file.path(wdir, 'results')
vdir <- file.path(rdir, 'multivariate')
pdir <- file.path(mdir, 'manuscript', 'report')
# setup MVPA parameters
classifiers <- c('LDA', 'GNB', 'SVClin', 'SVCrbf')
colors_clfs <- c('gray40', 'gray50', 'gray60', 'gray70')
modalities  <- c('visual', 'auditory', 'visual2', 'auditory2')
colors_mods <- c('gold3', 'gold', 'seagreen4', 'seagreen1')
# define data files
flocav <- file.path(rdir, 'task-LocaVis1p75', 'ROIs_left-vOT_task-LocaVis1p75.csv')
fmvpac <- file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-Perm10000_classifier-selection_unimodal+crossmodal.csv') 
fmvpar <- file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-PermACC_unimodal+crossmodal.csv')
# read data
locav_xyz <- read.csv(file = flocav, stringsAsFactors = FALSE)
mvpac_acc <- read.csv(file = fmvpac, stringsAsFactors = FALSE)
mvpar_acc <- read.csv(file = fmvpar, stringsAsFactors = FALSE)
## ---------------------------


## Visual localizer
png(filename = file.path(pdir, 'group_localizer-visual_individual-peaks.png'), width = 8, height = 6, unit = 'in', res = 300)
  scatter3D(locav_xyz$x, locav_xyz$y, locav_xyz$z, colvar = locav_xyz$T, pch = 20, cex = 3, main = 'Individual Peak Coordinates (N = 22)', bty = 'g',
            xlab = 'X', ylab = 'Y', zlab = 'Z', ticktype = 'detailed', clab = 'T value', clim = c(2, 7), col = ramp.col (col = c('yellow', 'red')))
dev.off()
## ---------------------------

## ROI-based MVPA
# classifiers comparison
rcomparison_sy(mvpac_acc[mvpac_acc$modality == 'auditory2',], 'ACC', 'classifier', classifiers, 'participant_id')
# visualization - classifiers comparison
mvpac_acc_ps <- lapply(unique(mvpac_acc$modality), function(x)
                       rplot_box2(gdata = mvpac_acc[mvpac_acc$modality == x, 'ACC'], groups = mvpac_acc$classifier[mvpac_acc$modality == x],
                                  gOrder = c('LDA', 'SVClin', 'GNB', 'SVCrbf'), gLabel = c('LDA', 'SVM-lin', 'GNB', 'SVM-RBF'), aLabel = c(x, 'ACC'), 
                                  fColor = colors_clfs, Xangle = 90) + ylim(c(0.3, 0.7)) + geom_hline(yintercept = 0.5, linetype = 'dashed'))
mvpac_acc_p <- plot_grid(plotlist = mvpac_acc_ps, align = 'h', nrow = 1)
save_plot(filename = file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-ACC_classifiers_unimodal+crossmodal.png'), mvpac_acc_p, base_height = 8, base_asp = 1)
# ROIs comparison
mvpar_acc_svclin <- mvpar_acc[mvpar_acc$classifier == 'SVClin',]
mvpar_acc_rois <- c('lvOT-1', 'lvOT-2', 'lvOT-3', 'lvOT-4', 'lvOT-sph4mm', 'lvOT-sph5mm', 'lvOT-sph6mm', 
                    'ilvOT', 'ilvOT-sph4mm', 'ilvOT-sph5mm', 'ilvOT-sph6mm', 
                    'lvOT-visual', 'lvOT-visualonly', 'lvOT-auditory', 'lvOT-auditoryonly', 'lvOT-both', 
                    'lSTG-auditory', 'rSTG-auditory')
mvpar_acc_test1 <- sapply(mvpar_acc_rois, function(x) 
                          rcomparison_p1(mvpar_acc_svclin[mvpar_acc_svclin$ROI_label == x,], 'modality', 'ACC', 0.5, 'greater', 10000),
                          simplify = FALSE, USE.NAMES = TRUE)
mvpar_acc_test2 <- sapply(mvpar_acc_rois, function(x) 
                          rcomparison_sy(mvpar_acc_svclin[mvpar_acc_svclin$ROI_label == x,], 'ACC', 'modality', modalities, 'participant_id'),
                          simplify = FALSE, USE.NAMES = TRUE)
# visualization - all ROIs comparison
mvpar_acc_ps <- lapply(mvpar_acc_rois, function(x)
                       rplot_box2(gdata = mvpar_acc_svclin[mvpar_acc_svclin$ROI_label == x, 'ACC'], 
                                  groups = mvpar_acc_svclin$modality[mvpar_acc_svclin$ROI_label == x],
                                  gOrder = c('visual', 'auditory', 'visual2', 'auditory2'), gLabel = c('Vis.', 'Aud.', 'Vis-Aud', 'Aud-Vis'),
                                  aLabel = c(x, 'ACC'), fColor = c('gray40', 'gray50', 'gray60', 'gray70'), Xangle = 90)
                       + ylim(c(0.3, 0.7)) + geom_hline(yintercept = 0.5, linetype = 'dashed'))
mvpar_acc_p <- plot_grid(plotlist = mvpar_acc_ps, nrow = 3, ncol = 6)
save_plot(filename = file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-PermACC_unimodal+crossmodal.png'), mvpar_acc_p, base_height = 12, base_asp = 0.8)
# visualization - ilvOT and ilvOT-sph4mm
mvpar_acc_roi_idx <- mvpar_acc_svclin$ROI_label == 'ilvOT'
mvpar_acc_s_ilvot <- data.frame(sleft = c(3), sright = c(3), slabs = c('*'), spos = c(0.68, 0.68),
                                labsize = 5, vjust = 1, stringsAsFactors = FALSE)
mvpar_acc_p_ilvot <- rplot_box2(mvpar_acc_svclin$ACC[mvpar_acc_roi_idx], mvpar_acc_svclin$modality[mvpar_acc_roi_idx],
                                bColor = colors_mods, fColor = colors_mods, gOrder = modalities, gLabel = modalities, aLabel = c('ivLVOT', 'ACC'), 
                                Yrange = c(0.3, 0.7), Xangle = 90, sBars = mvpar_acc_s_ilvot) + geom_hline(yintercept = 0.5, linetype = 'dashed')
mvpar_acc_s_ilvot4 <- data.frame(sleft = c(1, 3, 4), sright = c(1, 3, 4), slabs = c('**','**', '*'), spos = c(0.68, 0.68, 0.68),
                                 labsize = 5, vjust = 1, stringsAsFactors = FALSE)
mvpar_acc_roi_idx <- mvpar_acc_svclin$ROI_label == 'ilvOT-sph4mm'
mvpar_acc_p_ilvot4 <- rplot_box2(mvpar_acc_svclin$ACC[mvpar_acc_roi_idx], mvpar_acc_svclin$modality[mvpar_acc_roi_idx],
                                 bColor = colors_mods, fColor = colors_mods, gOrder = modalities, gLabel = modalities, aLabel = c('ivLVOT (4mm)', 'ACC'), 
                                 Yrange = c(0.3, 0.7), Xangle = 90, sBars = mvpar_acc_s_ilvot4) + geom_hline(yintercept = 0.5, linetype = 'dashed')
mvpar_acc_p_ilvots <- plot_grid(plotlist = list(mvpar_acc_p_ilvot, mvpar_acc_p_ilvot4), nrow = 1, ncol = 2)
save_plot(filename = file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-PermACC_ilvOT.png'), mvpar_acc_p_ilvots, base_height = 5, base_asp = 1.2)
# visualization - visual and auditory lvOT
mvpar_acc_roi_idx <- mvpar_acc_svclin$ROI_label == 'lvOT-visual'
mvpar_acc_s_vlvot <- data.frame(sleft = c(1, 3), sright = c(1, 3), slabs = c('***', '*'), spos = c(0.68, 0.68),
                                labsize = 5, vjust = 1, stringsAsFactors = FALSE)
mvpar_acc_p_vlvot <- rplot_box2(mvpar_acc_svclin$ACC[mvpar_acc_roi_idx], mvpar_acc_svclin$modality[mvpar_acc_roi_idx],
                                bColor = colors_mods, fColor = colors_mods, gOrder = modalities, gLabel = modalities, aLabel = c('gvLVOT', 'ACC'), 
                                Yrange = c(0.3, 0.7), Xangle = 90, sBars = mvpar_acc_s_vlvot) + geom_hline(yintercept = 0.5, linetype = 'dashed')
mvpar_acc_s_alvot <- data.frame(sleft = c(1, 2, 3, 4), sright = c(1, 2, 3, 4), slabs = c('**','***', '*', '**'), spos = rep(0.35, 4),
                                 labsize = 5, vjust = 1, stringsAsFactors = FALSE)
mvpar_acc_roi_idx <- mvpar_acc_svclin$ROI_label == 'lvOT-auditory'
mvpar_acc_p_alvot <- rplot_box2(mvpar_acc_svclin$ACC[mvpar_acc_roi_idx], mvpar_acc_svclin$modality[mvpar_acc_roi_idx],
                                 bColor = colors_mods, fColor = colors_mods, gOrder = modalities, gLabel = modalities, aLabel = c('gaLVOT', 'ACC'), 
                                 Yrange = c(0.3, 0.7), Xangle = 90, sBars = mvpar_acc_s_alvot) + geom_hline(yintercept = 0.5, linetype = 'dashed')
mvpar_acc_p_glvots <- plot_grid(plotlist = list(mvpar_acc_p_vlvot, mvpar_acc_p_alvot), nrow = 1, ncol = 2)
save_plot(filename = file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-PermACC_glvOT.png'), mvpar_acc_p_glvots, base_height = 5, base_asp = 1.2)
# visualization - left- and right-STG
mvpar_acc_roi_idx <- mvpar_acc_svclin$ROI_label == 'lSTG-auditory'
mvpar_acc_s_lstg <- data.frame(sleft = c(2), sright = c(2), slabs = c('**'), spos = c(0.68),
                                labsize = 5, vjust = 1, stringsAsFactors = FALSE)
mvpar_acc_p_lstg <- rplot_box2(mvpar_acc_svclin$ACC[mvpar_acc_roi_idx], mvpar_acc_svclin$modality[mvpar_acc_roi_idx],
                                bColor = colors_mods, fColor = colors_mods, gOrder = modalities, gLabel = modalities, aLabel = c('gaLSTG', 'ACC'), 
                                Yrange = c(0.3, 0.7), Xangle = 90, sBars = mvpar_acc_s_lstg) + geom_hline(yintercept = 0.5, linetype = 'dashed')
mvpar_acc_roi_idx <- mvpar_acc_svclin$ROI_label == 'rSTG-auditory'
mvpar_acc_s_rstg <- data.frame(sleft = c(3, 4), sright = c(3, 4), slabs = c('**', '**'), spos = rep(0.68, 2),
                                labsize = 5, vjust = 1, stringsAsFactors = FALSE)
mvpar_acc_p_rstg <- rplot_box2(mvpar_acc_svclin$ACC[mvpar_acc_roi_idx], mvpar_acc_svclin$modality[mvpar_acc_roi_idx],
                                bColor = colors_mods, fColor = colors_mods, gOrder = modalities, gLabel = modalities, aLabel = c('gaRSTG', 'ACC'), 
                                Yrange = c(0.3, 0.7), Xangle = 90, sBars = mvpar_acc_s_rstg) + geom_hline(yintercept = 0.5, linetype = 'dashed')
mvpar_acc_p_glvots <- plot_grid(plotlist = list(mvpar_acc_p_lstg, mvpar_acc_p_rstg), nrow = 1, ncol = 2)
save_plot(filename = file.path(vdir, 'group_task-AudioVisAssos1word_MVPA-PermACC_gSTG.png'), mvpar_acc_p_glvots, base_height = 5, base_asp = 1.2)
## ---------------------------

## ROI-based RSA
d <- read.mat('test.mat')
data <- as.matrix(d$RDMsCorr$Z[[1]])
dnames <- d$RDMsCorr$M$name
colnames(data) <- dnames
rownames(data) <- dnames
data_m <- melt(data)
p <- ggplot(data = data_m, aes(x=Var1,y=Var2,fill=value))+geom_tile()
## ---------------------------
