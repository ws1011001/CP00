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
from sklearn.feature_selection import SelectKBest, f_classif
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
              svm.SVC(kernel='linear', max_iter = -1),
              svm.SVC(max_iter = -1)]
clf_tokens = ['LDA', 'GNB', 'SVClin', 'SVCrbf']  # classifier abbreviations
nmodels = len(clf_tokens)
# ROI-based parameters
fs_perc = [57]                             # feature selection K best: [57, 93, 171, 389, 751] = radius 4, 5, 6, 8, 10 mm
nperm   = 10000                            # number of permutations
pperm   = 0.01                             # the threshold p-value
C       = np.int(pperm * (nperm + 1) - 1)  # C is the number of permutations whose score >= the true score given the threshold p-value
njobs   = -1                               # -1 means all CPUs
## ---------------------------

now = datetime.now()
print("========== START JOB : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))

## MVPA
# read trial labels
flab = os.path.join(vdir, "group_%s_labels-trial.csv" % task)  # trial-wise labels
labels = pd.read_csv(flab)       # trial labels
labs_trl = labels['conditions']  # WA, WV, PA, PV
labs_lex = labels['lexicon']     # word, pseudoword
labs_run = labels['runs']        # 5 runs, from run-01 to run-05
runs = np.unique(labs_run)       # run labels
nrun = len(runs)                 # number of runs
# load up group mask (left-vOT box without CBL)
thisroi = 'lvOT-Bouhali2019-gGM'
fbox = os.path.join(kdir, 'group', "group_%s_mask-%s.nii.gz" % (spac, thisroi))  # group GM confined left-vOT box
mbox = load_img(fbox)
masker_box = NiftiMasker(mask_img = mbox, standardize = True, detrend = False)  # mask transformer of left-vOT (3486 voxels)
# initialize performance tables
facc = os.path.join(vdir, "group_%s_MVPA-Perm%d_classifier-selection_unimodal+crossmodal.csv" % (task, nperm))  # performance table
dacc = pd.DataFrame(columns = ['participant_id', 'modality', 'ROI_label', 'classifier', 'nvox', 'ACC', 'CPermACC', 'Pval', 'CPval'])
# do MVPA for each subject
CV = LeaveOneGroupOut()  # leave-one-run-out cross-validation
for i in range(0, n):
  subj = subjects.index[i]
  print("Perform ROI-based MVPA using classifiers: %s with LOROCV for subject: %s ......\n" % (clf_tokens, subj))
  # setup individual path
  sdir = os.path.join(vdir, subj)          # subject working folder 
  bdir = os.path.join(sdir, 'betas_afni')  # beta estimates
  pdir = os.path.join(sdir, 'tvrMVPC')     # Trial-wise Volume ROI-based MVPC
  if not os.path.exists(pdir): os.makedirs(pdir)
  fbet = "%s/%s_LSS_nilearn.nii.gz" % (bdir, subj)
  for imod in mods:
    # read labels and betas according to the modality
    labs_mod = labs_trl.isin(['WV','PV']) if imod == 'visual' else labs_trl.isin(['WA','PA'])
    labs_crs = np.zeros(len(labs_run))           # initialize labels for PredefinedSplit() in which 0 is for test while -1 is for training
    labs_crs[labs_mod] = -1                      # this modality is for training
    betas = index_img(fbet, labs_mod)            # select betas with this modality
    betas_box = masker_box.fit_transform(betas)  # left-vOT box masked
    # do MVPA with each classifier
    for clf_token, clf_model in zip(clf_tokens, clf_models):
      # select features if the ROI is too big (not fixed)
      for iperc in fs_perc:
        feature_selected = SelectKBest(f_classif, k = iperc)  # feature selection
        clf_fs = Pipeline([('anova', feature_selected), ('classifier', clf_model)])
        # uni-modal MVPA
        acc, perm, pval = permutation_test_score(clf_fs, betas_box, labs_lex[labs_mod], cv=CV, scoring='accuracy',
                                                 n_permutations = nperm, groups = labs_run[labs_mod], n_jobs=-1)
        # cross-modal MVPA
        perm_crs = np.array([])        # initialize permutation scores array
        acc_crs = np.zeros((nrun, 3))  # initialize performance array for cross-modal decoding
        for j in range(0, nrun):
          thisrun = runs[j]
          # select labels for cross-modal decoding CV
          labs_train = ~labs_run.isin([thisrun]) & labs_mod     # train set of other 4 runs with this modality
          labs_test = labs_run.isin([thisrun]) & ~labs_mod      # test set of this run with another modality
          labs_thisrun = labs_train | labs_test                 # selected labels
          CV_thisrun = PredefinedSplit(labs_crs[labs_thisrun])  # pre-defined CV
          # prepare betas
          betas_thisrun = index_img(fbet, labs_thisrun)                # selected betas
          betas_thisrun_box = masker_box.fit_transform(betas_thisrun)  # masked betas
          # carry out MVPA for this run
          jacc, jperm, jpval = permutation_test_score(clf_fs, betas_thisrun_box, labs_lex[labs_thisrun], cv=CV_thisrun, scoring='accuracy',
                                                      n_permutations = nperm, groups = labs_run[labs_thisrun], n_jobs=-1)
          perm_crs = np.append(perm_crs, jperm)
          acc_crs[j, 0] = jacc                 # ACC of this run
          acc_crs[j, 1] = -np.sort(-jperm)[C]  # permutation ACC at C of this run
          acc_crs[j, 2] = jpval                # p-value of this run
        acc_crs = np.mean(acc_crs, axis=0)  # averaged performance           
        # output ACC and perm scores
        dacc.loc[len(dacc)] = [subj, imod, thisroi, clf_token, iperc, acc, -np.sort(-perm)[C], pval, pperm]
        dacc.loc[len(dacc)] = [subj, "%s2" % imod, thisroi, clf_token, iperc, acc_crs[0], acc_crs[1], acc_crs[2], pperm]
        funip = os.path.join(pdir, "%s_tvrMVPC-%s-Perm%d_LOROCV_ACC-%s_mask-%s-k%03d.1D" % (subj, clf_token, nperm, imod, thisroi, iperc))
        fcrsp = os.path.join(pdir, "%s_tvrMVPC-%s-Perm%d_LOROCV_ACC-%s2_mask-%s-k%03d.1D" % (subj, clf_token, nperm, imod, thisroi, iperc))
        perm.tofile(file = funip, sep = '\n')
        perm_crs.tofile(file = fcrsp, sep = '\n')

  print("Finish ROI-based MVPA for subject: %s.\n" % subj) 
# output the performance table
dacc = dacc.set_index('participant_id')
dacc.to_csv(facc)
## ---------------------------

now=datetime.now()
print("========== ALL DONE : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))
