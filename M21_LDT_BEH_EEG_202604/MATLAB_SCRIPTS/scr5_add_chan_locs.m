
% Clear memory and the command window
clear;
clc;

%% Load eeglab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
% ALLERP = buildERPstruct([]);

%% Set up variables holding key values 

%  Dialog box to get info about script variables 
prompt   = {'Enter StudyID:',...
            'Enter TaskID (leave blank if none):',...
            'Enter name of subject list file:',...
            'Enter the part of the file name that comes after the subject and task IDs, including the underscores (leave blank if none). :',...
            'Where is your eeglab directory located?'};
dlgtitle =  'Input';
dims     = [1 70];
definput = {'M21','LDT','subjlist1_interp.txt','_FLT_RSP_REF_ELS_BIN_ICA','/Users/jmorris/Documents/MATLAB/'};
my_input   = inputdlg(prompt,dlgtitle,dims,definput);

DIR            = pwd;                         % Current folder (where the script should be located)
studyID        = my_input{1};                 % which study
taskID         = my_input{2};                 % which task
subj_list      = importdata(my_input{3});     % list of subject ids
f_string       = my_input{4};                 % this string allows you to specify which .set file to load
eeglab_dir     = my_input{5};
nsubj          = length(subj_list);           % number of subjects


%% Load the  ERPsets and make them available in the ERPLAB GUI

for subject = 1:nsubj
    subjID = subj_list{subject};
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);
    
    subject_DIR = [DIR filesep subjID];
    
    % Handle the case where taskID is empty
    if isempty(taskID)
        fname = [subjID f_string];  % No taskID in the filename
    else
        fname = [subjID '_' taskID f_string];  % Include taskID if it's not empty
    end
    
    fname_set   = [fname '.set'];
    fname_fdt   = [fname '.fdt'];    

    
    %% Check to make sure the dataset file exists
    if (exist([subject_DIR filesep fname_set ], 'file')<=0||...
            exist([subject_DIR filesep fname_fdt ], 'file')<=0);
        fprintf('\n *** WARNING: %s does not exist *** \n', fname);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else 
        %% Load .set file
        fprintf('\n\n\n**** %s: Loading set file ****\n\n\n', fname_set);
        EEG = pop_loadset(fname_set, subject_DIR);
        EEG.setname = fname;
        EEG.datfile = fname_fdt; 
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
        eeglab redraw;

        %% Add the channel locations
        EEG = pop_chanedit(EEG, 'lookup','Standard-10-5-Cap385_witheog.elp');
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
        eeglab redraw;


     end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects
