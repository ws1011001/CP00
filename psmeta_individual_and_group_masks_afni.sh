#!/bin/bash
## ---------------------------
## [script name] psmeta_individual_and_group_masks.sh
## SCRIPT to create individual and group masks, such as gray matter mask, EPI-constrained GM, multiple ROIs.
##
## By Shuai Wang
## ---------------------------

## Set environment (packages, functions, working path etc.)
# Platform
platform='mesoc'
case "$platform" in
	mesoc)
		dir_main='/CP00'                       # the project Main folder @mesocentre
	  	export PATH="$dir_main/nitools:$PATH"  # setup tools if @mesocentre
	  	njob=16
	  	;;
	local)
		dir_main='/data/mesocentre/data/agora/CP00'  # the project Main folder @totti
	  	njob=4
	  	;;
	*)
		echo -e "Please input a valid platform!"
	  	exit 1
esac
# Setup path
dir_data="$dir_main/AudioVisAsso"              # experiment Data folder (BIDS put into fMRIPrep)
dir_fmri="$dir_data/derivatives/fmriprep"      # fMRIPrep output folder
dir_afni="$dir_data/derivatives/afni"          # AFNI output folder
dir_mask="$dir_data/derivatives/masks"         # masks folder
dir_mvpa="$dir_data/derivatives/multivariate"  # MVPA/RSA folder
# Processing parameters
readarray subjects < $dir_main/CP00_subjects.txt
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
bold='desc-preproc_bold'          # the token for the preprocessed BOLD data (without smoothing)
regs='desc-confounds_timeseries'  # the token for fMRIPrep output nuisance regressors
anat='desc-preproc_T1w_brain'     # skull-stripped anatomical image
deno='NR24a'                      # denoising strategy
gmth=0.2                          # gray matter threshold between [0 1]
#tasks=("task-LocaVis1p75" "task-AudioVisAssos1word" "task-AudioVisAssos2words")
tasks=("task-LocaAudio2p5")
# switches
isCreateGMind=false
isCreateGMgrp=false
isCreateCoord=true
isCopyMaskRSA=false
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## create GM masks for each subject
if $isCreateGMind;then
  for subj in ${subjects[@]};do
    gdir="$dir_fmri/$subj/anat"  # individual folder that contains anatomical segments
    sdir="$dir_mask/$subj"       # individual masks folder
    if [ ! -d $sdir ];then mdir_mask -p $sdir;fi
    # prepare anatomical images
    gm_segment="$gdir/${subj}_${spac}_label-GM_probseg.nii.gz"         # gray matter segment in probability 
    gm_mask_t1="$sdir/${subj}_${spac}_mask-gm${gmth}_res-anat.nii.gz"  # gray matter mask in T1 resolution
    if [ ! -f "$gm_segment" ];then
      cp -r $gm_segment $sdir  # copy gray matter image to individual masks folder
    fi
    if [ ! -f "$gm_mask_t1" ];then
      # create individual gray matter masks
      3dcalc -a $gm_segment -expr "ispositive(a-$gmth)" -prefix $gm_mask_t1
    fi
    # create functional masks and functionally constrained gray matter masks
    for task in ${tasks[@]};do
      # setup path
      wdir="$dir_afni/$subj/$task"                       # the task Working folder
      oglm="${subj}_${task}_GLM.wBIM.wPSC.w${deno}"  # the token for the Output GLM
      if [ ! -d $oglm ];then
        oglm="${subj}_${task}_GLM.wPSC.w${deno}"     # the token for the Output GLM without BIM
      fi
      # create F-based masks
      stats_afni="$wdir/$oglm/stats.${subj}_${task}+tlrc.[0]"               # AFNI statistics
      stats_mask="$sdir/${subj}_${spac}_mask-full-F_res-${task}.nii.gz"     # functional mask based on full F statistics
      gm_mask_bd="$sdir/${subj}_${spac}_mask-gm${gmth}_res-${task}.nii.gz"  # gray matter mask in task resolution
      gm_fF_mask="$sdir/${subj}_${spac}_mask-gm-full-F_res-${task}.nii.gz"  # gray matter mask constrained by full F mask
      # calculate functional mask using full F statistics
      3dcalc -a $stats_afni -expr 'ispositive(a)' -prefix $stats_mask
      # create functionally constrained gray matter masks
      3dresample -master $stats_mask -prefix $gm_mask_bd -input $gm_mask_t1
      3dcalc -a $gm_mask_bd -b $stats_mask -expr 'a*b' -prefix $gm_fF_mask
      # copy EPI-extent mask for partial coverage tasks
      epi_mask="${subj}_${task}_${spac}_desc-brain_mask.nii.gz"
      gm_epi_mask="$sdir/${subj}_${spac}_mask-gm-epi_res-${task}.nii.gz"
      cp -r $wdir/$epi_mask $sdir
      3dcalc -a $gm_mask_bd -b $sdir/$epi_mask -expr 'a*b' -prefix $gm_epi_mask  # gray matter mask constrained by EPI
    done
  done
fi
## ---------------------------

## create group-averaged GM masks
if $isCreateGMgrp;then
  if [ ! -d "$dir_mask/group" ];then
    mdir_mask -p $dir_mask/group
  fi
  # gray matter mask
  ggm_segment="$dir_mask/group/group_${spac}_label-GM_probseg.nii.gz"
  ggm_segmean="$dir_mask/group/group_${spac}_label-GM_probseg-mean.nii.gz"
  ggm_mask_t1="$dir_mask/group/group_${spac}_mask-gm${gmth}_res-anat.nii.gz"
  if [ ! -f "$ggm_segmean" ];then
    3dbucket -fbuc -aglueto $ggm_segment $dir_mask/sub-*/sub-*_${spac}_label-GM_probseg.nii.gz
    3dTstat -prefix $ggm_segmean -mean $ggm_segment
  fi
  if [ ! -f "$ggm_mask_t1" ];then
    3dcalc -a $ggm_segmean -expr "ispositive(a-$gmth)" -prefix $ggm_mask_t1
  fi
  # functional mask (i.e. full F) and functionally constrained gray matter mask
  for task in ${tasks[@]};do
    gstats_mask="$dir_mask/group/group_${spac}_mask-full-F_res-${task}.nii.gz"
    gepi_mask="$dir_mask/group/group_${task}_${spac}_desc-brain_mask.nii.gz"
    ggm_mask_bd="$dir_mask/group/group_${spac}_mask-gm${gmth}_res-${task}.nii.gz"
    ggm_fF_mask="$dir_mask/group/group_${spac}_mask-gm-full-F_res-${task}.nii.gz"
    ggm_epi_mask="$dir_mask/group/group_${spac}_mask-gm-epi_res-${task}.nii.gz"
    # group-averaged F mask
    3dmask_tool -input $dir_mask/sub-*/sub-*_${spac}_mask-full-F_res-${task}.nii.gz -prefix $gstats_mask -frac 1.0
    # group-averaged EPI mask
    3dmask_tool -input $dir_mask/sub-*/sub-*_${task}_${spac}_desc-brain_mask.nii.gz -prefix $gepi_mask -frac 1.0
    # resample GM to task resolution
    3dresample -master $gstats_mask -prefix $ggm_mask_bd -input $ggm_mask_t1
    # F constrained GM
    3dcalc -a $ggm_mask_bd -b $gstats_mask -expr 'a*b' -prefix $ggm_fF_mask  # manually check *mask-gm-full-F* masks to get *mask-gm-full-F-final* masks
    # EPI constrained GM
    3dcalc -a $ggm_mask_bd -b $gepi_mask -expr 'a*b' -prefix $ggm_epi_mask  # manually check *mask-gm-epi* masks to get *mask-gm-epi-final* masks
  done
fi
## ---------------------------

## Create coordinate-based masks
if $isCreateCoord;then
	dir_coord="$dir_mask/coordinates"
  	f_coord="$dir_coord/group_${spac}_mask-coordinates.csv"
  	f_ilvot="$dir_coord/group_${spac}_mask-ilvOT-coordinates.csv"
  	f_glvot="$dir_mask/group/group_${spac}_mask-lvOT-visual.nii.gz"
  	f_gm="$dir_mask/group/group_${spac}_mask-gm0.2_res-task-LocaVis1p75.nii.gz"
  	rads=(4 5 6 7 8)  # 4,5,6,7,8
  	# Create mask for each coordinate
  	OLDIFS=$IFS  # original delimiter
  	IFS=','      # delimiter of CSV
  	# Group ROIs
  	while read thisroi x y z;do
		for srad in ${rads[@]};do
			f_roi="$dir_coord/group_${spac}_mask-${thisroi}-sph${srad}mm.nii.gz"
  	  	  	if [ ! -f "$f_roi" ];then
				echo -e "Create a shpere ROI $thisroi with radius ${srad}mm and centre $x $y $z."
  	  	  	  	echo "$x $y $z 1" > $dir_coord/${thisroi}.peak
  	  	  	  	3dUndump -master $f_glvot -srad $srad -prefix $f_roi -xyz $dir_coord/${thisroi}.peak
  	  	  	  	rm -r $dir_coord/${thisroi}.peak
  	  	  	fi  
  	  	done
  	done < $f_coord
 	# Individual left-vOT (ilvOT)
 	while read subj x y z;do
		for srad in ${rads[@]};do
			f_roi="$dir_mask/$subj/${subj}_${spac}_mask-ilvOT-sph${srad}mm.nii.gz"
 	  	  	if [ ! -f "$f_roi" ];then
				echo -e "Create a shpere ROI ilvOT with radius ${srad}mm and centre $x $y $z."
 	  	  	  	echo "$x $y $z 1" > $dir_coord/${subj}_ilvOT.peak
 	  	  	  	3dUndump -master $f_glvot -srad $srad -prefix $f_roi -xyz $dir_coord/${subj}_ilvOT.peak
 	  	  	  	rm -r $dir_coord/${subj}_ilvOT.peak
 	  	  	fi  
 	  	  	# Constrained by the group GM
 	  	  	f_new="$dir_mask/$subj/${subj}_${spac}_mask-ilvOT-gm-sph${srad}mm.nii.gz"
 	  	  	3dcalc -a $f_roi -b $f_gm -expr 'a*b' -prefix $f_new
 	  	done
 	done < $f_ilvot
  	IFS=$OLDIFS
fi
## ---------------------------

## copy individual and group masks for RSA
if $isCopyMaskRSA;then 
  ftvr="$dir_mvpa/group_masks_labels-ROI.csv"
  ftvs="$dir_mvpa/group_masks_labels-searchlight.csv"
  for subj in ${subjects[@]};do
    idir="$dir_mask/$subj"                 # individual masks folder
    tvrRSA="$dir_mvpa/$subj/tvrRSA/masks"  # masks for ROI-base RSA
    tvsRSA="$dir_mvpa/$subj/tvsRSA/masks"  # masks for searchlight RSA
    # assign IFS to read CSV files
    OLDIFS=$IFS  # original delimiter
    IFS=','      # delimiter of CSV
    # copy masks for ROI-based RSA
    if [ ! -d $tvrRSA ];then mdir_mask -p $tvrRSA;fi
    rm -r $tvrRSA/*-*.nii  # remove any NIFTI files with a '-' in name in that folder
    sed 1d $ftvr | while read thisroi fixed input;do
      if [ $input -eq 1 ];then
        echo -e "Copy mask $thisroi to ROI-based RSA for subject $subj ......"
        if [ "${thisroi::1}" = 'i' ];then
          froi="$idir/${subj}_${spac}_mask-${thisroi}.nii.gz"
        else
          froi="$dir_mask/group/group_${spac}_mask-${thisroi}.nii.gz"
        fi
        3dcopy $froi $tvrRSA/${thisroi//-/_}.nii  # replace '-' by '_' for rsatoolbox in MATLAB
      else
        echo -e "Pass mask $thisroi since it has been copied."
      fi
    done
    # copy masks for searchlight RSA
    if [ ! -d $tvsRSA ];then mdir_mask -p $tvsRSA;fi
    rm -r $tvsRSA/*-*.nii  # remove any NIFTI files with a '-' in name in that folder
    sed 1d $ftvs | while read thisroi fixed input;do
      if [ $input -eq 1 ];then
        echo -e "Copy mask $thisroi to searchlight RSA for subject $subj ......"
        if [ "${thisroi::1}" = 'i' ];then
          froi="$idir/${subj}_${spac}_mask-${thisroi}.nii.gz"
        else
          froi="$dir_mask/group/group_${spac}_mask-${thisroi}.nii.gz"
        fi
        3dcopy $froi $tvsRSA/${thisroi//-/_}.nii  # replace '-' by '_' for rsatoolbox in MATLAB
      else
        echo -e "Pass mask $thisroi since it has been copied."
      fi
    done
    # re-assign IFS to read subjects otherwise it will cause an error in file path
    IFS=$OLDIFS
  done
fi
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
