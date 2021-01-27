## ---------------------------
## [script name] ps14_MVPA_AudioVisAssos1word_Searchlight_nilearn.py 
##
## SCRIPT to do searchlight MVPA on trials within its modality, i.e. visual trials or auditory trials. In this case, 
##              the cross-validation is leave-one-run-out.
##
## By Shuai Wang, [date] 2021-01-21
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
from datetime import datetime
from nilearn.image import load_img, index_img, mean_img, new_img_like
from sklearn import svm
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.naive_bayes import GaussianNB
from sklearn.model_selection import LeaveOneGroupOut
# setup path
mdir='/scratch/swang/agora/CP00/AudioVisAsso'  # the project main folder
ddir=os.path.join(mdir,'derivatives')          # different analyses after pre-processing
vdir=os.path.join(ddir,'multivariate')         # multivariate analyses folder
kdir=os.path.join(ddir,'masks')                # masks folder
# read subjects info
sfile=os.path.join(vdir,'participants_final.tsv')          # subjects info
subjects=pd.read_table(sfile).set_index('participant_id')  # the list of subjects
## ---------------------------

## MVPA parameters
# prepare classifiers without tuning parameters
clf_tokens=['lda','gnb','svclin','svcrbf']  # classifier tokens and order
clf_models=[LinearDiscriminantAnalysis(),
            GaussianNB(),
            svm.SVC(kernel='linear',max_iter=-1),
            svm.SVC(max_iter=-1)]
# searchlight parameters
radius=4  # searchlight radius in mm
njobs=-1  # -1 means all CPUs
# load up group mask (GM with EPI constrains)
# read trial labels
lfile=os.path.join(vdir,'trial_labels.csv')     # trial-wise labels
labels=pd.read_csv(lfile).set_index('stimuli')  # trial IDs
labels_trl=labels['conditions']                 # WA, WV, PA, PV
labels_lex=labels['lexicon']                    # word, pseudoword
labels_runs=labels['runs']                      # 5 runs, from run1 to run5
mask_vistrl=labels_trl.isin(['WV','PV'])        # visual trials
mask_audtrl=labels_trl.isin(['WA','PA'])        # auditory trials
## ---------------------------

now=datetime.now()
print("========== START JOB : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))

## MVPA

# do MVPA for each subject
CV=LeaveOneGroupOut()  # leave-one-run-out cross-validation
for subj in subjects.index[:]:
  print("do MVPA with classifiers: %s and leave-one-run-out CV for subject: %s ......\n" % (clf_tokens,subj))
  # setup subject path
  sdir=os.path.join(vdir,subj)          # subject working folder 
  bdir=os.path.join(sdir,'betas_afni')  # beta estimates
  pdir=os.path.join(sdir,'tvsMVPC')     # Trial-wise Volume-based Searchlight MVPC
  if not os.path.exists(pdir): os.makedirs(pdir)

#  # load up searchlight mask
#  mask_token='iGMepi'
#  mfile=os.path.join(sdir,'masks','iLVOT.nii')  # left vOT (Fusiform + ITC in AAL)
#  mfile=os.path.join(sdir,'masks',"%s.nii" % mask_token)  # GM mask file (individual GM with EPI constrains)
#  mask_slight=load_img(mfile)
  # load up betas
  fbetas="%s/%s_LSS_nilearn.nii.gz" % (bdir,subj)
  betas_all=load_img(fbetas)
  betas_vistrl=index_img(fbetas,mask_vistrl)
  betas_audtrl=index_img(fbetas,mask_audtrl)
  betas_mean=mean_img(betas_vistrl)
  # do MVPA with each classifier
  for clf_token,clf_model in zip(clf_tokens,clf_models):
    # train classifier with visual trials
    searchlight_vistrl=nilearn.decoding.SearchLight(mask_img=mask_slight,radius=radius,estimator=clf_model,n_jobs=njobs,cv=CV)
    searchlight_vistrl.fit(betas_vistrl,labels_trl[mask_vistrl],groups=labels_runs[mask_vistrl])
    # train classifier with auditory trials
    searchlight_audtrl=nilearn.decoding.SearchLight(mask_img=mask_slight,radius=radius,estimator=clf_model,n_jobs=njobs,cv=CV)
    searchlight_audtrl.fit(betas_audtrl,labels_trl[mask_audtrl],groups=labels_runs[mask_audtrl])
    # output MVPA results
    fvis="%s/%s_%s_MVPA_%s_LOROCV_ACC_vis.nii.gz" % (pdir,subj,mask_token,clf_token)
    faud="%s/%s_%s_MVPA_%s_LOROCV_ACC_aud.nii.gz" % (pdir,subj,mask_token,clf_token)
    acc_map_vistrl=new_img_like(betas_mean,searchlight_vistrl.scores_)
    acc_map_vistrl.to_filename(fvis)
    acc_map_audtrl=new_img_like(betas_mean,searchlight_audtrl.scores_)
    acc_map_audtrl.to_filename(faud)
  print("finish MVPA for subject: %s !\n" % subj) 
## ---------------------------

now=datetime.now()
print("========== ALL DONE : %s ==========\n" % now.strftime("%Y-%m-%d %H:%M:%S"))
