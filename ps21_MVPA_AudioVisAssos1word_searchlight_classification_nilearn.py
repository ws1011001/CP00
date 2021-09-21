## ---------------------------
## [script name] ps21_MVPA_AudioVisAssos1word_searchlight_classification_nilearn.py
##
## SCRIPT to do uni-modal and cross-modal classifications with searchlight for the AudioVisAssos1word task.
##
## By Shuai Wang, [date] 2021-08-23
##
## ---------------------------
## Notes: - do not tune parmeters, instead use L2 linear-SVM as a reference (Varoquaux et al., 2017)
##   
##
## ---------------------------

## set environment (packages, functions, working path etc.)
# load up packages
import os
import nilearn.decoding
import pandas as pd
import numpy as np
from datetime import datetime
from nilearn.image import load_img, index_img, mean_img, new_img_like
from sklearn import svm
from sklearn.model_selection import LeaveOneGroupOut, PredefinedSplit
# setup path
mdir = '/scratch/swang/agora/CP00/AudioVisAsso'   # the project main folder
ddir = os.path.join(mdir, 'derivatives')          # different analyses after pre-processing
vdir = os.path.join(ddir, 'multivariate')         # multivariate analyses folder
kdir = os.path.join(ddir, 'masks')                # masks folder
# read subjects information
fsub = os.path.join(vdir, 'participants_final.tsv')          # subjects info
subjects = pd.read_table(fsub).set_index('participant_id')   # the list of subjects
n = len(subjects)
# experiment parameters
task = 'task-AudioVisAssos1word'    # task name
spac = 'space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep 
mods = ['visual', 'auditory']       # stimulus modalities
## ---------------------------

## MVPA parameters
# prepare classifiers without tuning parameters - only use linear-SVM
clf_models = [svm.SVC(kernel = 'linear', max_iter = -1)]
clf_tokens = ['SVClin']  # classifier abbreviations
nmodels = len(clf_tokens)
# searchlight parameters
radius = 4   # searchlight kernel size (57 voxels)
njobs  = -1  # -1 means all CPUs
# read searchlight masks
froi = os.path.join(vdir, 'group_masks_labels-searchlight.csv')  # masks info
rois = pd.read_csv(froi).set_index('label')                      # the list of masks
rois = rois[rois.input == 1]                                     # only inculde new ROIs
nroi = len(rois)
## ---------------------------

now = datetime.now()
print("========== START JOB : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))

## MVPA
# read trial labels
flab = os.path.join(vdir, "group_%s_labels-trial.csv" % task)  # trial-wise labels
labels = pd.read_csv(flab)       # trial labels
labs_trl = labels['conditions']  # WA, WV, PA, PV
labs_lex = labels['lexicon']     # word, pseudoword
labs_run = labels['runs']        # 5 runs, from run1 to run5
runs = np.unique(labs_run)       # run labels
nrun = len(runs)                 # number of runs 
# do MVPA for each subject
CV = LeaveOneGroupOut()  # leave-one-run-out cross-validation
for i in range(0, n):
  subj = subjects.index[i]
  print("Perform searchlight MVPA using classifiers: %s with LOROCV for subject: %s ......\n" % (clf_tokens, subj))
  # setup individual  path
  sdir = os.path.join(vdir, subj)          # subject working folder 
  bdir = os.path.join(sdir, 'betas_afni')  # beta estimates
  pdir = os.path.join(sdir, 'tvsMVPC')     # Trial-wise Volume ROI-based MVPC
  if not os.path.exists(pdir): os.makedirs(pdir)
  fbet = "%s/%s_LSS_nilearn.nii.gz" % (bdir,subj)
  for imod in mods:
    # read labels and betas according to the modality
    labs_mod = labs_trl.isin(['WV','PV']) if imod == 'visual' else labs_trl.isin(['WA','PA'])
    betas = index_img(fbet, labs_mod)   # select betas with this modality
    betas_mean = mean_img(betas)        # as a template to output results 
    labs_crs = np.zeros(len(labs_run))  # initialize labels for PredefinedSplit() in which 0 is for test while -1 is for training
    labs_crs[labs_mod] = -1             # this modality is for training
    # do MVPA with each ROI
    for iroi in range(0, nroi):
      thisroi = rois.index[iroi]
      # load up group/individual mask
      if thisroi[0] == 'i':
        fbox = os.path.join(kdir, subj, "%s_%s_mask-%s.nii.gz" % (subj, spac, thisroi))  # individual mask
      else:
        fbox = os.path.join(kdir, 'group', "group_%s_mask-%s.nii.gz" % (spac, thisroi))
      mbox = load_img(fbox)
      # do MVPA with each classifier
      for clf_token, clf_model in zip(clf_tokens, clf_models):
        # searchlight MVPA
        if rois.fixed[iroi]:
          # uni-modal MVPA
          fout = os.path.join(pdir, "%s_tvsMVPC-%s_LOROCV_ACC-%s_mask-%s.nii.gz" % (subj, clf_token, imod, thisroi))
          searchlight_uni = nilearn.decoding.SearchLight(mask_img = mbox, radius = radius, estimator = clf_model,
                                                         n_jobs = njobs, cv = CV)
          searchlight_uni.fit(betas, labs_lex[labs_mod], groups = labs_run[labs_mod])
          searchlight_uni_map = new_img_like(betas_mean, searchlight_uni.scores_)
          searchlight_uni_map.to_filename(fout)
          # cross-modal MVPA
          for j in range(0, nrun):
            thisrun = runs[j]
            # select labels for cross-modal decoding CV
            labs_train = ~labs_run.isin([thisrun]) & labs_mod     # train set of other 4 runs with this modality
            labs_test = labs_run.isin([thisrun]) & ~labs_mod      # test set of this run with another modality
            labs_thisrun = labs_train | labs_test                 # selected labels
            CV_thisrun = PredefinedSplit(labs_crs[labs_thisrun])  # pre-defined CV
            # prepare betas
            betas_thisrun = index_img(fbet, labs_thisrun)                # selected betas
            # carry out MVPA with this run as a test set
            fout = os.path.join(pdir, "%s_tvsMVPC-%s_LOROCV-run%02d_ACC-%s2_mask-%s.nii.gz" % (subj, clf_token, j+1, imod, thisroi))
            searchlight_crs = nilearn.decoding.SearchLight(mask_img = mbox, radius = radius, estimator = clf_model,
                                                           n_jobs = njobs, cv = CV_thisrun)
            searchlight_crs.fit(betas_thisrun, labs_lex[labs_thisrun], groups = labs_run[labs_thisrun])
            searchlight_crs_map = new_img_like(betas_mean, searchlight_crs.scores_)
            searchlight_crs_map.to_filename(fout)           

  print("Finish searchlight MVPA for subject: %s.\n" % subj) 
## ---------------------------

now = datetime.now()
print("========== ALL DONE : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))
