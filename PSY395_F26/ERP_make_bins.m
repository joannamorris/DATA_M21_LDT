%% =========================================================================
%  make_bins.m
%
%  Loads each subject's raw ERPset, applies a set of bin operations (e.g.
%  combining split-repetition bins such as bin3+bin13 into a single
%  condition bin per m21_ldt_bin_operations_BF.txt), and saves the result
%  as a new ERPset with a suffix appended to the erpname/filename.
%
%  Expected directory structure:
%
%    PROJECT_ROOT/
%    └── DATA/
%        ├── S101/
%        ├── S102/
%        └── ...
%
%  Input ERP filenames are assumed to follow:
%
%    SubjID_TaskID.erp        (or SubjID.erp if TaskID is left blank)
%
%  Output ERP filenames follow:
%
%    SubjID[_TaskID]_<appendString>.erp
%
%  Requires: EEGLAB with ERPLAB
% =========================================================================

clear; clc;

%% Load EEGLAB
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% Initialize the ALLERP structure and CURRENTERP
ALLERP     = buildERPstruct([]);
CURRENTERP = 0;

%% -------------------------------------------------------------------------
%  Collect parameters
% -------------------------------------------------------------------------

prompt = { ...
    'Enter StudyID:', ...
    'Enter TaskID:', ...
    'Enter name of subject list file:', ...
    'Enter the name of the file that contains your bin equations:', ...
    'Enter the string to append to the name of the new erp file:'};

dlgtitle = 'Input';
dims     = [1 70];

definput = { ...
    'M21', ...
    'LDT_BF', ...
    'hc_subjlist_AB.txt', ...
    'm21_ldt_bin_operations_BF.txt', ...
    'binop'};

my_input = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(my_input)
    error('make_bins cancelled by user.');
end

study          = strtrim(my_input{1});
taskID         = strtrim(my_input{2});
subj_list_fname = strtrim(my_input{3});
bineq          = strtrim(my_input{4});
append_string  = strtrim(my_input{5});

DIR = pwd;   % Current folder (where the script should be located, and
             % where the subject subfolders and bin equations file live)

%% -------------------------------------------------------------------------
%  Validate inputs before touching any data
% -------------------------------------------------------------------------

if isempty(append_string)
    error(['The string to append to the new erp filename cannot be ' ...
        'empty (it is what distinguishes the output file from the ' ...
        'input file).']);
end

f_string = ['_' append_string];   % suffix applied to OUTPUT files only

if ~isfile(subj_list_fname)
    error('Subject list file not found: %s', subj_list_fname);
end

bineq_path = fullfile(DIR, bineq);

if ~isfile(bineq_path)
    error('Bin equations file not found: %s', bineq_path);
end

subj_list = importdata(subj_list_fname);

% importdata returns a char matrix (not a cell array) when the list has
% only one subject, which would break subj_list{subject} indexing below
if ischar(subj_list)
    subj_list = cellstr(subj_list);
end

nsubj = length(subj_list);

if nsubj == 0
    error('Subject list is empty: %s', subj_list_fname);
end

fprintf('\n========================================\n');
fprintf('make_bins setup\n');
fprintf('========================================\n');
fprintf('Study: %s\n', study);
fprintf('TaskID: %s\n', taskID);
fprintf('Subjects: %d\n', nsubj);
fprintf('Bin equations file: %s\n', bineq_path);
fprintf('Output suffix: %s\n\n', f_string);

%% -------------------------------------------------------------------------
%  Process each subject
% -------------------------------------------------------------------------
%  For each subject:
%    1. Load the raw ERPset (SubjID_TaskID.erp)
%    2. Apply the bin operations in bineq (e.g. combine bin3+bin13 etc.)
%    3. Save the result as a new ERPset with f_string appended
%  Any subject that is missing its input file, or that errors out during
%  loading/binning/saving, is skipped rather than halting the whole run,
%  and is recorded below so a summary can be printed at the end.
% -------------------------------------------------------------------------

processed_subjects = {};
skipped_subjects    = {};   % missing input file
failed_subjects      = {};   % input found but processing errored
backed_up_files       = {};   % pre-existing output files preserved

for subject = 1:nsubj

    subjID      = strtrim(subj_list{subject});
    subject_DIR = fullfile(DIR, 'DATA', subjID);

    % Build the INPUT filename. f_string (the output suffix) must NOT be
    % part of this name -- this is the raw ERPset the script reads in,
    % before any bin operations are applied.
    if isempty(taskID)
        fname     = [subjID '.erp'];   % No taskID in the filename
        taskLabel = '';                % Used when building output names
    else
        fname     = [subjID '_' taskID '.erp'];
        taskLabel = ['_' taskID];
    end

    fpath = fullfile(subject_DIR, fname);

    %% Check to make sure the input ERPset exists
    if ~isfile(fpath)

        fprintf(' *** WARNING: %s not found -- skipping %s ***\n', ...
            fpath, subjID);

        skipped_subjects{end+1} = subjID; %#ok<AGROW>
        continue

    end

    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);

    try

        %% Load the raw ERPset
        ERP = pop_loaderp('filename', fname, 'filepath', subject_DIR);

        CURRENTERP        = CURRENTERP + 1;
        ALLERP(CURRENTERP) = ERP;

        %% Apply bin operations (e.g. combine split-repetition bins)
        % Equations are read from the file named in bineq, which must
        % live directly in DIR (the project root).
        ERP = pop_binoperator(ERP, bineq_path);

        ERP.erpname = [subjID taskLabel f_string];   % name for erpset menu
        out_fname   = [ERP.erpname '.erp'];
        out_fpath   = fullfile(subject_DIR, out_fname);

        %% Prevent silently overwriting a pre-existing output file
        % If a previous run already produced this subject's output file,
        % back it up with a timestamp before writing the new one, rather
        % than letting pop_savemyerp overwrite it unnoticed. The new file
        % is still written under the expected name so downstream scripts
        % that look for SubjID[_TaskID]_<append_string>.erp keep working.
        if isfile(out_fpath)

            run_timestamp = datestr(now, 'yyyymmdd_HHMMSS'); %#ok<TNOW1,DATST>
            [bkp_dir, bkp_base, bkp_ext] = fileparts(out_fpath);
            backup_fpath = fullfile(bkp_dir, ...
                sprintf('%s_backup_%s%s', bkp_base, run_timestamp, bkp_ext));

            fprintf(['Note: %s already exists. Backing up existing ' ...
                'file to:\n  %s\n'], out_fpath, backup_fpath);

            movefile(out_fpath, backup_fpath);
            backed_up_files{end+1} = backup_fpath; %#ok<AGROW>

        end

        %% Save the new (binned) ERPset
        pop_savemyerp(ERP, ...
            'erpname',  ERP.erpname, ...
            'filename', out_fname, ...
            'filepath', subject_DIR, ...
            'warning',  'off');

        % Keep the derived ERP in ALLERP too, so it is visible in the
        % ERPLAB GUI / accessible to functions like pop_gaverager
        CURRENTERP        = CURRENTERP + 1;
        ALLERP(CURRENTERP) = ERP;

        erplab redraw;

        processed_subjects{end+1} = subjID; %#ok<AGROW>

    catch ME

        fprintf(' *** ERROR processing %s: %s ***\n', subjID, ME.message);
        fprintf(' *** Skipping remaining steps for this subject ***\n\n');

        failed_subjects{end+1} = subjID; %#ok<AGROW>

    end

end % end of looping through all subjects

%% -------------------------------------------------------------------------
%  Summary
% -------------------------------------------------------------------------

fprintf('\n========================================\n');
fprintf('make_bins run summary\n');
fprintf('========================================\n');
fprintf('Successfully processed: %d of %d\n', ...
    length(processed_subjects), nsubj);

if ~isempty(skipped_subjects)
    fprintf('Skipped (input file not found): %s\n', ...
        strjoin(skipped_subjects, ', '));
end

if ~isempty(failed_subjects)
    fprintf('Failed during processing: %s\n', strjoin(failed_subjects, ', '));
end

if ~isempty(backed_up_files)
    fprintf('\nExisting output files backed up rather than overwritten:\n');
    for i = 1:length(backed_up_files)
        fprintf('  %s\n', backed_up_files{i});
    end
end

fprintf('\n');
