%% Clear memory and the command window
clear;
clc;

%% Load eeglab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% Set up variables holding key values 

% Dialog box to get info about script variables 
prompt   = {'Enter StudyID (leave blank if none):',...
            'Enter TaskID (leave blank if none):',...
            'Enter datatype (leave blank if none):',...
            'Enter name of subject list file:'};
dlgtitle =  'Input';
dims     = [1 70];
definput = {'M21','LDT','EEG','temp.txt'};
my_input   = inputdlg(prompt,dlgtitle,dims,definput);

DIR            = pwd;                         % Current folder (where the script should be located)
studyID        = my_input{1};                 % which study (may be empty)
taskID         = my_input{2};                 % which task (may be empty)
datatype       = my_input{3};                 % which data type (may be empty)
subj_list      = importdata(my_input{4});     % list of subject ids
nsubj          = length(subj_list);           % number of subjects
  
%% Load the ERPsets and make them available in the ERPLAB GUI

for subject = 1:nsubj
    subjID = subj_list{subject};
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);

    subject_DIR = [DIR filesep subjID];
    
    % Construct filenames based on the presence of studyID, taskID, and datatype
    if isempty(studyID) && isempty(taskID) && isempty(datatype)
        fname_vhdr = [subjID '.vhdr'];
        fname_vmrk = [subjID '.vmrk'];
        fname_eeg  = [subjID '.eeg'];
    elseif isempty(studyID) && isempty(taskID)
        fname_vhdr = [subjID '_' datatype '.vhdr'];
        fname_vmrk = [subjID '_' datatype '.vmrk'];
        fname_eeg  = [subjID '_' datatype '.eeg'];
    elseif isempty(studyID) && isempty(datatype)
        fname_vhdr = [subjID '_' taskID '.vhdr'];
        fname_vmrk = [subjID '_' taskID '.vmrk'];
        fname_eeg  = [subjID '_' taskID '.eeg'];
    elseif isempty(taskID) && isempty(datatype)
        fname_vhdr = [studyID '_' subjID '.vhdr'];
        fname_vmrk = [studyID '_' subjID '.vmrk'];
        fname_eeg  = [studyID '_' subjID '.eeg'];
    elseif isempty(studyID)
        fname_vhdr = [subjID '_' taskID '_' datatype '.vhdr'];
        fname_vmrk = [subjID '_' taskID '_' datatype '.vmrk'];
        fname_eeg  = [subjID '_' taskID '_' datatype '.eeg'];
    elseif isempty(taskID)
        fname_vhdr = [studyID '_' subjID '_' datatype '.vhdr'];
        fname_vmrk = [studyID '_' subjID '_' datatype '.vmrk'];
        fname_eeg  = [studyID '_' subjID '_' datatype '.eeg'];
    elseif isempty(datatype)
        fname_vhdr = [studyID '_' subjID '_' taskID '.vhdr'];
        fname_vmrk = [studyID '_' subjID '_' taskID '.vmrk'];
        fname_eeg  = [studyID '_' subjID '_' taskID '.eeg'];
    else
        fname_vhdr = [studyID '_' subjID '_' taskID '_' datatype '.vhdr'];
        fname_vmrk = [studyID '_' subjID '_' taskID '_' datatype '.vmrk'];
        fname_eeg  = [studyID '_' subjID '_' taskID '_' datatype '.eeg'];
    end
    
    %% Check to make sure all three BV files exist
    if (exist([subject_DIR filesep fname_vhdr], 'file')<=0 || ...
            exist([subject_DIR filesep fname_vmrk], 'file')<=0 || ...          
            exist([subject_DIR filesep fname_eeg], 'file')<=0)
        fprintf('\n *** WARNING: %s does not exist *** \n', fname_vhdr);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else 
         %% Load .set file         
         fprintf('\n\n\n**** %s: Loading vhdr file ****\n\n\n', subj_list{subject});
         EEG = pop_loadbv(subject_DIR, fname_vhdr);
         
         % Adjust the setname based on whether studyID and taskID are empty
         if  isempty(taskID)
             EEG.setname = [subjID];
         else
             EEG.setname = [subjID '_' taskID];
         end
         
         % Save the new .set file
         [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
          eeglab redraw;
    end

end % end of looping through all subjects

erplab redraw;
