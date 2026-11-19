%% =========================================================================
%  ERP_pipeline.m
%  General EEGLAB/ERPLAB preprocessing pipeline:
%  load .set → filter → bad channels → ICA → interpolate → epoch →
%  artifact rejection → average
%
%  Supports two acquisition configurations:
%    hc = Hampshire College montage
%    pc = Providence College montage
%  StudyID, TaskID, subject list, BDF, epoch parameters, and artifact
%  thresholds are supplied at runtime.
%
%  Starting point: subjID_taskID.set  (unfiltered continuous EEG)
%  Expected location: DATA/subjID/subjID_taskID.set
%
%  Prerequisites: create the montage-specific .ced file(s) once:
%    M21_Hampshire_32ch.ced  for Hampshire (hc)
%    M21_PC_31ch.ced         for Providence (pc)
%
%  Outputs
%  -------
%    <studyID>_<taskID>_pipeline_log.txt     — per-subject processing log
%    <studyID>_<taskID>_ICA_log.csv          — ICA components removed per subject
%    <studyID>_<taskID>_removed_channels.txt — bad channels per subject
%    <studyID>_<taskID>_trial_counts.csv     — accepted trials per condition
%    <studyID>_<taskID>_summary_stats.txt    — means/ranges for Methods section
%
%  Requires: EEGLAB with ERPLAB plug-in, ICLabel plug-in
%  Tested with: EEGLAB 2024.x, ERPLAB 10.x
% =========================================================================

%% -------------------------------------------------------------------------
%  0. Housekeeping
% -------------------------------------------------------------------------
clear; clc;
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
ALLERP     = buildERPstruct([]);
CURRENTERP = 0;

%% -------------------------------------------------------------------------
%  1. Single dialog — collect all parameters up front
% -------------------------------------------------------------------------
prompt = { ...
    'StudyID:', ...
    'TaskID (leave blank if none):', ...
    'Data collection location (pc | hc):', ...
    'Subject list file (one ID per line):', ...
    'Bin descriptor file (BDF, full filename):', ...
    'Bin structure label (optional — leave blank unless running multiple bin structures, e.g. FS or BF):', ...
    'Downsample to (Hz):', ...
    'Epoch window (ms), e.g.  -200 1000:', ...
    'Artifact-rejection threshold (µV), e.g.  100:', ...
    'Artifact-rejection window (ms), e.g.  -100 600:', ...
    'EEGLAB directory (folder containing sample_locs/):'};
dlgtitle = 'Pipeline parameters';
dims     = [1 72];
definput = { ...
    '', 'LDT', 'hc', 'hc_subjlist_BA.txt', 'M21_LDT_BDF_B_BF_resid.txt', 'BF', ...
    '200', '-200 1000', '100', '-100 600', '/Users/jmorris/Documents/MATLAB/eeglab2024.2'};
my_input = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(my_input)
    error('Pipeline cancelled by user.');
end

DIR      = pwd;
studyID  = strtrim(my_input{1});
taskID   = strtrim(my_input{2});
location = lower(strtrim(my_input{3}));
binID    = strtrim(my_input{6});
srate    = str2double(my_input{7});

epoch_vec  = str2num(my_input{8});   %#ok<ST2NM>
arj_thresh = str2double(my_input{9});
arj_win    = str2num(my_input{10});  %#ok<ST2NM>
eeglab_dir = strtrim(my_input{11});




if numel(epoch_vec) ~= 2 || numel(arj_win) ~= 2
    error('Epoch window and artifact window must each be two numbers.');
end
if isnan(srate) || srate <= 0
    error('Downsample rate must be a positive number.');
end

subj_list = importdata(strtrim(my_input{4}));
nsubj     = length(subj_list);
bdf_file  = fullfile(DIR, strtrim(my_input{5}));

if ~isfile(bdf_file)
    error('Bin descriptor file not found: %s', bdf_file);
end

%% Location-dependent settings

if strcmp(location, 'hc')

    % Hampshire College:
    % 27 scalp EEG + 5 mastoid/EOG = 32 total channels
    chan_num = 32;

    chan_locs_file = fullfile( ...
        eeglab_dir, ...
        'sample_locs', ...
        'M21_Hampshire_32ch.ced');

    reref_file = fullfile( ...
        DIR, ...
        'reref_eq_brainvision_hampshire.txt');

    scalp_idx    = 1:27;
    nonscalp_idx = 28:33;   % Mastoid R/L, HEOG R/L, VEOG L, HEOG (created during re-referencing)

elseif strcmp(location, 'pc')

    % Providence College:
    % 31 scalp EEG channels, all with real 10-10 system coordinates —
    % no mastoid/EOG/reference channels in this montage, and re-referencing
    % (reref_eq_pchpl.txt) does not manufacture an additional channel the
    % way the Hampshire file creates HEOG. No split needed before clean_rawdata.
    %
    % IMPORTANT: unlike Hampshire, this reference scheme (single-channel
    % reference to TP9/ch10, not an average of two channels) is mathematically
    % full-rank — it does NOT force a structural rank deficiency. Do not assume
    % PC subjects will show "N-2" ICA components the way Hampshire subjects do;
    % full-rank (31) ICA output is the expected, correct result here. Any rank
    % deficiency on a PC subject reflects that subject's actual data (e.g. a
    % bridged/flat channel), not the reference scheme.
    %
    % NOTE: reref_eq_pchpl.txt has an inconsistent Label syntax for channels
    % 1-9 ("LabelFp1", no space) vs. channels 10-31 ("Label TP9", with space).
    % Verify this parses correctly in pop_eegchanoperator before trusting a
    % real run; safest fix is adding the missing spaces to match channels 10+.
    chan_num = 31;

    chan_locs_file = fullfile( ...
        eeglab_dir, 'sample_locs', 'M21_PC_31ch.ced');
    reref_file = fullfile(DIR, 'reref_eq_pchpl.txt');

    scalp_idx    = 1:31;
    nonscalp_idx = [];   % no non-scalp channels in this montage

else

    error( ...
        'Unknown data collection location "%s". Use "hc" or "pc".', ...
        location);

end

%% Verify required files exist

if ~isfile(chan_locs_file)
    error( ...
        'Channel locations file not found:\n  %s', ...
        chan_locs_file);
end

if ~isfile(reref_file)
    error( ...
        'Re-reference file not found:\n  %s', ...
        reref_file);
end

%% Filename prefix used in every output file
if isempty(taskID)
    task_pfx = '';
else
    task_pfx = ['_' taskID];
end

%% -------------------------------------------------------------------------
%  2. Open output files
% -------------------------------------------------------------------------

tag_parts = {};
if ~isempty(studyID), tag_parts{end+1} = studyID; end
if ~isempty(taskID),  tag_parts{end+1} = taskID;  end
if ~isempty(binID),   tag_parts{end+1} = binID;   end
study_tag = strjoin(tag_parts, '_');

run_timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));

folder_parts = [tag_parts, {run_timestamp}];
run_output_dir = fullfile(DIR, 'Pipeline_Logs', strjoin(folder_parts, '_'));
if ~isfolder(run_output_dir)
    mkdir(run_output_dir);
end

log_fname   = fullfile(run_output_dir, [study_tag '_pipeline_log.txt']);
chan_fname   = fullfile(run_output_dir, [study_tag '_removed_channels.txt']);
trial_fname  = fullfile(run_output_dir, [study_tag '_trial_counts.csv']);

fid_log   = fopen(log_fname,  'w');
fid_chan  = fopen(chan_fname,  'w');
fid_trial = fopen(trial_fname, 'w');

if any([fid_log fid_chan fid_trial] == -1)
    error('Could not open one or more output files for writing. Check folder permissions.');
end

fprintf(fid_log, 'Pipeline log — %s\n', study_tag);
fprintf(fid_log, 'Run: %s\n', char(datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss')));
fprintf(fid_log, 'Location: %s   Channels: %d   Srate: %d Hz\n', ...
    location, chan_num, srate);
fprintf(fid_log, 'Epoch: [%d %d] ms   ARJ threshold: +/-%d uV   ARJ window: [%d %d] ms\n\n', ...
    epoch_vec(1), epoch_vec(2), arj_thresh, arj_win(1), arj_win(2));

fprintf(fid_chan, 'Bad-channel removal log — %s\n', study_tag);
fprintf(fid_chan, 'Run: %s\n\n', char(datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss')));

%% -------------------------------------------------------------------------
%  3. Initialise accumulators
% -------------------------------------------------------------------------
ICA_log = table( ...
    strings(nsubj, 1), ...
    nan(nsubj, 1), ...
    strings(nsubj, 1), ...
    'VariableNames', {'Subject', 'N_Removed_ICs', 'Status'});

trial_header_written = false;
bin_labels           = {};
ica_removed_vec      = nan(nsubj, 1);
all_trial_counts     = [];
subj_duration_vec    = nan(nsubj, 1);   % seconds per subject, NaN if skipped

%% =========================================================================
%  MAIN SUBJECT LOOP
%
%  Suffix chain built up across stages:
%    (none) = loaded from subjID_taskID.set
%    _FLT   = band-pass filtered
%    _RSP   = resampled
%    _REF   = re-referenced
%    _ELS   = event list created
%    _CLN   = bad channels removed (automated)
%    _ICA   = ICA artefact components removed
%    _INT   = bad channels interpolated
%    _BIN   = bins assigned
%    _EPC   = epoched
%    _ARJ   = artifact-rejected epochs flagged
% =========================================================================

%% -------------------------------------------------------------------------
%  Pre-flight check: verify channel locations file exists.
% -------------------------------------------------------------------------
if ~isfile(chan_locs_file)
    fclose(fid_log); fclose(fid_chan); fclose(fid_trial);
    error('Channel locations file not found:\n  %s\nCreate the appropriate HC or PC .ced file first.', ...
        chan_locs_file);
end
fprintf('Pre-flight check passed: channel locations file found.\n');

pipeline_start = tic;   % overall run timer, starts here

for subject = 1:nsubj

    subjID      = strtrim(subj_list{subject});
    subject_DIR = fullfile(DIR, 'DATA', subjID);

    fprintf('\n\n==============================\n');
    fprintf('Subject %d / %d : %s\n', subject, nsubj, subjID);
    fprintf('==============================\n');
    fprintf(fid_log, '\n--- Subject %s ---\n', subjID);

    ICA_log.Subject(subject) = string(subjID);
    subj_start = tic;   % per-subject timer

    % ------------------------------------------------------------------
    %  Check starting .set/.fdt files exist
    %  Expected: DATA/subjID/subjID_taskID.set
    % ------------------------------------------------------------------
        fname_base      = [subjID task_pfx];        % unchanged — used only for loading the source .set/.fdt
    checkpoint_base = fname_base;                % bin-independent name, shared across both BDF passes
    output_base     = append_tag(fname_base, binID);   % used only from bin-assignment onward
    fname_set = [fname_base '.set'];
    fname_fdt = [fname_base '.fdt'];

    % ------------------------------------------------------------------
    %  Checkpoint check: has this subject already been through Stages
    %  2-5 (filter/resample/ref/clean/ICA/interpolate) in a previous
    %  pass (e.g. the FS run), leaving a reusable bin-independent
    %  dataset behind? If so, skip straight to bin assignment (Stage 6)
    %  and Stage 7 for THIS pass's BDF file, instead of redoing the most
    %  expensive stages (Stage 4 especially) a second time.
    % ------------------------------------------------------------------
    checkpoint_set  = [checkpoint_base '_FLT_RSP_REF_ELS_CLN_ICA_INT.set'];
    checkpoint_path = fullfile(subject_DIR, checkpoint_set);

    if isfile(checkpoint_path)

        fprintf('  Checkpoint found — loading %s\n', checkpoint_set);
        fprintf('  Skipping Stages 2a-5 (already completed in a previous pass)\n');
        fprintf(fid_log, '  Checkpoint found: %s — skipped Stages 2a-5\n', checkpoint_set);

        EEG = pop_loadset('filename', checkpoint_set, 'filepath', subject_DIR);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, 'gui', 'off');
        eeglab redraw;

        % ICA did not run this pass — record that plainly rather than
        % leaving a misleading blank/zero in the log.
        ICA_log.N_Removed_ICs(subject) = NaN;
        ICA_log.Status(subject)        = "checkpoint reused (see other pass for ICA count)";

        % true_removed_scalp_labels / original_chanlocs / original_labels
        % are needed later only for interpolation bookkeeping, which is
        % already baked into the checkpointed data — nothing further
        % needed here.

    else
        % ------------------------------------------------------------------
        %  No checkpoint yet — run the full Stages 1-5 for this subject.
        % ------------------------------------------------------------------

        if ~isfile(fullfile(subject_DIR, fname_set)) || ...
           ~isfile(fullfile(subject_DIR, fname_fdt))
            fprintf(' *** WARNING: %s or .fdt not found — skipping %s ***\n', fname_set, subjID);
            fprintf(fid_log, '  SKIPPED — %s or .fdt not found\n', fname_set);
            ICA_log.Status(subject) = "skipped - set file missing";
            continue
        end

        % ------------------------------------------------------------------
        %  Load starting .set file
        % ------------------------------------------------------------------
        fprintf('\n-- Loading %s --\n', fname_set);
        EEG = pop_loadset('filename', fname_set, 'filepath', subject_DIR);

        if EEG.nbchan ~= chan_num
            error(['Subject %s: channel-count mismatch. Location "%s" expects ' ...
                   '%d channels, but the loaded dataset contains %d.'], ...
                   subjID, location, chan_num, EEG.nbchan);
        end

        EEG.setname = fname_base;
        EEG.datfile = fname_fdt;
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'gui', 'off');
        eeglab redraw;
        fprintf(fid_log, '  Loaded: %s\n', fname_set);

        % ------------------------------------------------------------------
        %  STAGE 2: Filter -> Resample -> Channel locations -> Re-reference
        %            -> Event list   (bin-independent; this whole block is
        %            the shared checkpoint)
        % ------------------------------------------------------------------
        fprintf('\n-- Stage 2: Filter / resample / ref / event list --\n');

        % Band-pass filter (0.1-30 Hz, 4th-order Butterworth, DC removed)
        EEG = pop_basicfilter(EEG, 1:chan_num, ...
            'Boundary', 'boundary', ...
            'Cutoff',   [0.1 30], ...
            'Design',   'butter', ...
            'Filter',   'bandpass', ...
            'Order',    4, ...
            'RemoveDC', 'on');
        EEG.setname = [checkpoint_base '_FLT'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
            'gui', 'off');

        % Downsample
        EEG = pop_resample(EEG, srate);
        EEG.setname = [checkpoint_base '_FLT_RSP'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
            'gui', 'off');

        % Channel locations — must be added before pop_clean_rawdata (Stage 3)
        EEG = pop_chanedit(EEG, 'lookup', chan_locs_file);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
            'gui', 'off');

        fprintf('DEBUG: Pz X immediately after pop_chanedit lookup: %s\n', mat2str(EEG.chanlocs(11).X));

        % Re-reference
        EEG = pop_eegchanoperator(EEG, reref_file, 'Saveas', 'off');
        EEG.setname = [checkpoint_base '_FLT_RSP_REF'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
            'gui', 'off');

        % pop_eegchanoperator does not reliably preserve chanlocs geometry for
        % all formula-created channels (observed: Pz loses its X/Y/Z after this
        % step, despite being present and correct immediately after the earlier
        % lookup). Re-running ONLY the coordinate lookup (not the re-reference
        % itself — see note in project log) restores it from the same
        % known-good .ced file.
        EEG = pop_chanedit(EEG, 'lookup', chan_locs_file);

        fprintf('DEBUG: Pz X immediately after re-referencing + second lookup: %s\n', ...
            mat2str(EEG.chanlocs(strcmpi({EEG.chanlocs.labels}, 'Pz')).X));

        % Create event list (bin-independent)
        EEG = pop_creabasiceventlist(EEG, ...
            'AlphanumericCleaning', 'on', ...
            'BoundaryNumeric',      {-99}, ...
            'BoundaryString',       {'boundary'}, ...
            'Eventlist', fullfile(subject_DIR, [checkpoint_base '_ELS.txt']));
        EEG.setname = [checkpoint_base '_FLT_RSP_REF_ELS'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
            'gui', 'off');
        eeglab redraw;
        fprintf(fid_log, '  Stage 2 done: filter / resample / ref / event list\n');

        % ------------------------------------------------------------------
        %  STAGE 3: Automated bad-channel removal
        %
        %  scalp_idx / nonscalp_idx come from the location config block
        %  above (hc or pc) — NOT redefined here, so this works correctly
        %  regardless of montage.
        % ------------------------------------------------------------------
        fprintf('\n-- Stage 3: Automated bad-channel removal --\n');

        original_chanlocs = EEG.chanlocs;
        original_labels   = {EEG.chanlocs.labels};

        if isempty(nonscalp_idx)
            % No non-scalp channels in this montage (e.g. PC) — clean
            % directly, no split/recombine needed.
            scalp_labels_before = {EEG.chanlocs.labels};

            EEG = pop_clean_rawdata(EEG, ...
                'FlatlineCriterion',  15, ...
                'ChannelCriterion',   0.65, ...
                'LineNoiseCriterion', 7, ...
                'Highpass',           'off', ...
                'BurstCriterion',     'off', ...
                'WindowCriterion',    'off', ...
                'BurstRejection',     'off', ...
                'Distance',           'Euclidian');

            scalp_labels_after = {EEG.chanlocs.labels};
            true_removed_scalp_labels = setdiff(scalp_labels_before, scalp_labels_after, 'stable');

        else
            % Non-scalp channels present (e.g. HC) — split them out before
            % cleaning, since pop_clean_rawdata has no built-in
            % channel-restriction parameter and cannot meaningfully
            % evaluate channels without scalp locations.
            EEG_scalp    = pop_select(EEG, 'channel', scalp_idx);
            EEG_nonscalp = pop_select(EEG, 'channel', nonscalp_idx);

            fprintf('DEBUG: X coordinates for EEG_scalp channels:\n');
            disp([EEG_scalp.chanlocs.X]);
            fprintf('DEBUG: number of channels in EEG_scalp: %d\n', length(EEG_scalp.chanlocs));

            scalp_labels_before = {EEG_scalp.chanlocs.labels};

            EEG_scalp = pop_clean_rawdata(EEG_scalp, ...
                'FlatlineCriterion',  15, ...
                'ChannelCriterion',   0.65, ...
                'LineNoiseCriterion', 7, ...
                'Highpass',           'off', ...
                'BurstCriterion',     'off', ...
                'WindowCriterion',    'off', ...
                'BurstRejection',     'off', ...
                'Distance',           'Euclidian');

            scalp_labels_after = {EEG_scalp.chanlocs.labels};
            true_removed_scalp_labels = setdiff(scalp_labels_before, scalp_labels_after, 'stable');

            assert(size(EEG_scalp.data, 2) == size(EEG_nonscalp.data, 2), ...
                'Subject %s: scalp and non-scalp subsets have different sample counts.', subjID);

            EEG = EEG_scalp;
            EEG.data     = [EEG_scalp.data; EEG_nonscalp.data];
            EEG.chanlocs = [EEG_scalp.chanlocs, EEG_nonscalp.chanlocs];
            EEG.nbchan   = size(EEG.data, 1);
        end

        fprintf('DEBUG: TRUE scalp channels removed (label-diff method): ');
        if isempty(true_removed_scalp_labels)
            fprintf('(none)\n');
        else
            fprintf('%s\n', strjoin(true_removed_scalp_labels, ', '));
        end

        if isfield(EEG.chaninfo, 'removedchans')
            EEG.chaninfo.removedchans = [];   % stale from Stage 2 lookup, not a real removal record
        end

        EEG = eeg_checkset(EEG);
        fprintf('DEBUG: channel count after cleaning + eeg_checkset: %d\n', length(EEG.chanlocs));

        EEG.setname = [checkpoint_base '_FLT_RSP_REF_ELS_CLN'];
        EEG = pop_saveset(EEG, ...
            'filename', [EEG.setname '.set'], ...
            'filepath', subject_DIR);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, 'gui', 'off');

        % Log removed channels
        fprintf(fid_chan, 'Subject: %s\n', subjID);
        if isempty(true_removed_scalp_labels)
            fprintf(fid_chan, '  No channels removed.\n\n');
            fprintf(fid_log,  '  Stage 3: no channels removed\n');
        else
            for ci = 1:length(true_removed_scalp_labels)
                fprintf(fid_chan, '  Removed: %s\n', true_removed_scalp_labels{ci});
            end
            fprintf(fid_chan, '\n');
            fprintf(fid_log, '  Stage 3: removed %d channel(s): %s\n', ...
                length(true_removed_scalp_labels), strjoin(true_removed_scalp_labels, ', '));
        end
        eeglab redraw;

        % ------------------------------------------------------------------
        %  STAGE 4: ICA
        %  Decompose with runica (extended mode), classify with ICLabel,
        %  flag components: muscle >= 0.90, eye >= 0.90, line noise >= 0.90
        % ------------------------------------------------------------------
        fprintf('\n-- Stage 4: ICA --\n');

        EEG = pop_runica(EEG, ...
            'icatype',   'runica', ...
            'extended',  1, ...
            'rndreset',  'yes', ...
            'interrupt', 'on');

        EEG = pop_iclabel(EEG, 'default');

        EEG = pop_icflag(EEG, ...
            [NaN NaN; ...   % Brain       — keep all
             0.90  1; ...   % Muscle      — remove if p >= 0.90
             0.90  1; ...   % Eye         — remove if p >= 0.90
             NaN NaN; ...   % Heart       — keep
             0.90  1; ...   % Line noise  — remove if p >= 0.90
             NaN NaN; ...   % Channel noise
             NaN NaN]);     % Other

        rejected_ICs = find(EEG.reject.gcompreject);
        n_removed    = length(rejected_ICs);

        ICA_log.N_Removed_ICs(subject) = n_removed;
        ICA_log.Status(subject)        = "processed";
        ica_removed_vec(subject)       = n_removed;

        fprintf('  %d ICA component(s) removed\n', n_removed);
        if n_removed > 0
            ic_str = strjoin(arrayfun(@num2str, rejected_ICs, 'UniformOutput', false), ', ');
        else
            ic_str = 'none';
        end
        fprintf(fid_log, '  Stage 4: %d component(s) removed (%s)\n', n_removed, ic_str);

        EEG = pop_subcomp(EEG, rejected_ICs, 0);
        EEG.setname = [checkpoint_base '_FLT_RSP_REF_ELS_CLN_ICA'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
            'gui', 'off');
        eeglab redraw;

        % ------------------------------------------------------------------
        %  STAGE 5: Interpolate channels removed in Stage 3
        %           and restore original channel order.
        %           The dataset saved at the end of this stage is the
        %           CHECKPOINT reused by the second (FS/BF) pass.
        % ------------------------------------------------------------------
        fprintf('\n-- Stage 5: Interpolation --\n');

        if ~isempty(true_removed_scalp_labels)
            fprintf('  Interpolating %d removed channel(s): %s\n', ...
                length(true_removed_scalp_labels), strjoin(true_removed_scalp_labels, ', '));

            [~, idx_in_original] = ismember(true_removed_scalp_labels, original_labels);
            removed_chanlocs = original_chanlocs(idx_in_original);

            EEG = eeg_interp(EEG, removed_chanlocs, 'spherical');
        else
            fprintf('  No removed channels — skipping interpolation\n');
        end

        current_labels = {EEG.chanlocs.labels};
        fprintf('DEBUG: %d channels in EEG.chanlocs after interpolation:\n', length(EEG.chanlocs));
        disp({EEG.chanlocs.labels});

        reorder = zeros(1, length(original_labels));
        for i = 1:length(original_labels)
            idx = find(strcmpi(current_labels, original_labels{i}));
            if isempty(idx)
                error('Subject %s: channel "%s" missing after interpolation.', subjID, original_labels{i});
            end
            if length(idx) > 1
                error('Subject %s: duplicate channel label "%s".', subjID, original_labels{i});
            end
            reorder(i) = idx;
        end

        EEG.data     = EEG.data(reorder, :);
        EEG.chanlocs = original_chanlocs;
        EEG.nbchan   = length(original_chanlocs);

        fprintf('  Channel order restored to original montage.\n');
        fprintf(fid_log, '  Stage 5: channel order restored to original montage\n');

        EEG.setname = [checkpoint_base '_FLT_RSP_REF_ELS_CLN_ICA_INT'];
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
            'gui', 'off');

        eeglab redraw;
        fprintf(fid_log, '  Stage 5 done: checkpoint saved (%s)\n', [EEG.setname '.set']);

    end   % if isfile(checkpoint_path) ... else ...

    % ------------------------------------------------------------------
    %  STAGE 6: Assign bins for THIS pass's BDF file.
    %  Runs every pass, whether or not the checkpoint above was reused.
    % ------------------------------------------------------------------
    if isempty(binID)
        fprintf('\n-- Stage 6: Bin assignment --\n');
    else
        fprintf('\n-- Stage 6: Bin assignment (%s) --\n', binID);
    end

    EEG = pop_binlister(EEG, ...
        'BDF',       bdf_file, ...
        'ExportEL',  fullfile(subject_DIR, [output_base '_ELS_BIN.txt']), ...
        'IndexEL',   1, ...
        'SendEL2',   'EEG&Text', ...
        'UpdateEEG', 'on', ...
        'Voutput',   'EEG');
    EEG.setname = [output_base '_FLT_RSP_REF_ELS_CLN_ICA_INT_BIN'];
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
        'setname', EEG.setname, ...
        'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
        'gui', 'off');
    eeglab redraw;
    if isempty(binID)
        fprintf(fid_log, '  Stage 6 done: bins assigned\n');
    else
        fprintf(fid_log, '  Stage 6 done: bins assigned (%s)\n', binID);
    end

    % ------------------------------------------------------------------
    %  STAGE 7: Epoch -> Artifact rejection -> Average
    % ------------------------------------------------------------------
    fprintf('\n-- Stage 7: Epoch / artifact rejection / average --\n');

    % Epoch and apply prestimulus baseline correction
    EEG = pop_epochbin(EEG, epoch_vec, 'pre');
    EEG.setname = [output_base '_FLT_RSP_REF_ELS_CLN_ICA_INT_BIN_EPC'];
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
        'setname', EEG.setname, ...
        'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
        'gui', 'off');
    eeglab redraw;

    % ------------------------------------------------------------------
    % Artifact rejection — amplitude threshold on scalp EEG channels only
    %
    % Hampshire:
    %   channels 1-27  = scalp EEG
    %   channels 28-32 = Mastoid R/L, HEOG R/L, VEOG L
    %
    % Providence:
    %   channels 1-31  = scalp EEG
    % ------------------------------------------------------------------

    % Artifact rejection — amplitude threshold on scalp EEG channels only.
    % scalp_idx is set once in the location config block above.
    arj_channels = scalp_idx;

    fprintf('  Artifact rejection channels: %s\n', mat2str(arj_channels));
    fprintf(fid_log, ...
            '  Stage 7 artifact rejection channels: %s\n', ...
        mat2str(arj_channels));


    EEG = pop_artextval(EEG, ...
        'Channel',   arj_channels, ...
        'Flag',      1, ...
        'LowPass',  -1, ...
        'Threshold', [-arj_thresh arj_thresh], ...
        'Twindow',   arj_win);

    EEG.setname = [output_base '_FLT_RSP_REF_ELS_CLN_ICA_INT_BIN_EPC_ARJ'];
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
        'setname', EEG.setname, ...
        'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
        'gui', 'off');

    % Artifact summary to text file
    EEG = pop_summary_AR_eeg_detection(EEG, ...
        fullfile(subject_DIR, [output_base '_ARJ_SUM.txt']));
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
        'setname', EEG.setname, ...
        'save', fullfile(subject_DIR, [EEG.setname '.set']), ...
        'gui', 'off');
    eeglab redraw;

    % Average — good epochs only, include SEM
    ERP = pop_averager(EEG, ...
        'Criterion',       'good', ...
        'ExcludeBoundary', 'on', ...
        'SEM',             'on');

    ERP.erpname = append_tag([subjID task_pfx], binID);
    pop_savemyerp(ERP, ...
        'erpname',  ERP.erpname, ...
        'filename', [ERP.erpname '.erp'], ...
        'filepath', subject_DIR, ...
        'warning',  'off');

    CURRENTERP         = CURRENTERP + 1;
    ALLERP(CURRENTERP) = ERP;
    eeglab redraw;
    erplab redraw;

    % ------------------------------------------------------------------
    %  Collect trial counts per bin
    % ------------------------------------------------------------------
    if isfield(ERP, 'ntrials') && isfield(ERP.ntrials, 'accepted')
        counts = ERP.ntrials.accepted;   % 1 x nBins

        % Accumulate for summary statistics
        if isempty(all_trial_counts)
            all_trial_counts = counts;
        else
            all_trial_counts = [all_trial_counts; counts]; %#ok<AGROW>
        end

        % Write CSV header from first valid subject's bin descriptions
        if ~trial_header_written
            if isfield(ERP, 'bindescr') && ~isempty(ERP.bindescr)
                bin_labels = ERP.bindescr;
            else
                bin_labels = arrayfun(@(b) sprintf('Bin%d', b), ...
                    1:length(counts), 'UniformOutput', false);
            end
            fprintf(fid_trial, 'Subject');
            fprintf(fid_trial, ',%s', bin_labels{:});
            fprintf(fid_trial, '\n');
            trial_header_written = true;
        end

        fprintf(fid_trial, '%s', subjID);
        fprintf(fid_trial, ',%d', counts);
        fprintf(fid_trial, '\n');

        fprintf(fid_log, '  Stage 7: accepted trials per bin: %s\n', num2str(counts));
    else
        fprintf(fid_log, '  Stage 7: ntrials.accepted not available\n');
    end

    subj_elapsed = toc(subj_start);
    subj_duration_vec(subject) = subj_elapsed;

    fprintf('  Subject %s completed in %s\n', subjID, format_duration(subj_elapsed));
    fprintf(fid_log, '  Stage 7: subject completed in %.1f s (%s)\n', ...
        subj_elapsed, format_duration(subj_elapsed));
    fprintf(fid_log, '  COMPLETED\n');

end  % subject loop


pipeline_elapsed = toc(pipeline_start);
fprintf('\n\nTotal pipeline runtime: %s (%.1f minutes)\n', ...
    format_duration(pipeline_elapsed), pipeline_elapsed/60);

%% =========================================================================
%  Post-loop: write ICA log and summary statistics
% =========================================================================

%% ICA log CSV
ica_log_fname = fullfile(run_output_dir, [study_tag '_ICA_log.csv']);
writetable(ICA_log, ica_log_fname);
fprintf('\nICA log saved: %s\n', ica_log_fname);

%% Summary statistics (for the Methods section)
sum_fname = fullfile(run_output_dir, [study_tag '_summary_stats.txt']);
fid_sum   = fopen(sum_fname, 'w');

fprintf(fid_sum, 'Summary statistics for Methods section\n');
fprintf(fid_sum, 'Study: %s   Task: %s\n', studyID, taskID);
fprintf(fid_sum, 'Run: %s\n\n', char(datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss')));

% Subject processing time
valid_durations = subj_duration_vec(~isnan(subj_duration_vec));
if ~isempty(valid_durations)
    fprintf(fid_sum, '--- Per-subject processing time ---\n');
    fprintf(fid_sum, '  N subjects: %d\n',   length(valid_durations));
    fprintf(fid_sum, '  Mean:  %s\n',        format_duration(mean(valid_durations)));
    fprintf(fid_sum, '  SD:    %.1f s\n',    std(valid_durations));
    fprintf(fid_sum, '  Range: %s - %s\n\n', ...
        format_duration(min(valid_durations)), format_duration(max(valid_durations)));
end

fprintf(fid_sum, '--- Total pipeline runtime ---\n');
fprintf(fid_sum, '  %s (%.1f minutes)\n\n', format_duration(pipeline_elapsed), pipeline_elapsed/60);

% ICA
valid_ica = ica_removed_vec(~isnan(ica_removed_vec));
if ~isempty(valid_ica)
    fprintf(fid_sum, '--- ICA components removed ---\n');
    fprintf(fid_sum, '  N subjects: %d\n',    length(valid_ica));
    fprintf(fid_sum, '  Mean:  %.1f\n',        mean(valid_ica));
    fprintf(fid_sum, '  SD:    %.1f\n',        std(valid_ica));
    fprintf(fid_sum, '  Range: %d - %d\n\n',  min(valid_ica), max(valid_ica));
    fprintf('\nICA components removed: M = %.1f, SD = %.1f, range %d-%d\n', ...
        mean(valid_ica), std(valid_ica), min(valid_ica), max(valid_ica));
end

% Trial counts per bin
if ~isempty(all_trial_counts)
    fprintf(fid_sum, '--- Accepted trials per condition ---\n');
    for b = 1:size(all_trial_counts, 2)
        col = all_trial_counts(:, b);
        col = col(~isnan(col));
        if ~isempty(bin_labels)
            lbl = bin_labels{b};
        else
            lbl = sprintf('Bin %d', b);
        end
        fprintf(fid_sum, '  %s\n',              lbl);
        fprintf(fid_sum, '    N:     %d\n',     length(col));
        fprintf(fid_sum, '    Mean:  %.1f\n',   mean(col));
        fprintf(fid_sum, '    SD:    %.1f\n',   std(col));
        fprintf(fid_sum, '    Range: %d - %d\n', min(col), max(col));
    end
end

fclose(fid_sum);

%% Close all open output files
fclose(fid_log);
fclose(fid_chan);
fclose(fid_trial);

fprintf('\n\nAll output files written to: %s\n', run_output_dir);
fprintf('  %s\n', log_fname);
fprintf('  %s\n', chan_fname);
fprintf('  %s\n', trial_fname);
fprintf('  %s\n', ica_log_fname);
fprintf('  %s\n', sum_fname);
fprintf('\nPipeline complete.\n');

%% =========================================================================
%  Run the appropriate downstream grand-average and measurement scripts
%  after reviewing individual ERPs and finalising subject inclusion.
% =========================================================================


%% -------------------------------------------------------------------------
%  Local helper functions
% -------------------------------------------------------------------------
function s = format_duration(seconds_elapsed)
    % Formats a duration in seconds as "Hh MMm SSs" or "MMm SSs" if under an hour.
    h = floor(seconds_elapsed / 3600);
    m = floor(mod(seconds_elapsed, 3600) / 60);
    s_val = mod(seconds_elapsed, 60);
    if h > 0
        s = sprintf('%dh %02dm %02.0fs', h, m, s_val);
    else
        s = sprintf('%dm %02.0fs', m, s_val);
    end
end

function s = append_tag(base, tag)
    % Appends '_' + tag to base only if tag is non-empty, so callers
    % don't need to special-case an optional label (e.g. blank binID)
    % everywhere it's used.
    if isempty(tag)
        s = base;
    else
        s = [base '_' tag];
    end
end