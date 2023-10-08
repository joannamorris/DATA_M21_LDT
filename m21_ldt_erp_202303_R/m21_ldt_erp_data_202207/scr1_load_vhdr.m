%% Clear memory and the command window
clear;
clc;

%% Load eeglab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
% ALLERP = buildERPstruct([]);

%% Set up variables holding key values 
 

% Dialog box to get info about script variables 
prompt   = {'Enter StudyID:',...
            'Enter TaskID:',...
            'Enter datatype:',...
            'Enter name of subject list file:'};
dlgtitle =  'Input';
dims     = [1 70];
definput = {'M21','LDT','EEG','subjlist.txt',''};
my_input   = inputdlg(prompt,dlgtitle,dims,definput);

    
DIR            = pwd;                         % Current folder (where the script should be located)
studyID        = my_input{1};                 % which study
task           = my_input{2};                 % which task
datatype       = my_input{3};                 % which data type
subj_list      = importdata(my_input{4});     % list of subject ids
nsubj          = length(subj_list);           % number of subjects
  
%% Load the  ERPsets and make them available in the ERPLAB GUI

for subject = 1:nsubj
    subjID = subj_list{subject};
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);

    subject_DIR = [DIR filesep subjID];
    fname_vhdr = [studyID '_' subjID '_' task '_' datatype '.vhdr'];
    fname_vmrk = [studyID '_' subjID '_' task '_' datatype '.vmrk'];
    fname_eeg  = [studyID '_' subjID '_' task '_' datatype '.eeg'];


    %% Check to make sure all three BV files exist
    if (exist([subject_DIR filesep fname_vhdr], 'file')<=0 || ...
            exist([subject_DIR filesep fname_vmrk], 'file')<=0) ||...          
            exist([subject_DIR filesep fname_eeg], 'file')<=0;  
        fprintf('\n *** WARNING: %s does not exist *** \n', fname_vhdr);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else 
         %% Load .vhdr file         
         fprintf('\n\n\n**** %s: Loading vhdr file ****\n\n\n', subj_list{subject});
         EEG = pop_loadbv(subject_DIR, fname_vhdr);
         EEG.setname = [subjID '_' task];
         [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
          eeglab redraw;
             
    end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects

erplab redraw;