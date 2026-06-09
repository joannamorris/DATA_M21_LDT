% This script conducts ICA for all participants in the "subjlist.txt" file
% It also saves the number of ICA components removed per subject.

%% Clear memory and the command window
clear;
clc;

%% Load eeglab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% Set up variables holding key values 

prompt   = {'Enter StudyID:',...
            'Enter TaskID (leave blank if none):',...
            'Enter data collection location:',...
            'Enter name of subject list file:',...
            'Enter the part of the file name that comes after the subject and task IDs, including the underscores (leave blank if none). :'};
dlgtitle =  'Input';
dims     = [1 70];
definput = {'M21','LDT','hc','hc_subjlist_BA.txt','_FLT_RSP_REF_ELS_BIN'};
my_input   = inputdlg(prompt,dlgtitle,dims,definput);

DIR            = pwd;
studyID        = my_input{1};
taskID         = my_input{2};
location       = my_input{3};
subj_list      = importdata(my_input{4});
f_string       = my_input{5};
nsubj          = length(subj_list);

if strcmp(location, 'hc')
    chan_num = 32;
else
    chan_num = 31;
end

comp_list = chan_num * ones(1, length(subj_list));

%% Set up ICA component removal log

ICA_log = table( ...
    strings(nsubj,1), ...
    strings(nsubj,1), ...
    nan(nsubj,1), ...
    strings(nsubj,1), ...
    'VariableNames', {'Subject','Dataset','N_Removed_ICs','Status'} ...
);

%% Loop through subjects

for subject = 1:nsubj

    subjID = subj_list{subject};
    compnum = comp_list(subject);

    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);

    subject_DIR = [DIR filesep subjID];

    if isempty(taskID)
        fname = [subjID f_string];
    else
        fname = [subjID '_' taskID f_string];
    end

    fname_set = [fname '.set'];
    fname_fdt = [fname '.fdt'];

    ICA_log.Subject(subject) = string(subjID);
    ICA_log.Dataset(subject) = string(fname);

    %% Check to make sure the dataset file exists

    if (exist([subject_DIR filesep fname_set], 'file') <= 0 || ...
        exist([subject_DIR filesep fname_fdt], 'file') <= 0)

        fprintf('\n *** WARNING: %s does not exist *** \n', fname);
        fprintf('\n *** Skip all processing for this subject *** \n\n');

        ICA_log.N_Removed_ICs(subject) = NaN;
        ICA_log.Status(subject) = "file missing";

    else

        %% Load .set file

        fprintf('\n\n\n**** %s: Loading set file ****\n\n\n', fname_set);

        EEG = pop_loadset(fname_set, subject_DIR);
        EEG.setname = fname;
        EEG.datfile = fname_fdt;

        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
            'setname', EEG.setname,...
            'save', [subject_DIR filesep EEG.setname '.set'],...
            'gui', 'off');

        eeglab redraw;

        %% Run ICA

        fprintf('\n\n\n**** %s: Running ICA ****\n\n\n', fname_set);

        EEG = pop_runica(EEG, ...
            'icatype', 'runica', ...
            'extended', 1, ...
            'rndreset', 'yes', ...
            'interrupt', 'on');

        EEG = pop_iclabel(EEG, 'default');

        EEG = pop_icflag(EEG, ...
            [NaN NaN; ...
             0.9 1; ...
             0.6 1; ...
             NaN NaN; ...
             0.9 1; ...
             NaN NaN; ...
             NaN NaN]);

        %% Count rejected ICA components BEFORE removing them

        rejected_ICs = find(EEG.reject.gcompreject);
        n_removed = length(rejected_ICs);

        ICA_log.N_Removed_ICs(subject) = n_removed;
        ICA_log.Status(subject) = "processed";

        fprintf('\nSubject %s: %d ICA components marked for removal\n', ...
            subjID, n_removed);

        pop_selectcomps(EEG, 1:compnum);

        EEG = pop_subcomp(EEG, rejected_ICs, 0);

        EEG.setname = [fname '_ICA'];

        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
            'setname', EEG.setname,...
            'save', [subject_DIR filesep EEG.setname '.set'],...
            'gui', 'off');

        eeglab redraw;

    end

end

%% Save ICA component removal log

outname = [studyID '_' taskID '_ICA_components_removed_by_subject.csv'];

% If taskID is blank, avoid double underscores or awkward filename
if isempty(taskID)
    outname = [studyID '_ICA_components_removed_by_subject.csv'];
end

writetable(ICA_log, [DIR filesep outname]);

fprintf('\nSaved ICA component removal log to:\n%s\n', ...
    [DIR filesep outname]);

%% Close non-EEGLAB figures

figHandles = findall(0, 'Type', 'figure');

for i = 1:length(figHandles)

    figName = get(figHandles(i), 'Name');

    if ~contains(figName, 'EEGLAB')
        close(figHandles(i));
    end

end