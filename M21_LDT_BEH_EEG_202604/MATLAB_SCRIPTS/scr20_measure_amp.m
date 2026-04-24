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
                  'Enter the numbers of the bins to measure:',...
                  'Enter the measurement window in ms (e.g. [300 500]):',...
                  'Enter the baseline correction window in ms (e.g. [-200 0]):'};
dlgtitle       = 'Input';
dims           = [1 70];
definput       = {'M21', '', 'pc', 'subjlist1_all.txt', 'diff_waves', '9:10', '[300 500]', '[-200 0]'};
my_input       = inputdlg(prompt, dlgtitle, dims, definput);

%% Check that the user did not cancel the dialog
if isempty(my_input)
    error('User cancelled input dialog. Exiting script.');
end

%% Parse and validate inputs
study    = strtrim(my_input{1});
taskID   = strtrim(my_input{2});
location = strtrim(my_input{3});
subj_list_fname = strtrim(my_input{4});
erp_ext  = strtrim(my_input{5});

% Validate required fields
if isempty(study)
    error('StudyID cannot be empty.');
end
if isempty(location)
    error('Data collection location cannot be empty.');
end
if isempty(subj_list_fname)
    error('Subject list filename cannot be empty.');
end

% Load subject list with error checking
if ~isfile(subj_list_fname)
    error('Subject list file "%s" not found in the current directory.', subj_list_fname);
end
subj_list = importdata(subj_list_fname);
if isempty(subj_list)
    error('Subject list file "%s" is empty.', subj_list_fname);
end

DIR   = pwd;
nsubj = length(subj_list);

% Validate and parse bin numbers
bin_str = strtrim(my_input{6});
if isempty(bin_str)
    error('Bin numbers cannot be empty.');
end
try
    bins = eval(bin_str);
catch
    error('Could not parse bin numbers from "%s". Use a valid MATLAB expression (e.g. 9:10 or [9 10]).', bin_str);
end
if ~isnumeric(bins) || any(bins < 1) || any(bins ~= floor(bins))
    error('Bin numbers must be positive integers.');
end

% Validate and parse measurement window
interval_str = strtrim(my_input{7});
if isempty(interval_str)
    error('Measurement window cannot be empty.');
end
try
    interval = eval(interval_str);
catch
    error('Could not parse measurement window from "%s". Use a format like [300 500].', interval_str);
end
if ~isnumeric(interval) || numel(interval) ~= 2 || interval(1) >= interval(2)
    error('Measurement window must be two numbers [start end] where start < end (e.g. [300 500]).');
end

% Validate and parse baseline window
baseline_str = strtrim(my_input{8});
if isempty(baseline_str)
    error('Baseline correction window cannot be empty.');
end
try
    baseline = eval(baseline_str);
catch
    error('Could not parse baseline window from "%s". Use a format like [-200 0].', baseline_str);
end
if ~isnumeric(baseline) || numel(baseline) ~= 2 || baseline(1) >= baseline(2)
    error('Baseline window must be two numbers [start end] where start < end (e.g. [-200 0]).');
end

%% Determine channel count based on location
if strcmpi(location, 'hampshire')
    chan_num = 27;
else
    chan_num = 31;
end
channels = 1:chan_num;

%% Auto-construct output filename from study ID and window parameters
% Format: <studyID>_mea_<intervalStart>_<intervalEnd>_bl_<baselineStart>_<baselineEnd>.csv
% Replace minus signs with 'n' for negative values to keep filename safe
interval_start_str  = strrep(num2str(interval(1)),  '-', 'n');
interval_end_str    = strrep(num2str(interval(2)),  '-', 'n');
baseline_start_str  = strrep(num2str(baseline(1)),  '-', 'n');
baseline_end_str    = strrep(num2str(baseline(2)),  '-', 'n');

output_fname = fullfile(DIR, sprintf('%s_mea_%s_%s_bl_%s_%s.csv', ...
    study, interval_start_str, interval_end_str, ...
    baseline_start_str, baseline_end_str));

fprintf('\nOutput file will be saved as:\n  %s\n', output_fname);

%% Other fixed parameters
erp_list_fname = fullfile(DIR, 'erp_file_list.txt');
format         = 'long';

%% Initialize the list to hold ERP file paths
erp_file_list  = {};
missing_files  = {};

%% Load the ERPsets, make them available in the ERPLAB GUI, and store the file paths
fileID = fopen(erp_list_fname, 'w');
if fileID == -1
    error('Could not open ERP file list "%s" for writing. Check folder permissions.', erp_list_fname);
end

for subject = 1:nsubj
    subjID     = strtrim(subj_list{subject});
    subject_DIR = fullfile(DIR, subjID);

    % Construct filename based on presence of taskID and erp_ext
    if ~isempty(taskID) && ~isempty(erp_ext)
        fname = sprintf('%s_%s_%s.erp', subjID, taskID, erp_ext);
    elseif isempty(taskID) && ~isempty(erp_ext)
        fname = sprintf('%s_%s.erp', subjID, erp_ext);
    elseif ~isempty(taskID) && isempty(erp_ext)
        fname = sprintf('%s_%s.erp', subjID, taskID);
    else
        fname = sprintf('%s.erp', subjID);
    end

    full_path = fullfile(subject_DIR, fname);

    if ~isfile(full_path)
        fprintf('\n *** WARNING: %s does not exist ***\n', full_path);
        fprintf(' *** Skipping subject %s ***\n\n', subjID);
        missing_files{end+1} = subjID; %#ok<AGROW>
    else
        fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);
        fprintf(fileID, '%s\n', full_path);
        erp_file_list{end+1} = full_path; %#ok<AGROW>
    end
end
fclose(fileID);

%% Warn if no valid ERP files were found
if isempty(erp_file_list)
    error('No valid ERP files were found. Please check your subject list and file paths.');
end

%% Report any missing subjects before proceeding
if ~isempty(missing_files)
    fprintf('\n*** Summary: ERP files were missing for %d subject(s): %s ***\n\n', ...
        numel(missing_files), strjoin(missing_files, ', '));
end

%% Measure amplitude of ERPs across the specified window
fprintf('\nMeasuring mean amplitude in window [%d %d] ms with baseline [%d %d] ms...\n', ...
    interval(1), interval(2), baseline(1), baseline(2));

try
    ALLERP = pop_geterpvalues(erp_list_fname, ...
                              interval, bins, channels, ...
                              'Baseline',     baseline, ...
                              'Binlabel',     'on', ...
                              'FileFormat',   format, ...
                              'Filename',     output_fname, ...
                              'Fracreplace',  'NaN', ...
                              'InterpFactor', 1, ...
                              'Measure',      'meanbl', ...
                              'Mlabel',       'mean_amp', ...
                              'Resolution',   3);
catch ME
    error('pop_geterpvalues failed with error:\n  %s\nCheck that your bin numbers, channels, and time windows are valid for the loaded ERPsets.', ME.message);
end

fprintf('\nDone. Results saved to:\n  %s\n', output_fname);
