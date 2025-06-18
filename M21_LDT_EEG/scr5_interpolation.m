% This file requires the the channels to interpolate be in a text file with the
% channels for each subject on a separate line separated by spaces.  It uses the 
% 'pop_erplabInterpolateElectrodes()' function from EEGlab.  

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
            'Enter data collection location:',...            
            'Enter name of subject list file:',...
            'Enter name of the file containing channels to interpolate for each subject:',...
            'Enter the part of the file names that comes after the subject and task IDs. If there are no filename extensions, leave the box empty:'};
dlgtitle =  'Input';
dims     = [1 70];
definput = {'M21','LDT','pc','temp_interp.txt','temp_interp_chan.txt','FLT_RSP_REF_ELS_BIN_ICA'};
my_input   = inputdlg(prompt,dlgtitle,dims,definput);


DIR            = pwd;                         % Current folder (where the script should be located)
studyID        = my_input{1};                 % which study
taskID         = my_input{2};                 % which task
location       = my_input{3}
subj_list      = importdata(my_input{4});     % list of subject ids
f_string       = ['_' my_input{6}];                 % this string allows you to specify which .set file to load
nsubj          = length(subj_list);           % number of subjects

if strcmp(location,'hampshire')
    chan_ignore = [1, 27:33];
else
    chan_ignore = [1 31];
end


% Open the file containing the channels to interpolate
fileID = fopen(my_input{5}, 'r');

% Read the file line by line into a cell array, where each cell contains a numeric array
int_ch = {};

while ~feof(fileID)
    line = fgetl(fileID);  % Read a line from the file
    if ischar(line)  % Check if the line is a string (i.e., not the end of the file)
        int_ch{end+1} = str2num(line);  % Convert the line to a numeric array and store it in the cell array
    end
end

% Close the file
fclose(fileID);

% Display the result
% disp(int_ch);

%% Load the  ERPsets and make them available in the ERPLAB GUI

for subject = 1:nsubj
    subjID = subj_list{subject};
    badchans = int_ch{subject};
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
                                               'gui','off');
        eeglab redraw;
        
        %% interpolate bad channels
        EEG  = pop_erplabInterpolateElectrodes(EEG ,...
                                               'displayEEG', 0,...
                                               'ignoreChannels', [ chan_ignore],...
                                               'interpolationMethod', 'spherical',...
                                               'replaceChannels', [badchans] );
        EEG.setname = [fname '_INT'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,...
                                                 'setname',EEG.setname,...
                                                 'save', [subject_DIR filesep EEG.setname '.set'],...
                                                 'gui','off');
        eeglab redraw;
   
 end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects
