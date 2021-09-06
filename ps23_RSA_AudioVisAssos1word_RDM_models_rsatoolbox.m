%% ---------------------------
%% [script name] ps23_RSA_AudioVisAssos1word_RDM_models_rsatoolbox.m 
%%
%% SCRIPT to create the RDM models for the representational similarity analysis for the AudioVisAssos1word task. The RDM
%% models are based on multiple situations that will be tested using RSA.
%%
%% By Shuai Wang, [date] 2021-09-03
%%
%% ---------------------------
%% Notes: 1. The condition order for models is WA, PA, WV, PV. 
%%        2. Two experimental factors (Modality x Lexicon), result in 15 models.
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
mdir = '/media/wang/BON/Projects/CP00';  % do this ps locally to examine the RDM models
ddir = fullfile(mdir, 'AudioVisAsso', 'results');
vdir = fullfile(ddir, 'multivariate');
% task parameters
conditions = {'WA', 'PA', 'WV', 'PV'};
ncon = length(conditions);  % number of conditions
ntrl = 60;                  % number of trials per condition
%% ---------------------------

%% create conceptual (condition-wise) models 
% amodal and lexicon sensitive 
models_conditions.amodal_lexico = [0 1 0 1;
                                   1 0 1 0;
                                   0 1 0 1;
                                   1 0 1 0];
% amodal and word sensitive                 
models_conditions.amodal_lexiwd = [0 1 0 1;
                                   1 1 1 1;
                                   0 1 0 1;
                                   1 1 1 1];
% amodal and pseudoword sensitive (actually nonsense...)
models_conditions.amodal_lexipw = [1 1 1 1;
                                   1 0 1 0;
                                   1 1 1 1;
                                   1 0 1 0];
% unimodal auditory and lexicon sensitive 
models_conditions.audmod_lexico = [0 1 2 2;
                                   1 0 2 2;
                                   2 2 2 2;
                                   2 2 2 2];
% unimodal auditory and word sensitive                                     
models_conditions.audmod_lexiwd = [0 1 2 2;
                                   1 1 2 2;
                                   2 2 2 2;
                                   2 2 2 2];
% unimodal auditory and pseudoword sensitive                                     
models_conditions.audmod_lexipw = [1 1 2 2;
                                   1 0 2 2;
                                   2 2 2 2;
                                   2 2 2 2];      
% unimodal auditory and lexicon insensitive
models_conditions.audmod_nolexi = [0 0 1 1;
                                   0 0 1 1;
                                   1 1 1 1;
                                   1 1 1 1];
% unimodal visual and lexicon sensitive
models_conditions.vismod_lexico = [2 2 2 2;
                                   2 2 2 2;
                                   2 2 0 1;
                                   2 2 1 0];
% unimodal visual and word sensitive        
models_conditions.vismod_lexiwd = [2 2 2 2;
                                   2 2 2 2;
                                   2 2 0 1;
                                   2 2 1 1];
% unimodal visual and pseudoword sensitive
models_conditions.vismod_lexipw = [2 2 2 2;
                                   2 2 2 2;
                                   2 2 1 1;
                                   2 2 1 0];
% unimodal visual and lexicon insensitive
models_conditions.vismod_nolexi = [1 1 1 1;
                                   1 1 1 1;
                                   1 1 0 0;
                                   1 1 0 0];
% multimodal and lexicon sensitive
models_conditions.mmodal_lexico = [0 1 2 2;
                                   1 0 2 2;
                                   2 2 0 1;
                                   2 2 1 0];
% multimodal and word sensitive
models_conditions.mmodal_lexiwd = [0 1 2 2;
                                   1 1 2 2;
                                   2 2 0 1;
                                   2 2 1 1];
% multimodal and pseudoword sensitive
models_conditions.mmodal_lexipw = [1 1 2 2;
                                   1 0 2 2;
                                   2 2 1 1;
                                   2 2 1 0];
% multimodal and lexicon insensitive
models_conditions.mmodal_nolexi = [0 0 1 1;
                                   0 0 1 1;
                                   1 1 0 0;
                                   1 1 0 0];
%% ---------------------------

%% create trial-wise RDM models for RSA
% convert conceptual models to trial-wise models
models_names = fieldnames(models_conditions);
for i = 1:length(models_names)
  model_name = models_names{i};
  model_this = kron(models_conditions.(model_name), ones(ntrl, ntrl));
  model_this(1:ntrl*ncon+1:end) = 0;  % make the diagonal zero
  models_trialwise.(model_name) = model_this;
end
% RSA settings
ds_models.rootPath       = vdir;
ds_models.analysisName   = 'RSA_AudioVisAssos1word_WAPAWVPV';
%ds_models.conditionLabels = repelem(conditions, ntrl);
%ds_models.conditionColours = [repmat([1 0.5 0], ntrl, 1); repmat([1 0 0], ntrl, 1); repmat([0 1 0], ntrl, 1); repmat([0 0.5 1], ntrl, 1)];
ds_models.displayFigures = false;
ds_models.saveFiguresJpg = true; 
% construct RDM models for RSA
models_trialwise_RDMs = constructModelRDMs(models_trialwise, ds_models);
figureRDMs(models_trialwise_RDMs, ds_models);
%MDSConditions(models_trialwise_RDMs, ds_models, struct('alternativeConditionLabels', cell(ntrl*ncon, 1)));
% reorder the models to be used in RSA : new order of conditions is WA WV PA PV
ds_models.analysisName   = 'RSA_AudioVisAssos1word_WAWVPAPV';
models_neworder = [1:ntrl, ...           % WA
                   ntrl*2+1:ntrl*3, ...  % WV
                   ntrl+1:ntrl*2, ...    % PA
                   ntrl*3+1:ntrl*4];     % PV
models_trialwise_beta = structfun(@(x) x(models_neworder, models_neworder), models_trialwise, 'UniformOutput', 0);
models_trialwise_beta_RDMs = constructModelRDMs(models_trialwise_beta, ds_models);
figureRDMs(models_trialwise_beta_RDMs, ds_models);
% output models
fout = fullfile(vdir, 'RSA_AudioVisAssos1word_models-design.mat');
save(fout);
%% ---------------------------