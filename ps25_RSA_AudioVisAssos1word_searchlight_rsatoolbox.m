%% ---------------------------
%% [script name] ps05_RSA_AudioVisAssos1word_Searchlight_rsatoolbox.m 
%%
%% SCRIPT to do the representational similarity analysis for the AudioVisAssos1word task with the original design. The 
%% RSA will be performed on trial-wise estimates with searchlight method.
%%
%% By Shuai Wang, [date]
%%
%% ---------------------------
%% Notes: Run this script on mesocentre using singularity and slurm.
%%        Dot '.' cannot be used as part of a m file name!!!
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
% setup RSA common parameters
ds_common.maskNames         = {'bvOT_Bouhali2019'};  % ROI labels without any '-'
ds_common.searchlightRadius = 4;                     % searchlight kernel radius (mm)
ds_common.voxelSize         = [1.754 1.754 1.75];    % 57 voxels
ds_common.distance          = 'Correlation';
ds_common.RoIColor          = [0 0 1];
ds_common.displayFigures    = false;
ds_common.saveFiguresJpg    = true; 
%% ---------------------------

%% RDM models
% trial-wise RDM models

%% ---------------------------

%% perform searchlight RSA
% prepare working data
for i=1:n
  sid = subjects{i};               % original subject ID
  subj = {strrep(sid, '-', '_')};  % replace '-' by '_' 
  fprintf('Extract working data for trial-wise volume-based searchlight RSA for subject: %s ......\n', sid)
  % RSA settings
  ds_working              = ds_common;  % inherit common parameters
  ds_working.analysisName = sid;   % original subject ID
  ds_working.subjectNames = subj;  % subject ID (in a cell) without any '-'
  ds_working.rootPath     = fullfile(vdir, sid, 'tvsRSA');  % Trial-wise Volume-based searchlight RSA    
  ds_working.maskPath     = fullfile(ds_common.rootPath, 'masks', '[[maskName]].nii');  % prepare masks  
  if ~exist(fullfile(ds_common.rootPath, 'SWAP'), 'dir')
    mkdir(fullfile(ds_common.rootPath, 'SWAP'));
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
  % output working data  
  fout = fullfile(ds_working.rootPath, 'SWAP', sprintf('%s_tvsRSA_working_data.mat', sid));
  save(fout, 'ds_working', 'betas*', 'data_*', '-v7.3');
  clear betas* data_*
  fprintf('Finished the preparation for subject: %s.\n', sid);
end
% searchlight one subject at a time
for j = 1:n
  sid = subjects{j};               % original subject ID
  subj = {strrep(sid, '-', '_')};  % replace '-' by '_' 
  fprintf('Perform trial-wise volume-based searchlight RSA for subject: %s ......\n', sid)  
  % load up working data
  fout = fullfile(ds_working.rootPath, 'SWAP', sprintf('%s_tvsRSA_working_data.mat', sid));
  load(filename);
  % searchlight RSA
  fMRISingleSearchlight(data_betas, data_masks, RDMs_models{i}, betas, ds_working, 0);  % 0: do not save voxel-wise RDMs  
  clear betas* data_*
  fprintf('Finished the trial-wise volume-based searchlight RSA for subject: %s.\n', sid) 
end
%% ---------------------------
