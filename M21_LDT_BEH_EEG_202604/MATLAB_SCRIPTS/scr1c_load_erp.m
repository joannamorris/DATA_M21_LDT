%% Clear memory and the command window
clear;
clc;

%% Load eeglab, erplab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
ALLERP = buildERPstruct([]);
%% Set up variables holding key values 
    
% Dialog box to get info about script variables 
prompt    = {'Enter name of subject list file:',...
             'Enter task ID:',...
             'Enter the part of the file names that comes after the subject and task IDs. If there are no filename extensions, leave the box empty:',...
             ''};
dlgtitle  =  'Input';
dims      = [1 70];
definput  = {'subjlist1_interp.txt', 'LDT'};
my_input  = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(my_input{2})                         % which task
    taskID     = '';
else
    taskID     = ['_' my_input{2}];
end

if isempty(my_input{3})
    f_string = '';
else
    f_string  = ['_' my_input{3}];
end
subjlist = importdata(my_input{1});   % list of subject ids
nsubj     = length(subjlist);         % number of subjects

DIR       = pwd;                       % Current folder (where the script should be located)


%% Load the  ERPsets and make them available in the ERPLAB GUI

for subject = 1:nsubj
    subjID = subjlist{subject};
    subject_DIR = [DIR filesep subjID];
    fname = [subjID taskID f_string '.erp'];  % Include taskID if it's not empty

     %% Check to make sure the dataset file exists
    if  exist([subject_DIR filesep fname ], 'file')<=0
        fprintf('\n *** WARNING: %s does not exist *** \n', fname);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else 
        
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);
    
    
    ERP = pop_loaderp('filename', fname, 'filepath', subject_DIR);
	CURRENTERP = CURRENTERP + 1;
    ALLERP(CURRENTERP) = ERP;  

    end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects
erplab redraw;