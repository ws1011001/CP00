## ---------------------------
## [script name] ps18_MVPA_AudioVisAssos1word_ROI_classification_nilearn.py
##
## SCRIPT to do uni-modal and cross-modal classifications with linear-SVM on several ROIs for the AudioVisAssos1word task.
##
## By Shuai Wang, [date] 2021-06-23
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
import itertools  # to create combinations for Leave-N-Runs-Out-CV for cross-modal decoding
from datetime import datetime
from nilearn.image import load_img, index_img, mean_img, new_img_like
from nilearn.input_data import NiftiMasker
from sklearn import svm
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.naive_bayes import GaussianNB
from sklearn.model_selection import LeaveOneGroupOut, LeavePGroupsOut, PredefinedSplit, permutation_test_score
from sklearn.pipeline import Pipeline
from sklearn.feature_selection import SelectKBest, f_classif
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
np.random.seed(21)  # random seed for sklearn
task = 'task-AudioVisAssos1word'    # task name
spac = 'space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep 
mods = ['visual', 'auditory']       # stimulus modalities
## ---------------------------

## MVPA parameters
# prepare classifiers without tuning parameters - only use linear-SVM
clf_models = [LinearDiscriminantAnalysis(),
              GaussianNB(),
              svm.SVC(kernel = 'linear', max_iter = -1),
              svm.SVC(max_iter = -1)]
clf_tokens = ['LDA', 'GNB', 'SVClin', 'SVCrbf']  # classifier abbreviations
nmodels    = len(clf_tokens)
# ROI-based parameters
fs_perc = [57, 93, 171, 389]               # feature selection K best: [57, 93, 171, 389, 751] = radius 4, 5, 6, 8, 10 mm
nperm   = 1                              # number of permutations
pperm   = 0.05                             # the threshold p-value 
C       = np.int(pperm * (nperm + 1) - 1)  # C is the number of permutations whose score >= the true score given the threshold p-value
njobs   = -1                               # -1 means all CPUs
CV_type = 'LNROCV'                         # LOROCV; LNROCV
CV_N    = 2                                # number of runs to be leaved out
st_type = 'spatial'               # standardization method: none; spatial; temporal (default); spatial-temporal
# read ROIs information
froi = os.path.join(vdir, 'group_masks_labels-ROI.csv')  # ROIs info
rois = pd.read_csv(froi).set_index('label')              # the list of ROIs
rois = rois[rois.input == 1]                             # only inculde new ROIs
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
# initialize performance tables
facc = os.path.join(vdir, "group_%s_MVPA-ST1-PermACC_unimodal+crossmodal_%s.csv" % (task, CV_type))  # performance table
dacc = pd.DataFrame(columns = ['participant_id', 'modality', 'ROI_label', 'classifier', 'nvox', 'ACC', 'CPermACC', 'Pval', 'CPval'])
# define cross-validation
if CV_type == 'LOROCV':
  CV = LeaveOneGroupOut()  # leave-one-run-out cross-validation
else:
  CV = LeavePGroupsOut(n_groups=CV_N)                           # leave-N-runs-out cross-validation
  runs = [list(r) for r in itertools.combinations(runs, CV_N)]  # all combinations of N runs
nrun = len(runs)  # number of FOLDs 
# do MVPA for each subject
for i in range(n):
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
    betas = index_img(fbet, labs_mod)   # select betas with this modality
    labs_crs = np.zeros(len(labs_run))  # initialize labels for PredefinedSplit() in which 0 is for test while -1 is for training
    labs_crs[labs_mod] = -1             # this modality is for training
    # do MVPA with each ROI
    for iroi in range(nroi):
      thisroi = rois.index[iroi]
      # load up group/individual mask
      if thisroi[0] == 'i':
        fbox = os.path.join(kdir, subj, "%s_%s_mask-%s.nii.gz" % (subj, spac, thisroi))  # individual mask
      else:
        fbox = os.path.join(kdir, 'group', "group_%s_mask-%s.nii.gz" % (spac, thisroi))
      mbox = load_img(fbox)
      nvox = np.sum(mbox.get_data())
      # data standardization
      masker_box = NiftiMasker(mask_img = mbox, standardize = False, detrend = False)  # mask transformer; no standardize for searchlight
      betas_box = masker_box.fit_transform(betas)                                      # masked betas
      if st_type == 'spatial':
        print(f'Do spatial standardization for {thisroi}. ')
        betas_box = (betas_box - betas_box.mean(axis=1).reshape(-1, 1)) / betas_box.std(axis=1).reshape(-1, 1)  # spatial
      elif st_type == 'temporal':
        print(f'Do temporal standardization for {thisroi}. ')
        betas_box = (betas_box - betas_box.mean(axis=0).reshape(1, -1)) / betas_box.std(axis=0).reshape(1, -1)  # temporal
      elif st_type == 'spatial-temporal':
        print(f'Do spatial and temporal standardization sequentially for {thisroi}. ')
        betas_box = (betas_box - betas_box.mean(axis=1).reshape(-1, 1)) / betas_box.std(axis=1).reshape(-1, 1)  # spatial
        betas_box = (betas_box - betas_box.mean(axis=0).reshape(1, -1)) / betas_box.std(axis=0).reshape(1, -1)  # temporal
      else:
        print('No standardization for {thisroi}. ')
      # do MVPA with each classifier
      for clf_token, clf_model in zip(clf_tokens, clf_models):
        # permutation MVPA
        if rois.fixed[iroi]:
          # uni-modal MVPA
          acc, perm, pval = permutation_test_score(clf_model, betas_box, labs_lex[labs_mod], cv=CV, scoring='accuracy',
                                                   n_permutations = nperm, groups = labs_run[labs_mod], n_jobs=-1, random_state=21)
          # cross-modal MVPA
          perm_crs = np.array([])         # initialize permutation scores array
          acc_crs  = np.zeros((nrun, 3))  # initialize performance array for cross-modal decoding
          for j in range(nrun):
            thisrun = runs[j]
            if type(thisrun) != list: thisrun = [thisrun]  # make sure it is a list
            # select labels for cross-modal decoding CV
            labs_train = ~labs_run.isin(thisrun) & labs_mod     # train set of other 4 runs with this modality
            labs_test = labs_run.isin(thisrun) & ~labs_mod      # test set of this run with another modality
            labs_thisrun = labs_train | labs_test                 # selected labels
            CV_thisrun = PredefinedSplit(labs_crs[labs_thisrun])  # pre-defined CV
            # prepare betas and data stanardization
            betas_thisrun = index_img(fbet, labs_thisrun)                # selected betas
            betas_thisrun_box = masker_box.fit_transform(betas_thisrun)  # masked betas
            if st_type == 'spatial':
              print(f'Do spatial standardization for {thisroi}. ')
              betas_box = (betas_box - betas_box.mean(axis=1).reshape(-1, 1)) / betas_box.std(axis=1).reshape(-1, 1)  # spatial
            elif st_type == 'temporal':
              print(f'Do temporal standardization for {thisroi}. ')
              betas_thisrun_box = (betas_thisrun_box - betas_thisrun_box.mean(axis=0).reshape(1, -1)) / betas_thisrun_box.std(axis=0).reshape(1, -1)  # temporal
            elif st_type == 'spatial-temporal':
              print(f'Do spatial and temporal standardization sequentially for {thisroi}. ')
              betas_thisrun_box = (betas_thisrun_box - betas_thisrun_box.mean(axis=1).reshape(-1, 1)) / betas_thisrun_box.std(axis=1).reshape(-1, 1)  # spatial
              betas_thisrun_box = (betas_thisrun_box - betas_thisrun_box.mean(axis=0).reshape(1, -1)) / betas_thisrun_box.std(axis=0).reshape(1, -1)  # temporal
            else:
              print(f'No standardization for {thisroi}. ')
            # carry out MVPA for this run
            jacc, jperm, jpval = permutation_test_score(clf_model, betas_thisrun_box, labs_lex[labs_thisrun], cv=CV_thisrun, scoring='accuracy',
                                                        n_permutations = nperm, groups = labs_run[labs_thisrun], n_jobs=-1, random_state=21)
            perm_crs = np.append(perm_crs, jperm)
            acc_crs[j, 0] = jacc                 # ACC of this run
            acc_crs[j, 1] = -np.sort(-jperm)[C]  # permutation ACC at C of this run
            acc_crs[j, 2] = jpval                # p-value of this run
          acc_crs = np.mean(acc_crs, axis=0)  # averaged performance
          # output ACC and perm scores
          dacc.loc[len(dacc)] = [subj, imod, thisroi, clf_token, nvox, acc, -np.sort(-perm)[C], pval, pperm]
          dacc.loc[len(dacc)] = [subj, "%s2" % imod, thisroi, clf_token, nvox, acc_crs[0], acc_crs[1], acc_crs[2], pperm]
          funip = os.path.join(pdir, "%s_tvrMVPC-%s-Perm%d_LOROCV_ACC-%s_mask-%s.1D" % (subj, clf_token, nperm, imod, thisroi))
          fcrsp = os.path.join(pdir, "%s_tvrMVPC-%s-Perm%d_LOROCV_ACC-%s2_mask-%s.1D" % (subj, clf_token, nperm, imod, thisroi))
          perm.tofile(file = funip, sep = '\n')
          perm_crs.tofile(file = fcrsp, sep = '\n')
        else:
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
              if type(thisrun) != list: thisrun = [thisrun]  # make sure it is a list
              # select labels for cross-modal decoding CV
              labs_train = ~labs_run.isin(thisrun) & labs_mod     # train set of other 4 runs with this modality
              labs_test = labs_run.isin(thisrun) & ~labs_mod      # test set of this run with another modality
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

now = datetime.now()
print("========== ALL DONE : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))
