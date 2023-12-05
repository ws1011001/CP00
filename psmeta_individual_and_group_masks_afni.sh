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
#tasks=("task-LocaVis1p75" "task-LocaAudio2p5" "task-AudioVisAssos1word" "task-AudioVisAssos2words")
tasks=("task-AudioVisAssos1word" "task-AudioVisAssos2words")
# switches
isCreateGMind=true
isCreateGMgrp=true
isCreateCoord=false
isCopyMaskRSA=false
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## create GM masks for each subject
if $isCreateGMind;then
	for subj in ${subjects[@]};do
		echp -e "Create individual masks for subject $subj."
		dir_anat="$dir_fmri/$subj/anat"  # individual folder that contains anatomical segments
  	  	dir_subj="$dir_mask/$subj"       # individual masks folder
  	  	if [ ! -d $dir_subj ];then mkdir -p $dir_subj;fi
  	  	# prepare anatomical images
  	  	f_segment="$dir_anat/${subj}_${spac}_label-GM_probseg.nii.gz"         # gray matter segment in probability 
  	  	f_mask_gmt1="$dir_subj/${subj}_${spac}_mask-gm${gmth}_res-anat.nii.gz"  # gray matter mask in T1 resolution
  	  	#if [ ! -f "$f_segment" ];then
		#	cp -r $f_segment $dir_subj  # copy gray matter image to individual masks folder
  	  	#fi
  	  	if [ ! -f "$f_mask_gmt1" ];then
  	  	  	3dcalc -a $f_segment -expr "ispositive(a-$gmth)" -prefix $f_mask_gmt1  # create individual gray matter masks
  	  	fi
  	  	# Create functional masks and functionally constrained gray matter masks
  	  	for task in ${tasks[@]};do
  	  	  	dir_task="$dir_afni/$subj/$task"                       # the task Working folder
  	  	  	oglm="${subj}_${task}_GLM.wBIM.wPSC.w${deno}"  # the token for the Output GLM
  	  	  	if [ ! -d "$dir_task/$oglm" ];then
				oglm="${subj}_${task}_GLM.wPSC.w${deno}"     # the token for the Output GLM without BIM
  	  	  	fi
  	  	  	# Create F-based masks
  	  	  	f_stats="$dir_task/$oglm/stats.${subj}_${task}+tlrc.[0]"               # AFNI statistics
  	  	  	f_mask_F="$dir_subj/${subj}_${spac}_mask-full-F_res-${task}.nii.gz"     # functional mask based on full F statistics
  	  	  	f_mask_gmtask="$dir_subj/${subj}_${spac}_mask-gm${gmth}_res-${task}.nii.gz"  # gray matter mask in task resolution
  	  	  	f_mask_gm_F="$dir_subj/${subj}_${spac}_mask-gm-full-F_res-${task}.nii.gz"  # gray matter mask constrained by full F mask
			if [ ! -f "$f_mask_F" ];then
				3dcalc -a $f_stats -expr 'ispositive(a)' -prefix $f_mask_F  # calculate functional mask using full F statistics
				3dresample -master $f_mask_F -prefix $f_mask_gmtask -input $f_mask_gmt1
				3dcalc -a $f_mask_gmtask -b $f_mask_F -expr 'a*b' -prefix $f_mask_gm_F  # create functionally constrained gray matter masks
			fi
  	  	  	# Create EPI-extent mask for partial coverage tasks
  	  	  	f_mask_epi="$dir_task/${subj}_${task}_${spac}_desc-brain_mask.nii.gz"
  	  	  	f_mask_gm_epi="$dir_subj/${subj}_${spac}_mask-gm-epi_res-${task}.nii.gz"
			if [ ! -f "$f_mask_gm_epi" ];then
				3dcalc -a $f_mask_gmtask -b $f_mask_epi -expr 'a*b' -prefix $f_mask_gm_epi  # gray matter mask constrained by EPI
			fi
			# Create TSNR masks
			f_tsnr="$dir_task/$oglm/TSNR.${subj}_${task}+tlrc."
			f_mask_tsnr="$dir_mask/$subj/${subj}_${spac}_mask-TSNR20_res-${task}.nii.gz"
			if [ ! -f "$f_mask_tsnr" ];then
				3dcalc -a $f_tsnr -expr 'within(a,20,1000)' -prefix $f_mask_tsnr
			fi
  	  	done
  	done
fi
## ---------------------------

## Create group-averaged GM masks
if $isCreateGMgrp;then
	if [ ! -d "$dir_mask/group" ];then mkdir -p $dir_mask/group; fi
  	# Gray matter mask
  	f_segment="$dir_mask/group/group_${spac}_label-GM_probseg.nii.gz"
  	f_segment_avg="$dir_mask/group/group_${spac}_label-GM_probseg-mean.nii.gz"
  	f_mask_gmt1="$dir_mask/group/group_${spac}_mask-gm${gmth}_res-anat.nii.gz"
  	if [ ! -f "$f_segment_avg" ];then
		3dbucket -fbuc -aglueto $f_segment $dir_mask/sub-*/sub-*_${spac}_label-GM_probseg.nii.gz
  	  	3dTstat -prefix $f_segment_avg -mean $f_segment
  	fi
  	if [ ! -f "$f_mask_gmt1" ];then
		3dcalc -a $f_segment_avg -expr "ispositive(a-$gmth)" -prefix $f_mask_gmt1
  	fi
  	# Functional mask (i.e. full F) and functionally constrained gray matter mask
  	for task in ${tasks[@]};do
		f_mask_F="$dir_mask/group/group_${spac}_mask-full-F_res-${task}.nii.gz"
  	  	f_mask_epi="$dir_mask/group/group_${task}_${spac}_desc-brain_mask.nii.gz"
  	  	f_mask_gmtask="$dir_mask/group/group_${spac}_mask-gm${gmth}_res-${task}.nii.gz"
  	  	f_mask_gm_F="$dir_mask/group/group_${spac}_mask-gm-full-F_res-${task}.nii.gz"
  	  	f_mask_gm_epi="$dir_mask/group/group_${spac}_mask-gm-epi_res-${task}.nii.gz"
		f_tsnr_grp="$dir_afni/group/$task/stats.TSNR_group_${task}.nii.gz"
		f_tsnr_avg="$dir_afni/group/$task/stats.TSNRmean_group_${task}.nii.gz"
		f_mask_gtsnr="$dir_mask/group/group_${spac}_mask-TSNR20_res-${task}.nii.gz"
		if [ ! -f "$f_mask_gm_epi" ];then
			3dmask_tool -input $dir_mask/sub-*/sub-*_${spac}_mask-full-F_res-${task}.nii.gz -prefix $f_mask_F -frac 1.0  # group-averaged F mask
  	  		3dmask_tool -input $dir_mask/sub-*/sub-*_${task}_${spac}_desc-brain_mask.nii.gz -prefix $f_mask_epi -frac 1.0  # group-averaged EPI mask
  	  		3dresample -master $f_mask_F -prefix $f_mask_gmtask -input $f_mask_gmt1  # resample GM to task resolution
  	  		3dcalc -a $f_mask_gmtask -b $f_mask_F -expr 'a*b' -prefix $f_mask_gm_F  # F constrained GM: manually check *mask-gm-full-F* masks to get *mask-gm-full-F-final* masks
  	  		3dcalc -a $f_mask_gmtask -b $f_mask_epi -expr 'a*b' -prefix $f_mask_gm_epi  # EPI constrained GM: manually check *mask-gm-epi* masks to get *mask-gm-epi-final* masks
		fi
		if [ ! -f "$f_mask_gtsnr" ];then
			3dbucket -fbuc -aglueto $f_tsnr_grp $dir_afni/sub-*/sub-*_${task}_GLM.wBIM.wPSC.w${deno}/TSNR.sub-*_${task}+tlrc.
			3dTstat -prefix $f_tsnr_avg -mean $f_tsnr_grp
			3dcalc -a $f_tsnr_avg -expr 'within(a,20,1000)' -prefix $f_mask_gtsnr
		fi
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
    if [ ! -d $tvrRSA ];then mkdir -p $tvrRSA;fi
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
    if [ ! -d $tvsRSA ];then mkdir -p $tvsRSA;fi
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
