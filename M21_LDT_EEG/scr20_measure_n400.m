%% Clear memory and the command window
clear;
clc;

%% Load eeglab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% Initialize the ALLERP structure and CURRENTERP
ALLERP     = buildERPstruct([]);
CURRENTERP = 0;

%% Set up variables holding key values about the files
prompt         = {'Enter StudyID:',...
                  'Enter TaskID:',...
                  'Enter the data collection location:',...
                  'Enter name of subject list file:',...
                  'Enter the part of the file names that comes after the subject and task IDs, including the underscores. If there are no filename extensions, leave the box empty:',...
                  'Enter the numbers of the bins to measure',...
                  'Enter the name of the output file containing the measured values:'};  
dlgtitle       = 'Input';                         
dims           = [1 70];                          
definput       = {'M21','LDT','hc','subjlist1_all.txt', 'diff_waves','1:15', 'm21_ldt_mea_300500_050050_1.csv'};  
my_input       = inputdlg(prompt,dlgtitle,dims,definput);  

study          = my_input{1};
if isempty(my_input{2})                         % which task
    taskID     = '';
else
    taskID     = ['_' my_input{2}];
end

location       = my_input{3};
DIR            = pwd;
subj_list      = importdata(my_input{4}); 
if isempty(my_input{5})   
    f_string = '';
else
    f_string  = ['_' my_input{5}];
end


nsubj          = length(subj_list); 
output_fname   = [DIR filesep my_input{7}];


if strcmp(location, 'hc')
    chan_num = 27;
else
    chan_num = 31;
end


% Convert input to integer array
if ~isempty(my_input{6})  % Check if input is not empty
    bins = eval(my_input{6});  % Evaluate the string to get the array
end

%% Set up variables holding key values about the parameters for measurement
interval       = [300 500];
baseline       = [-50 50];
channels       = 1:chan_num;
erp_list_fname = [DIR filesep 'erp_file_list.txt'];  % Text file to hold the list of .erp files
format         = 'long';

%% Initialize the list to hold ERP file paths
erp_file_list = {};  % Empty cell array to hold .erp file paths

%% Load the ERPsets, make them available in the ERPLAB GUI, and store the file paths
fileID = fopen(erp_list_fname, 'w');  % Open text file for writing
for subject = 1:nsubj
    subjID = subj_list{subject};
    subject_DIR = [DIR filesep subjID];
    fname       = [subjID taskID f_string '.erp'];
    
    %% Check to make sure the dataset file exists
    if exist([subject_DIR filesep fname], 'file') <= 0
        fprintf('\n *** WARNING: %s does not exist *** \n', [subject_DIR filesep fname]);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else 
        fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);
        
        % Load ERP file
        % ERP = pop_loaderp('filename', fname, 'filepath', subject_DIR);
        
        % Store the file path in the list for later processing
        erp_file_path = [subject_DIR filesep fname];
        fprintf(fileID, '%s\n', erp_file_path);  % Write the file path to the text file
    end
end
fclose(fileID);  % Close the text file after writing

%% Use the list of file paths stored in the text file to measure amplitude of ERPs between 150 and 250 ms
ALLERP = pop_geterpvalues(erp_list_fname, ...
                          interval, bins, channels, ...
                          'Baseline', baseline, ...
                          'Binlabel', 'on', ...
                          'FileFormat', format, ...
                          'Filename', output_fname, ...
                          'Fracreplace', 'NaN', ...
                          'InterpFactor', 1, ...
                          'Measure', 'meanbl', ...
                          'Mlabel', 'mean_amp', ...
                          'Resolution', 3);
