%% Clear memory and the command window
clear;
clc;

%% Load eeglab, erplab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
ALLERP = buildERPstruct([]);
%% Set up variables holding key values 
    
% Dialog box to get info about script variables 
prompt    = {'Enter name of subject list file:'};
dlgtitle  =  'Input';
dims      = [1 70];
definput  = {'subjlist.txt'};
my_input  = inputdlg(prompt,dlgtitle,dims,definput);

DIR       = pwd;                       % Current folder (where the script should be located)
subj_list = importdata(my_input{1});   % list of subject ids
nsubj     = length(subj_list);         % number of subjects


%% Load the  ERPsets and make them available in the ERPLAB GUI

for subject = 1:nsubj
    subjID = subj_list{subject};
    subject_DIR = [DIR filesep subjID];
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);

     %% Check to make sure the dataset file exists
    if (exist([subject_DIR filesep subjID '.erp' ], 'file')<=0)
        fprintf('\n *** WARNING: %s does not exist *** \n', fname);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else 
        
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);
    
    Subject_DIR = [DIR filesep subjID];
    fname = [subjID '.erp'];
    ERP = pop_loaderp('filename', fname, 'filepath', Subject_DIR);
	CURRENTERP = CURRENTERP + 1;
    ALLERP(CURRENTERP) = ERP;  

    end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects
erplab redraw;