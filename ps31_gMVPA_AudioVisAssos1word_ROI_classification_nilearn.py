#!/usr/bin/env python
## ---------------------------
## [script name] ps31_gMVPA_AudioVisAssos1word_ROI_classification_nilearn.py
## SCRIPT to do classifier selection with the box ROI of VWFA on trials within its modality (i.e. visual and auditory
##              trials) at the group level (group MVPA). In this case, the cross-validation is leave-one-sub-out.
##
## By Shuai Wang, [date] 2023-04-14
## ---------------------------
## Notes: - do not tune parmeters, instead use L2 linear-SVM as a reference (Varoquaux et al., 2017)
## ---------------------------


## Set environment (packages, functions, working path etc.)
# Load up packages
import os
import pickle
import nilearn.decoding
import pandas as pd
import numpy as np
from datetime import datetime
from nilearn.image import load_img, index_img, mean_img, new_img_like
from nilearn.input_data import NiftiMasker
from sklearn import svm
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.naive_bayes import GaussianNB
from sklearn.model_selection import LeaveOneGroupOut, PredefinedSplit, cross_validate, permutation_test_score
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
np.random.seed(21)  # random seed for sklearn
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
ST       = 'temporal'               # standardization method: none; spatial; temporal (default); spatial-temporal
# Read ROIs information
f_roi = os.path.join(dir_mvpa, 'group_masks_labels-ROI.csv')  # ROIs info
df_roi = pd.read_csv(f_roi).set_index('label')              # the list of ROIs
df_roi = df_roi[df_roi.input == 1]                             # only inculde new ROIs
nroi = len(df_roi)
## ---------------------------

now = datetime.now()
print("========== START JOB : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))

## MVPA
# Read trial labels
f_labels = os.path.join(dir_mvpa, f'group_{task}_labels-group-trial.tsv')  # trial-wise labels
df_labels = pd.read_table(f_labels) # trial labels
# Initialize performance tables
f_cv_acc = os.path.join(dir_mvpa, f'group_{task}_gMVPA_LOSOCV_ST-{ST}_unimodal+crossmodal.csv')  # performance table
dt_cv_acc = {'participant_id': [], 'modality': [], 'ROI_label': [], 'classifier': [], 'nvox': [], 'ACC': []}
f_acc = os.path.join(dir_mvpa, f'group_{task}_gMVPA_LOSOCV-Perm{N_PERM}_ST-{ST}_unimodal.csv')  # performance table
df_acc = pd.DataFrame(columns = ['modality', 'ROI_label', 'classifier', 'nvox', 'ACC', 'CPermACC', 'Pval', 'CPval'])
# Do MVPA with leave-one-subject-out CV
CV = LeaveOneGroupOut()  # leave-one-subject-out cross-validation
f_betas = "%s/group_LSS_nilearn.nii.gz" % dir_mvpa
for imod in mods:
    # Read labels and betas according to the modality
    labels_cross = np.zeros(len(df_labels))  # initial labels for cross-modal decoding
    labels = df_labels['correct'] * (df_labels['modality'] == imod)
    labels_cross[labels] = -1  # this modality is for cross-modal training (-1)
    groups = df_labels['participant_id'][labels].values
    targets = df_labels['lexicon'][labels].values   
    betas = index_img(f_betas, labels)           # select betas with this modality
    # Loop ROI
    for iroi in range(nroi):
        thisroi = df_roi.index[iroi]
        f_mask = os.path.join(dir_mask, 'group', "group_%s_mask-%s.nii.gz" % (spac, thisroi))            
        img_mask = load_img(f_mask)
        nvox = np.sum(img_mask.get_data())  # Number of voxels
        masker_box = NiftiMasker(mask_img=img_mask, standardize=False, detrend=False)  # mask transformer
        betas_box = masker_box.fit_transform(betas)  # apply mask on betas

        if ST == 'spatial':
            print(f'Do spatial standardization for {thisroi}.\n')
            betas_box = (betas_box - betas_box.mean(axis=1).reshape(-1, 1)) / betas_box.std(axis=1).reshape(-1, 1)  # spatial
        elif ST == 'temporal':
            print(f'Do temporal standardization for {thisroi}.\n')
            betas_box = (betas_box - betas_box.mean(axis=0).reshape(1, -1)) / betas_box.std(axis=0).reshape(1, -1)  # temporal
        elif ST == 'spatial-temporal':
            print(f'Do spatial and temporal standardization sequentially for {thisroi}.\n')
            betas_box = (betas_box - betas_box.mean(axis=1).reshape(-1, 1)) / betas_box.std(axis=1).reshape(-1, 1)  # spatial
            betas_box = (betas_box - betas_box.mean(axis=0).reshape(1, -1)) / betas_box.std(axis=0).reshape(1, -1)  # temporal
        else:
            print('No standardization for {thisroi}.\n') 

        # Do MVPA with each classifier
        for clf_token, clf_model in zip(clf_tokens, clf_models):
            if df_roi.fixed[iroi]:
                # Unimodal MVPA: cross-validation
                cv_results = cross_validate(clf_model, betas_box, targets, cv=CV, scoring='accuracy', groups=groups, n_jobs=N_JOBs)
                f_cv = os.path.join(dir_mvpa, 'groupMVPA', f'group_gMVPA-{clf_token}_LOSOCV_ST-{ST}_ACC-{imod}_mask-{thisroi}.pkl')
                f = open(f_cv, 'wb')
                pickle.dump(cv_results, f)  # save the list of data
                f.close()
                print(f'Check the performance of the classifer {clf_token} with {nvox} features of {thisroi} for the modality {imod}:')
                print(f"Averaged ACC = {cv_results['test_score'].mean()}, SD = {cv_results['test_score'].std()}.\n")
                dt_cv_acc['participant_id'] += [f'sub-{i:02d}' for i in range(1, n+1)]
                dt_cv_acc['modality']       += [imod] * n
                dt_cv_acc['ROI_label']      += [thisroi] * n
                dt_cv_acc['classifier']     += [clf_token] * n
                dt_cv_acc['nvox']           += [nvox] * n
                dt_cv_acc['ACC']            += cv_results['test_score'].tolist()            
                ## Unimodal MVPA: permutation test
                #acc, perm, pval = permutation_test_score(clf_fs, betas_box, targets, cv=CV, scoring='accuracy', n_permutations=N_PERM, groups=groups, n_jobs=N_JOBs)
                #df_acc.loc[len(df_acc)] = [imod, thisroi, clf_token, k, acc, -np.sort(-perm)[C], pval, P_PERM]  # Output ACC and perm scores
                #f_perm = os.path.join(dir_mvpa, "group_tvrMVPC-%s-Perm%d_LOSOCV_ACC-%s_mask-%s-k%03d.1D" % (clf_token, N_PERM, imod, thisroi, k))
                #perm.tofile(file=f_perm, sep='\n')
                # Cross-modal MVPA: cross-validation
                cross_results = []
                for i in range(n):
                    subj = subjects.index[i]
                    labels_train = df_labels['correct'] * (df_labels['modality'] == imod) * (df_labels['participant_id'] != subj)
                    labels_valid = df_labels['correct'] * (df_labels['modality'] != imod) * (df_labels['participant_id'] == subj)
                    labels_all = labels_train | labels_valid
                    CV_cross = PredefinedSplit(labels_cross[labels_all])  # pre-defined CV for cross-modal decoding
                    targets = df_labels['lexicon'][labels_all].values   
                    betas = index_img(f_betas, labels_all)           # select betas with this modality
                    betas_box = masker_box.fit_transform(betas)  # apply mask on betas

                    if ST == 'spatial':
                        print(f'Do spatial standardization for {thisroi}.\n')
                        betas_box = (betas_box - betas_box.mean(axis=1).reshape(-1, 1)) / betas_box.std(axis=1).reshape(-1, 1)  # spatial
                    elif ST == 'temporal':
                        print(f'Do temporal standardization for {thisroi}.\n')
                        betas_box = (betas_box - betas_box.mean(axis=0).reshape(1, -1)) / betas_box.std(axis=0).reshape(1, -1)  # temporal
                    elif ST == 'spatial-temporal':
                        print(f'Do spatial and temporal standardization sequentially for {thisroi}.\n')
                        betas_box = (betas_box - betas_box.mean(axis=1).reshape(-1, 1)) / betas_box.std(axis=1).reshape(-1, 1)  # spatial
                        betas_box = (betas_box - betas_box.mean(axis=0).reshape(1, -1)) / betas_box.std(axis=0).reshape(1, -1)  # temporal
                    else:
                        print('No standardization for {thisroi}.\n')

                    acc = permutation_test_score(clf_model, betas_box, targets, cv=CV_cross, scoring='accuracy', n_permutations=1, groups=groups, n_jobs=N_JOBs)
                    cross_results.append(acc)
                print(f'Check the performance of the classifer {clf_token} with {nvox} features of {thisroi} for the modality {imod}2:')
                print(f"Averaged ACC = {np.mean(cross_results)}, SD = {np.std(cross_results)}.\n")
                dt_cv_acc['participant_id'] += [f'sub-{i:02d}' for i in range(1, n+1)]
                dt_cv_acc['modality']       += [f'{imod}2'] * n
                dt_cv_acc['ROI_label']      += [thisroi] * n
                dt_cv_acc['classifier']     += [clf_token] * n
                dt_cv_acc['nvox']           += [nvox] * n
                dt_cv_acc['ACC']            += cross_results
    print('Finish ROI-based group MVPA.\n')
# output the performance table
df_cv_acc = pd.DataFrame.from_dict(dt_cv_acc)
df_cv_acc.to_csv(f_cv_acc)
#df_acc.to_csv(f_acc)
## ---------------------------

now=datetime.now()
print("========== ALL DONE : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))
