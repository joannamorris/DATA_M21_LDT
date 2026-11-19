%% =========================================================================
%  ERP_measure_amp.m
%
%  Measures baseline-adjusted mean ERP amplitude across a specified time
%  window for selected bins, channels, and subjects.
%
%  Expected directory structure:
%
%    PROJECT_ROOT/
%    └── DATA/
%        ├── S101/
%        ├── S102/
%        └── ...
%
%  Subject ERP filenames are assumed to follow:
%
%    SubjID[_TaskID][_Extension].erp
%
%  Output is a long-format CSV suitable for R/lme4.
%
%  Supported recording configurations:
%    hc = Hampshire College montage: scalp channels 1-27
%    pc = Providence College montage: scalp channels 1-31
%
%  Requires: EEGLAB with ERPLAB
% =========================================================================

clear; clc;

%% Start EEGLAB / ERPLAB
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
ALLERP     = buildERPstruct([]);
CURRENTERP = 0;

%% -------------------------------------------------------------------------
%  Collect parameters
% -------------------------------------------------------------------------

prompt = { ...
    'StudyID (used in output filename; leave blank if none):', ...
    'TaskID (leave blank if none):', ...
    'Data collection location (hc | pc):', ...
    'Subject list file:', ...
    'ERP filename extension after subject/task IDs (leave blank if none):', ...
    'Bins to measure (e.g. 9:10 or [9 10]):', ...
    'Measurement window in ms (e.g. [300 500]):', ...
    'Baseline window in ms (e.g. [-200 0]):'};

dlgtitle = 'ERP amplitude measurement parameters';
dims     = [1 72];

definput = { ...
    '', ...
    'LDT', ...
    'hc', ...
    'hc_subjlist_AB.txt', ...
    'BF_binop', ...
    '[9:12, 17:20]', ...
    '[200 300]', ...
    '[-200 0]'};

my_input = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(my_input)
    error('Amplitude measurement cancelled by user.');
end

DIR             = pwd;
studyID         = strtrim(my_input{1});
taskID          = strtrim(my_input{2});
location        = lower(strtrim(my_input{3}));
subj_list_fname = strtrim(my_input{4});
erp_ext         = strtrim(my_input{5});

%% -------------------------------------------------------------------------
%  Parse and validate numeric inputs
% -------------------------------------------------------------------------

try
    bins     = str2num(strtrim(my_input{6})); %#ok<ST2NM>
    interval = str2num(strtrim(my_input{7})); %#ok<ST2NM>
    baseline = str2num(strtrim(my_input{8})); %#ok<ST2NM>
catch ME
    error('Could not parse numeric inputs: %s', ME.message);
end

if isempty(bins) || ~isnumeric(bins) || any(bins < 1) || any(mod(bins,1) ~= 0)
    error('Bin numbers must be positive integers.');
end

if numel(interval) ~= 2 || interval(1) >= interval(2)
    error('Measurement window must contain [start end] with start < end.');
end

if numel(baseline) ~= 2 || baseline(1) >= baseline(2)
    error('Baseline window must contain [start end] with start < end.');
end

if ~isfile(subj_list_fname)
    error('Subject list file not found: %s', subj_list_fname);
end

%% -------------------------------------------------------------------------
%  Define scalp channels from recording configuration
% -------------------------------------------------------------------------

switch location
    case 'hc'
        channels = 1:27;

    case 'pc'
        channels = 1:31;

    otherwise
        error('Unknown recording location "%s". Use "hc" or "pc".', ...
            location);
end

%% -------------------------------------------------------------------------
%  Load subject list
% -------------------------------------------------------------------------

subj_list = importdata(subj_list_fname);

if ischar(subj_list)
    subj_list = cellstr(subj_list);
end

nsubj = length(subj_list);

if nsubj == 0
    error('Subject list is empty: %s', subj_list_fname);
end

%% -------------------------------------------------------------------------
%  Build filename suffixes
% -------------------------------------------------------------------------

if isempty(taskID)
    task_pfx = '';
else
    task_pfx = ['_' taskID];
end

if isempty(erp_ext)
    erp_sfx = '';
else
    erp_sfx = ['_' erp_ext];
end

%% -------------------------------------------------------------------------
%  Build output filename
% -------------------------------------------------------------------------

fmt = @(x) strrep(num2str(x), '-', 'n');

name_parts = {};

if ~isempty(studyID)
    name_parts{end+1} = studyID;
end

if ~isempty(taskID)
    name_parts{end+1} = taskID;
end

if isempty(name_parts)
    output_prefix = 'ERP';
else
    output_prefix = strjoin(name_parts, '_');
end

output_fname = fullfile( ...
    DIR, ...
    sprintf('%s_mea_%s_%s_bl_%s_%s.csv', ...
        output_prefix, ...
        fmt(interval(1)), ...
        fmt(interval(2)), ...
        fmt(baseline(1)), ...
        fmt(baseline(2))));

%% -------------------------------------------------------------------------
%  Avoid overwriting a pre-existing output file
%
%  output_fname is built only from the measurement/baseline windows, so
%  re-running with a different subject list (but the same windows) would
%  otherwise silently overwrite a previous run's output. If a file
%  already exists at that path, append a timestamp to keep this run's
%  output separate.
% -------------------------------------------------------------------------

if isfile(output_fname)

    [out_dir, out_base, out_ext] = fileparts(output_fname);
    run_timestamp = datestr(now, 'yyyymmdd_HHMMSS'); %#ok<TNOW1,DATST>

    original_fname = output_fname;
    output_fname = fullfile(out_dir, ...
        sprintf('%s_%s%s', out_base, run_timestamp, out_ext));

    fprintf(['\nNote: output file already exists, so this run will not ' ...
        'overwrite it:\n  %s\nWriting this run to:\n  %s\n'], ...
        original_fname, output_fname);
end

erp_list_fname = fullfile(DIR, 'erp_file_list.txt');

fprintf('\n========================================\n');
fprintf('ERP amplitude measurement setup\n');
fprintf('========================================\n');
fprintf('Location: %s\n', location);
fprintf('Scalp channels: %s\n', mat2str(channels));
fprintf('Bins: %s\n', mat2str(bins));
fprintf('Measurement window: [%g %g] ms\n', interval(1), interval(2));
fprintf('Baseline: [%g %g] ms\n', baseline(1), baseline(2));
fprintf('Output: %s\n\n', output_fname);

%% -------------------------------------------------------------------------
%  Build ERP file list
% -------------------------------------------------------------------------

fid = fopen(erp_list_fname, 'w');

if fid == -1
    error('Cannot open ERP file list for writing: %s', erp_list_fname);
end

valid_files      = {};
missing_subjects = {};

for s = 1:nsubj

    subjID      = strtrim(subj_list{s});
    subject_DIR = fullfile(DIR, 'DATA', subjID);

    fname = [subjID task_pfx erp_sfx '.erp'];
    fpath = fullfile(subject_DIR, fname);

    if ~isfile(fpath)

        fprintf(' *** WARNING: %s not found — skipping %s ***\n', ...
            fpath, subjID);

        missing_subjects{end+1} = subjID; %#ok<AGROW>

    else

        fprintf(fid, '%s\n', fpath);
        valid_files{end+1} = fpath; %#ok<AGROW>

    end
end

fclose(fid);

if isempty(valid_files)
    error('No valid ERP files found.');
end

fprintf('\nFound %d of %d requested ERP files.\n', ...
    length(valid_files), nsubj);

if ~isempty(missing_subjects)
    fprintf('Missing/skipped subjects: %s\n', ...
        strjoin(missing_subjects, ', '));
end

%% -------------------------------------------------------------------------
%  Measure mean amplitude
% -------------------------------------------------------------------------

fprintf('\nMeasuring mean amplitude...\n');

try

    ALLERP = pop_geterpvalues( ...
        erp_list_fname, ...
        interval, ...
        bins, ...
        channels, ...
        'Baseline',     baseline, ...
        'Binlabel',     'on', ...
        'FileFormat',   'long', ...
        'Filename',     output_fname, ...
        'Fracreplace',  'NaN', ...
        'InterpFactor', 1, ...
        'Measure',      'meanbl', ...
        'Mlabel',       'mean_amp', ...
        'Resolution',   3);

catch ME

    error('pop_geterpvalues failed: %s', ME.message);

end

fprintf('\nAmplitude measurement complete.\n');
fprintf('ERP files included: %d\n', length(valid_files));

%% -------------------------------------------------------------------------
%  Locate the file pop_geterpvalues actually wrote
%
%  pop_geterpvalues silently forces a .txt extension on 'long' format
%  output even when 'Filename' is given with a .csv extension, so the
%  file actually written may sit at the .txt sibling path rather than
%  output_fname itself. Detect this and rename it to the intended .csv
%  path before doing anything else.
% -------------------------------------------------------------------------

[out_dir, out_base, ~] = fileparts(output_fname);
alt_txt_fname = fullfile(out_dir, [out_base '.txt']);

if isfile(output_fname)
    % pop_geterpvalues respected the .csv filename as given

elseif isfile(alt_txt_fname)

    fprintf(['\nNote: pop_geterpvalues wrote output as .txt; ' ...
        'renaming to .csv:\n  %s\n  -> %s\n'], alt_txt_fname, output_fname);

    movefile(alt_txt_fname, output_fname);

else
    error(['Could not locate the file written by pop_geterpvalues.\n' ...
        'Checked:\n  %s\n  %s'], output_fname, alt_txt_fname);
end

%% -------------------------------------------------------------------------
%  Clean output: enforce true comma-separated CSV, strip leading/trailing
%  whitespace from every field
%
%  pop_geterpvalues writes 'long' format output as a whitespace/tab-padded
%  text file, so this step re-parses the raw output and rewrites it as a
%  proper comma-delimited file with no leading or trailing spaces around
%  any value.
% -------------------------------------------------------------------------

fprintf('\nCleaning output formatting (CSV, trimmed fields)...\n');

fid_in = fopen(output_fname, 'r');

if fid_in == -1
    error('Could not reopen output file for cleanup: %s', output_fname);
end

raw_lines = {};
line = fgetl(fid_in);

while ischar(line)
    raw_lines{end+1} = line; %#ok<AGROW>
    line = fgetl(fid_in);
end

fclose(fid_in);

fid_out = fopen(output_fname, 'w');

if fid_out == -1
    error('Could not reopen output file for writing cleaned data: %s', ...
        output_fname);
end

for i = 1:length(raw_lines)

    this_line = strtrim(raw_lines{i});

    if isempty(this_line)
        continue
    end

    % Split on any run of whitespace (spaces and/or tabs), then trim each
    % field individually before re-joining with commas
    fields = strsplit(this_line);
    fields = strtrim(fields);

    fprintf(fid_out, '%s\n', strjoin(fields, ','));

end

fclose(fid_out);

fprintf('Saved (cleaned CSV): %s\n', output_fname);
