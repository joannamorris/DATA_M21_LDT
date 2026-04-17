% This script creates a grand average erp file 

%% Clear memory and the command window
clear;
clc;

%% Load eeglab, erplab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
ALLERP = buildERPstruct([]);
CURRENTERP = 0;  % Initialize CURRENTERP

%% Set up variables holding key values 
prompt   = {'Enter StudyID:',...
            'Enter TaskID:',...
            'Enter name of subject list file:',...
            'Enter the part of the file names that comes after the subject and task IDs. If there are no filename extensions, leave the box empty:',...
            'What do you want to call your grand average file?'};
dlgtitle = 'Input';
dims     = [1 70];
definput = {'M21','LDT','subjlist1_lo_ortho.txt','diff_waves','M21_LDT_GA1_lo_ortho' };
my_input = inputdlg(prompt, dlgtitle, dims, definput);

DIR            = pwd;
studyID        = my_input{1};
taskID         = my_input{2};
subj_list      = importdata(my_input{3});
f_string       = ['_' my_input{4}];
nsubj          = length(subj_list);
ga_name        = my_input{5};

%% Load the ERPsets and make them available in the ERPLAB GUI
valid_erpsets = [];  % List of indices for valid ERP sets

for subject = 1:nsubj
    subjID = subj_list{subject};
    Subject_DIR = [DIR filesep subjID];

    % Handle the case where taskID is empty
    if isempty(taskID)
        fname = [subjID f_string '.erp'];
        taskLabel = '';
    else
        fname = [subjID '_' taskID f_string '.erp'];
        taskLabel = ['_' taskID];
    end

    %% Check to make sure the dataset file exists
    if exist([Subject_DIR filesep fname], 'file') <= 0
        fprintf('\n *** WARNING: %s does not exist *** \n', [Subject_DIR filesep fname]);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else 
        %% Load erpset
        fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);
        ERP = pop_loaderp('filename', fname, 'filepath', Subject_DIR);
        CURRENTERP = CURRENTERP + 1;
        ALLERP(CURRENTERP) = ERP;
        valid_erpsets = [valid_erpsets, CURRENTERP];  % Add to valid ERP sets list
    end
    erplab redraw;
end

%% Create a grand average ERP waveform from the files listed in ALLERP
ERP = pop_gaverager(ALLERP , ...
                    'Erpsets', valid_erpsets, ...
                    'Criterion', 100, ...
                    'SEM', 'on', ...
                    'Warning', 'on', ...
                    'Weighted', 'on');
ERP = pop_savemyerp(ERP, ...
                    'erpname', ga_name, ...
                    'filename', [ga_name '.erp'], ...
                    'filepath', DIR , ...
                    'Warning', 'on');
CURRENTERP = CURRENTERP + 1;
ALLERP(CURRENTERP) = ERP;  
erplab redraw;
