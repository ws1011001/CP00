## ---------------------------
## [script name] ps17_MVPA_classifier_selection__nilearn.py
##
## SCRIPT to do classifier selection with the box ROI of VWFA on trials within its modality, i.e. visual trials and 
##              auditory trials. In this case, the cross-validation is leave-one-run-out.
##
## By Shuai Wang, [date] 2021-03-02
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
from nilearn.input_data import NiftiMasker
from sklearn import svm
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.naive_bayes import GaussianNB
from sklearn.model_selection import LeaveOneGroupOut
from sklearn.model_selection import permutation_test_score
from sklearn.pipeline import Pipeline
from sklearn.feature_selection import SelectPercentile, f_classif
# setup path
mdir = '/scratch/swang/agora/CP00/AudioVisAsso'  # the project main folder
ddir = os.path.join(mdir,'derivatives')          # different analyses after pre-processing
vdir = os.path.join(ddir,'multivariate')         # multivariate analyses folder
kdir = os.path.join(ddir,'masks')                # masks folder
# read subjects information
fsub = os.path.join(vdir,'participants_final.tsv')          # subjects info
subjects = pd.read_table(fsub).set_index('participant_id')  # the list of subjects
n = len(subjects)
# experiment parameters
task = 'task-AudioVisAssos1word'    # task name
spac = 'space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep 
mods = ['visual', 'auditory']       # stimulus modalities
## ---------------------------

## MVPA parameters
# prepare classifiers without tuning parameters
clf_models = [LinearDiscriminantAnalysis(),
              GaussianNB(),
              svm.SVC(kernel='linear',max_iter=-1),
              svm.SVC(max_iter=-1)]
clf_tokens = ['LDA','GNB','SVClin','SVCrbf']  # classifier abbreviations
nmodels = len(clf_tokens)
# ROI-based parameters
fs_perc = [1, 2, 5]  # feature selection percentile
nperm = 1000         # number of permutations
njobs = -1           # -1 means all CPUs
## ---------------------------

now = datetime.now()
print("========== START JOB : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))

## MVPA
# read trial labels
flab = os.path.join(vdir, "group_trial-labels_%s_within-modality.csv" % task)  # trial-wise labels
labels = pd.read_csv(flab)             # trial labels
labs_trl = labels['conditions']        # WA, WV, PA, PV
labs_lex = labels['lexicon']           # word, pseudoword
labs_run = labels['runs']              # 5 runs, from run-01 to run-05
# load up group mask (left-vOT box without CBL)
fbox = os.path.join(kdir, 'group', "group_%s_mask-lVOT-woCBL_res-%s.nii.gz" % (spac, task))
mbox = load_img(fbox)
masker_box = NiftiMasker(mask_img = mbox, standardize = True, detrend = False)  # mask transformer of left-vOT (3486 voxels)
# initialize performance tables
acc_scores = ["participant_id", "modality"]
for c in clf_tokens:
  for s in fs_perc:
    acc_scores.extend(["ACC_%s_perc%s" % (c, s), "Perm_%s_perc%s" % (c, s), "P_%s_perc%s" % (c, s)])
facc = os.path.join(vdir, "group_MVPA-ACC-scores_%s_within-modality.csv" % task)
with open(facc, 'w') as fid: fid.write(','.join(acc_scores) + '\n')
fid.close()
# do MVPA for each subject
CV = LeaveOneGroupOut()  # leave-one-run-out cross-validation
for i in range(0, n):
  subj = subjects.index[i]
  print("Perform ROI-based MVPA using classifiers: %s with LOROCV for subject: %s ......\n" % (clf_tokens, subj))
  # setup individual  path
  sdir = os.path.join(vdir, subj)          # subject working folder 
  bdir = os.path.join(sdir, 'betas_afni')  # beta estimates
  pdir = os.path.join(sdir, 'tvrMVPC')     # Trial-wise Volume ROI-based MVPC
  if not os.path.exists(pdir): os.makedirs(pdir)
  fbet = "%s/%s_LSS_nilearn.nii.gz" % (bdir,subj)
  for imod in mods:
    # read labels and betas according to the modality
    labs_mod = labs_trl.isin(['WV','PV']) if imod == 'visual' else labs_trl.isin(['WA','PA'])
    betas = index_img(fbet, labs_mod)
    betas_box = masker_box.fit_transform(betas)  # left-vOT box masked
    # do MVPA with each classifier
    acc_scores = [subj, imod]
    for clf_token, clf_model in zip(clf_tokens, clf_models):
      for iperc in fs_perc:
        feature_selected = SelectPercentile(f_classif, percentile = iperc)  # feature selection
        clf_fs = Pipeline([('anova', feature_selected), ('classifier', clf_model)])
        acc, perm, pval = permutation_test_score(clf_fs, betas_box, labs_lex[labs_mod], cv=CV, scoring='accuracy',
                                                 n_permutations = nperm, groups = labs_runs[labs_mod], n_jobs=-1)
        acc_scores.extend(["%f" % acc, "%f" % np.mean(perm), "%f" % pval])
    # output performance data
    with open(facc, 'a') as fid: fid.write(','.join(acc_scores) + '\n')
    fid.close()
  print("Finish ROI-based MVPA for subject: %s.\n" % subj) 
## ---------------------------

now=datetime.now()
print("========== ALL DONE : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))
