#!/usr/bin/env python
## ---------------------------
## [script name] ps30_gMVPA_classifier_selection_nilearn.py
## SCRIPT to do classifier selection with the box ROI of VWFA on trials within its modality (i.e. visual and auditory
##              trials) at the group level (group MVPA). In this case, the cross-validation is leave-one-sub-out.
##
## By Shuai Wang, [date] 2023-03-02
## ---------------------------
## Notes: - do not tune parmeters, instead use L2 linear-SVM as a reference (Varoquaux et al., 2017)
## ---------------------------


## Set environment (packages, functions, working path etc.)
# Load up packages
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
from sklearn.model_selection import LeaveOneGroupOut, PredefinedSplit, permutation_test_score
from sklearn.pipeline import Pipeline
from sklearn.feature_selection import SelectKBest, f_classif
# Setup path
dir_main = '/scratch/swang/agora/CP00/AudioVisAsso'  # the project main folder
dir_data = os.path.join(dir_main, 'derivatives')     # different analyses after pre-processing
dir_mvpa = os.path.join(dir_data, 'multivariate')    # multivariate analyses folder
dir_mask = os.path.join(dir_data, 'masks')           # masks folder
# Read subjects information
f_subjs = os.path.join(dir_mvpa, 'participants_final.tsv')     # subjects info
subjects = pd.read_table(f_subjs).set_index('participant_id')  # the list of subjects
n = len(subjects)
# Task parameters
task = 'task-AudioVisAssos1word'    # task name
spac = 'space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep 
mods = ['V', 'A']       # stimulus modalities
## ---------------------------


## MVPA parameters
# Prepare classifiers without tuning parameters
clf_models = [LinearDiscriminantAnalysis(),
              GaussianNB(),
              svm.SVC(kernel='linear', max_iter = -1),
              svm.SVC(max_iter = -1)]
clf_tokens = ['LDA', 'GNB', 'SVClin', 'SVCrbf']  # classifier abbreviations
nmodels = len(clf_tokens)
# ROI-based parameters
FS_PERCs = [171, 253, 389]                             # feature selection K best: [57, 93, 171, 253, 389, 751] = radius 4, 5, 6, 7, 8, 10 mm
N_PERM   = 1000                             # number of permutations
P_PERM   = 0.01                             # the threshold p-value
C        = np.int(P_PERM * (N_PERM + 1) - 1)  # C is the number of permutations whose score >= the true score given the threshold p-value
N_JOBs   = -1                               # -1 means all CPUs
## ---------------------------

now = datetime.now()
print("========== START JOB : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))

## MVPA
# Read trial labels
f_labels = os.path.join(dir_mvpa, "group_%s_labels-group-trial.tsv" % task)  # trial-wise labels
df_labels = pd.read_table(f_labels) # trial labels
# Load up group mask (left-vOT box without CBL)
thisroi = 'lvOT-Bouhali2019-gGM'
f_roi = os.path.join(dir_mask, 'group', "group_%s_mask-%s.nii.gz" % (spac, thisroi))  # group GM confined left-vOT box
img_roi = load_img(f_roi)
masker_box = NiftiMasker(mask_img=img_roi, standardize=True, detrend=False)  # mask transformer of left-vOT (3486 voxels)
# Initialize performance tables
f_acc = os.path.join(dir_mvpa, "group_%s_gMVPA-Perm%d_classifier-selection_unimodal+crossmodal.csv" % (task, N_PERM))  # performance table
df_acc = pd.DataFrame(columns = ['modality', 'ROI_label', 'classifier', 'nvox', 'ACC', 'CPermACC', 'Pval', 'CPval'])
# Do MVPA with leave-one-subject-out CV
CV = LeaveOneGroupOut()  # leave-one-subject-out cross-validation
f_betas = "%s/group_LSS_nilearn.nii.gz" % dir_mvpa
for imod in mods:
    # Read labels and betas according to the modality
    labels = df_labels['correct'] * (df_labels['modality'] == imod)
    groups = df_labels['participant_id'][labels].values
    targets = df_labels['lexicon'][labels].values   
    betas = index_img(f_betas, labels)           # select betas with this modality
    betas_box = masker_box.fit_transform(betas)  # apply mask on betas
    # Do MVPA with each classifier
    for clf_token, clf_model in zip(clf_tokens, clf_models):
        # Select features if the ROI is too big (not fixed)
        for iperc in FS_PERCs:
            feature_selected = SelectKBest(f_classif, k=iperc)  # feature selection
            clf_fs = Pipeline([('anova', feature_selected), ('classifier', clf_model)])
            # Unimodal MVPA
            acc, perm, pval = permutation_test_score(clf_fs, betas_box, targets, cv=CV, scoring='accuracy', 
                                                     n_permutations=N_PERM, groups=groups, n_jobs=N_JOBs)
            # Output ACC and perm scores
            df_acc.loc[len(df_acc)] = [imod, thisroi, clf_token, iperc, acc, -np.sort(-perm)[C], pval, P_PERM]
            f_perm = os.path.join(dir_mvpa, "group_tvrMVPC-%s-Perm%d_LOSOCV_ACC-%s_mask-%s-k%03d.1D" % (clf_token, N_PERM, imod, thisroi, iperc))
            perm.tofile(file=f_perm, sep='\n')

    print("Finish ROI-based group MVPA for subject: %s.\n" % subj) 
# output the performance table
df_acc.to_csv(f_acc)
## ---------------------------

now=datetime.now()
print("========== ALL DONE : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))
