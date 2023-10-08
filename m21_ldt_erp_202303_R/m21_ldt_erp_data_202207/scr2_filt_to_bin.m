%% Clear memory and the command window
clear;
clc;

%% Load eeglab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
% ALLERP = buildERPstruct([]);

%% Set up variables holding key values 

%  Dialog box to get info about script variables 
prompt   = {'Enter StudyID:',...
            'Enter TaskID:',...
            'Enter name of subject list file:',...
            'Enter name of bin descriptor file:', ...
            'Enter where the data were collected:',...
            'Enter the part of the file names that comes after the subject and task IDs, including the underscores. If there are no filename extensions, leave the box empty:'};
dlgtitle =  'Input';
dims     = [1 70];
definput = {'M21','LDT','subjlist.txt','M21_LDT_CAT_BDF.txt','reref_eq_brainvision_hampshire.txt',''};
my_input   = inputdlg(prompt,dlgtitle,dims,definput);

DIR            = pwd;                         % Current folder (where the script should be located)
studyID        = my_input{1};                 % which study
task           = my_input{2};                 % which task
subj_list      = importdata(my_input{3});     % list of subject ids
bdf_file       = [DIR filesep my_input{4}];   % bin descriptor file 
reref_file     = [DIR filesep my_input{5}];   % file with reref equations
f_string       = my_input{6};                 % this string allows you to specify which .set file to load
nsubj          = length(subj_list);           % number of subjects
  
%% Load the  ERPsets and make them available in the ERPLAB GUI

for subject = 1:nsubj
    subjID = subj_list{subject};
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);
    
    subject_DIR = [DIR filesep subjID];
    fname       = [subjID '_'  task f_string];     % this string allows you to specify which .set file to load
    fname_set   = [fname '.set'];
    fname_fdt   = [fname '.fdt'];
    
    %% Check to make sure the dataset file exists
    if (exist([subject_DIR filesep fname_set ], 'file')<=0);
        fprintf('\n *** WARNING: %s does not exist *** \n', fname);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else 
        %% Load .set file
        fprintf('\n\n\n**** %s: Loading set file ****\n\n\n', fname_set);
        EEG = pop_loadset(fname_set,  subject_DIR);
        EEG.setname = fname;
       % EEG.datfile = fname_fdt; 
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                               'setname',EEG.setname,...
                                               'gui','off');
        % eeglab redraw;
             
   



        %% Band-pass filter data

        EEG  = pop_basicfilter( EEG,  1:31 ,...
                                    'Boundary', 'boundary', ...
                                    'Cutoff', [ 0.1 30],...
                                    'Design', 'butter',...
                                    'Filter', 'bandpass',...
                                    'Order',  4,...
                                    'RemoveDC', 'on' );
    
        EEG.setname = [fname '_FLT_TRM'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
        % eeglab redraw;


        %% Downsample the data
        EEG = pop_resample( EEG, 200);
        EEG.setname = [fname '_FLT_RSP'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
        % eeglab redraw;

        %% Add the channel locations
            
        EEG = pop_chanedit(EEG, 'lookup','standard-10-5-cap385.elp');
            
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
       % EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath', subject_DIR);
                                 
       % eeglab redraw;

        %% Re-reference
        EEG         = pop_eegchanoperator(EEG, reref_file, 'Saveas', 'off');
        EEG.setname = [fname '_FLT_RSP_REF'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
        % eeglab redraw;

        %% Create event list
          EEG = pop_creabasiceventlist( EEG , ...
                                         'AlphanumericCleaning', 'on'           , ...
                                         'BoundaryNumeric'     , { -99 }        , ...
                                         'BoundaryString'      , { 'boundary' } ,...
                                         'Eventlist', [subject_DIR filesep fname '_ELS.txt']);
          EEG.setname = [fname '_FLT_RSP_REF_ELS'];
          [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
          % eeglab redraw;

        %% Assign Bins

        EEG         = pop_binlister( EEG , ...
                                       'BDF'    , bdf_file, ...
                                       'ExportEL',[subject_DIR filesep fname '_ELS_BIN.txt'],...
                                       'IndexEL', 1     , ...
                                       'SendEL2', 'EEG&Text' , ...
                                       'UpdateEEG', 'on',...
                                       'Voutput', 'EEG' );
        EEG.setname = [fname '_FLT_RSP_REF_ELS_BIN'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
         % eeglab redraw;

          
    end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects

eeglab redraw;
            