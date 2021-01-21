## ---------------------------
## [script name] ps05_MVPA_AudioVisAssos1word_Searchlight_nilearn.py 
##
## SCRIPT to ...
##
## By Shuai Wang, [date]
##
## ---------------------------
## Notes:
##   
##
## ---------------------------

## clean up
## ---------------------------

## set environment (packages, functions, working path etc.)
# load up packages
import os
import nilearn.decoding
import pandas as pd
from nilearn.image import load_img, index_img, mean_img, new_img_like
from sklearn import svm
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.naive_bayes import GaussianNB
from sklearn.model_selection import LeaveOneGroupOut, PredefinedSplit
# setup path
mdir='/scratch/swang/agora/CP00/AudioVisAsso'        # the project main folder
#mdir='/data/mesocentre/data/agora/CP00/AudioVisAsso'        # the project main folder
ddir=os.path.join(mdir,'derivatives')
vdir=os.path.join(ddir,'multivariate')  # multivariate analyses folder
## ---------------------------

## MVPA parameters
# prepare classifiers
clf_tokens=['lda','gnb','svclin','svcrbf']  # classifier tokens and order
clf_models=[LinearDiscriminantAnalysis(),
            GaussianNB(),
            svm.SVC(kernel='linear',max_iter=-1),
            svm.SVC(max_iter=-1)]
# searchlight parameters
radius=4                              # searchlight radius in mm
njobs=-1                              # -1 means all CPUs
## ---------------------------

## MVPA
# read subjects info
sfile=os.path.join(vdir,'participants.tsv')  # subjects list
subjects=pd.read_table(sfile).set_index('participant_id')
# do MVPA for each subject
CV=LeaveOneGroupOut()  # leave-one-run-out cross-validation
for subj in subjects.index[:]:
  print("do MVPA with classifiers: %s and leave-one-run-out CV for subject: %s ......" % (clf_tokens,subj))
  # setup subject path
  sdir=os.path.join(vdir,subj)
  bdir=os.path.join(sdir,'betas_afni')  # beta estimates
  pdir=os.path.join(sdir,'tvsMVPC')     # Trial-wise Volume-based Searchlight MVPC
  if not os.path.exists(pdir): os.makedirs(pdir)
  # read trial labels
  lfile=os.path.join(sdir,'trial_labels.csv')   # trial-wise labels
  labels=pd.read_csv(lfile).set_index('stimuli')
  labels_trl=labels['conditions']
  labels_lex=labels['lexicon']
  labels_runs=labels['runs']
  mask_vistrl=labels_trl.isin(['WV','PV'])
  mask_audtrl=labels_trl.isin(['WA','PA'])
  audtrain=labels['audtrain']
  vistrain=labels['vistrain']
  # load up searchlight mask
  mask_token='iGMepi'
#  mfile=os.path.join(sdir,'masks','iLVOT.nii')  # left vOT (Fusiform + ITC in AAL)
  mfile=os.path.join(sdir,'masks',"%s.nii" % mask_token)  # GM mask file (individual GM with EPI constrains)
  mask_slight=load_img(mfile)
  # load up betas
  fbetas="%s/%s_LSS_nilearn.nii.gz" % (bdir,subj)
  betas_all=load_img(fbetas)
  betas_vistrl=index_img(fbetas,mask_vistrl)
  betas_audtrl=index_img(fbetas,mask_audtrl)
  betas_mean=mean_img(betas_vistrl)
  # do MVPA with each classifier
  PS_audtrain=PredefinedSplit(audtrain)
  PS_vistrain=PredefinedSplit(vistrain)
  for clf_token,clf_model in zip(clf_tokens,clf_models):
    # train classifier with visual trials
    searchlight_vistrl=nilearn.decoding.SearchLight(mask_img=mask_slight,radius=radius,estimator=clf_model,n_jobs=njobs,cv=CV)
    searchlight_vistrl.fit(betas_vistrl,labels_trl[mask_vistrl],groups=labels_runs[mask_vistrl])
    # train classifier with auditory trials
    searchlight_audtrl=nilearn.decoding.SearchLight(mask_img=mask_slight,radius=radius,estimator=clf_model,n_jobs=njobs,cv=CV)
    searchlight_audtrl.fit(betas_audtrl,labels_trl[mask_audtrl],groups=labels_runs[mask_audtrl])
    # train classifier with visual trials but test it using auditory trials (cross-modal decoding)
    searchlight_vis2aud=nilearn.decoding.SearchLight(mask_img=mask_slight,radius=radius,estimator=clf_model,n_jobs=njobs,cv=PS_vistrain)
    searchlight_vis2aud.fit(betas_all,labels_lex)
    # train classifier with auditory trials but test it using visual trials (cross-modal decoding)
    searchlight_aud2vis=nilearn.decoding.SearchLight(mask_img=mask_slight,radius=radius,estimator=clf_model,n_jobs=njobs,cv=PS_audtrain)
    searchlight_aud2vis.fit(betas_all,labels_lex)
    # output MVPA results
    fvis="%s/%s_%s_MVPA_%s_LOROCV_ACC_vis.nii.gz" % (pdir,subj,mask_token,clf_token)
    faud="%s/%s_%s_MVPA_%s_LOROCV_ACC_aud.nii.gz" % (pdir,subj,mask_token,clf_token)
    fv2a="%s/%s_%s_MVPA_%s_LOROCV_ACC_vis2aud.nii.gz" % (pdir,subj,mask_token,clf_token)
    fa2v="%s/%s_%s_MVPA_%s_LOROCV_ACC_aud2vis.nii.gz" % (pdir,subj,mask_token,clf_token)
    acc_map_vistrl=new_img_like(betas_mean,searchlight_vistrl.scores_)
    acc_map_vistrl.to_filename(fvis)
    acc_map_audtrl=new_img_like(betas_mean,searchlight_audtrl.scores_)
    acc_map_audtrl.to_filename(faud)
    acc_map_vis2aud=new_img_like(betas_mean,searchlight_vis2aud.scores_)
    acc_map_vis2aud.to_filename(fv2a)
    acc_map_aud2vis=new_img_like(betas_mean,searchlight_aud2vis.scores_)
    acc_map_aud2vis.to_filename(fa2v)
  print("finish MVPA for subject: %s !" % subj) 
## ---------------------------

