%% Clear memory and the command window
clear;
clc;

%% Load eeglab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
ALLERP = buildERPstruct([]);

%% Set up variables holding key values 

%  Dialog box to get info about script variables 
prompt   = {'Enter StudyID:',...
            'Enter TaskID:',...
            'Enter name of subject list file:',...
            'Enter the part of the file names that comes after the subject and task IDs, including the underscores. If there are no filename extensions, leave the box empty:'};
dlgtitle =  'Input';
dims     = [1 70];
definput = {'M21','VSL2','subjlist1_interp.txt','_TRM_FLT_RSP_REF_ELS_BIN_ICA_INT_EPC_ARJ'};
my_input   = inputdlg(prompt,dlgtitle,dims,definput);
DIR            = pwd;                         % Current folder (where the script should be located)
studyID        = my_input{1};                 % which study

if isempty(my_input{2})                         % which task
    taskID     = '';
else
    taskID     = ['_' my_input{2}];
end

if isempty(my_input{4})
    f_string = '';
else
    f_string  = ['_' my_input{4}];
end

subj_list      = importdata(my_input{3});     % `list of subject ids
nsubj          = length(subj_list);           % number of subjects
  
%% Load the  eegsets and make them available in the EEGLAB GUI

for subject = 1:nsubj
    subjID = subj_list{subject};
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);
    
    subject_DIR = [DIR filesep subjID];

    fname = [subjID taskID f_string];  
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

       
    
        %%  %% Average
         % Only good trials.  Include standard deviation.  Save to disk.            
            
            fprintf('\n\n\n**** %s: Averaging ****\n\n\n', fname_set);

            ERP         = pop_averager( EEG, ...
                                       'Criterion'      , 'good', ...
                                       'ExcludeBoundary', 'on', ...
                                       'SEM'            , 'on');
        ERP.erpname = [subjID taskID];  % name for erpset menu
            pop_savemyerp(ERP,... 
                           'erpname', ERP.erpname,...
                              'filename', [ERP.erpname '.erp'],...
                           'filepath', subject_DIR, ...
                           'warning', 'off');

           
            CURRENTERP         = CURRENTERP + 1;
            ALLERP(CURRENTERP) = ERP;
            
            eeglab redraw;
            erplab redraw;




    end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects

