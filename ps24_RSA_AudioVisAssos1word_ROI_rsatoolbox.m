%% ---------------------------
%% [script name] ps23_RSA_AudioVisAssos1word_ROI_rsatoolbox.m 
%%
%% SCRIPT to do the representational similarity analysis for the AudioVisAssos1word task. The RSA is performed on 
%% trial-wise estimates and focus on several ROIs within vOT.
%%
%% By Shuai Wang, [date] 2021-08-24
%%
%% ---------------------------
%% Notes: 1. To prepare masks (i.e. ROIs), put ROIs in NIFTI .nii format under the subject's tvrRSA folder.
%%        2. For subject ID and mask labels in the RSA setting structure, replace '-' by '_' since MATLAB structures 
%%           (required by rsatoolbox) do not allow symbol '-' in the name of a field.
%%   
%%
%% ---------------------------

%% clean up
close all
clear
clc
%% ---------------------------

%% set environment (packages, functions, working path etc.)
% setup working path
mdir = '/CP00';
ddir = fullfile(mdir, 'AudioVisAsso', 'derivatives');
vdir = fullfile(ddir, 'multivariate');
% setup packages
addpath('/CP00/nitools/spm8');
addpath(genpath('/CP00/nitools/rsatoolbox'));
% read the subjects list
fid = fopen(fullfile(mdir, 'CP00_subjects.txt'));
subjects = textscan(fid, '%s');
fclose(fid);
subjects = subjects{1};  % the subjects list
n = length(subjects);
% read ROIs info
ROIs = readtable(fullfile(vdir, 'group_masks_labels-ROI.csv'));
ROIs = ROIs.label;
nROI = length(ROIs);
ROIs = cellfun(@(x) strrep(x, '-', '_'), ROIs, 'UniformOutput', 0);  % make sure ROI labels dont have any '-'
% setup RSA common parameters
ds_common.maskNames      = ROIs;  
ds_common.distance       = 'Correlation';
ds_common.RoIColor       = [0 0 1];
ds_common.displayFigures = false;
ds_common.saveFiguresJpg = true;  
%% ---------------------------

%% perform ROI-based RSA
for i = 1:n
  sid = subjects{i};               % original subject ID
  subj = {strrep(sid, '-', '_')};  % replace '-' by '_' 
  fprintf('Perform trial-wise volume-based ROIs-only RSA for subject: %s ......\n', sid)
  % RSA settings
  ds_working              = ds_common;  % inherit common parameters
  ds_working.analysisName = sid;   % original subject ID
  ds_working.subjectNames = subj;  % subject ID (in a cell) without any '-'
  ds_working.rootPath     = fullfile(vdir, sid, 'tvrRSA');  % Trial-wise Volume-based ROIs-only RSA    
  ds_working.maskPath     = fullfile(ds_working.rootPath, 'masks', '[[maskName]].nii');  % prepare masks  
  if ~exist(fullfile(ds_working.rootPath, 'SWAP'), 'dir')
    mkdir(fullfile(ds_working.rootPath, 'SWAP'));
  end
  % prepare fMRI data
  bdir = fullfile(vdir, sid, 'betas_afni');  % betas folder
  fbet = dir(fullfile(bdir, '*.nii'));       % beta files in NIFTI .nii format
  betas_label = extractfield(fbet, 'name');  % to be used as trial labels
  betas = cell2struct(betas_label(:), 'identifier', 2);
  betas = betas';  % to be used as the first argument in the function fMRIDataPreparation()
  ds_working.betaPath = fullfile(bdir, '[[betaIdentifier]]');
  ds_working.conditionLabels = betas_label;
  data_betas = fMRIDataPreparation(betas, ds_working);
  data_masks = fMRIMaskPreparation(ds_working);
  % calculate RDMs
  data_masked_betas = fMRIDataMasking(data_betas, data_masks, betas, ds_working);
  data_RDMs = constructRDMs(data_masked_betas, betas, ds_working);
  % output figures of RDM 
  for iROI = 1:nROI
    figureRDMs(data_RDMs(iROI), ds_working, struct('fileName', sprintf('RDM_mask-%s', ROIs{iROI})));   
  end
  fout = fullfile(ds_working.rootPath, 'SWAP', sprintf('%s_tvrRSA_working_data.mat', sid));
  save(fout, 'ds_working', 'betas*');
  clear betas* data_*
end
%% ---------------------------
