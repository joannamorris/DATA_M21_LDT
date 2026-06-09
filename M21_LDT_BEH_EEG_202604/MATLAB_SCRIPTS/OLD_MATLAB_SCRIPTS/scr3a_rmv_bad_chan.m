%% Clear memory and the command window
clear;
clc;

%% Load EEGLAB
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
ALLERP = buildERPstruct([]);

%% Set up variables holding key values

prompt = { ...
    'Enter StudyID:', ...
    'Enter TaskID:', ...
    'Enter name of subject list file:', ...
    'Enter the part of the file names that comes after the subject and task IDs, including the underscores. If there are no filename extensions, leave the box empty:'};
dlgtitle = 'Input';
dims = [1 70];
definput = {'MSC','','msc_subjlist.txt','_FLT_RSP_REF_ELS_BIN'};
my_input = inputdlg(prompt, dlgtitle, dims, definput);

DIR        = pwd;
studyID    = my_input{1}; %#ok<NASGU>  % currently not used
task       = my_input{2};
subj_list  = importdata(my_input{3});
f_string   = my_input{4};
nsubj      = length(subj_list);

%% Open output file once before looping through subjects
outFile = fullfile(DIR,[studyID '_removed_channels.txt'] );
fid = fopen(outFile, 'w');
if fid == -1
    error('Could not open %s for writing.', outFile);
end

fprintf(fid, 'Removed channel log\n');
fprintf(fid, '===================\n\n');

%% Load the eegsets and make them available in the EEGLAB GUI

for subject = 1:nsubj
    subjID = strtrim(subj_list{subject});
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);

    subject_DIR = fullfile(DIR, subjID);

    % Construct filename
    if isempty(task)
        fname = [subjID f_string];
    else
        fname = [subjID '_' task f_string];
    end

    fname_set = [fname '.set'];
    fname_fdt = [fname '.fdt'];

    %% Check to make sure the dataset file exists
    if exist(fullfile(subject_DIR, fname_set), 'file') <= 0 || ...
       exist(fullfile(subject_DIR, fname_fdt), 'file') <= 0

        fprintf('\n *** WARNING: %s does not exist *** \n', fname);
        fprintf('\n *** Skip all processing for this subject *** \n\n');

        fprintf(fid, 'Subject %s\n', subjID);
        fprintf(fid, '  WARNING: dataset files not found for %s\n\n', fname);

    else
        %% Load .set file
        fprintf('\n**** %s: Loading set file ****\n\n', fname_set);
        EEG = pop_loadset('filename', fname_set, 'filepath', subject_DIR);
        EEG.setname = fname;
        EEG.datfile = fname_fdt;

        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'gui', 'off');

        eeglab redraw;

        %% Bad channel removal
        EEG = pop_clean_rawdata(EEG, ...
            'FlatlineCriterion', 15, ...
            'ChannelCriterion', 0.65, ...
            'LineNoiseCriterion', 7, ...
            'Highpass', 'off', ...
            'BurstCriterion', 20, ...
            'WindowCriterion', 'off', ...
            'BurstRejection', 'off', ...
            'Distance', 'Euclidian');

        EEG.setname = [fname '_CLN'];

        %% Save cleaned dataset
        EEG = pop_saveset(EEG, ...
            'filename', [EEG.setname '.set'], ...
            'filepath', subject_DIR);

        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', EEG.setname, ...
            'gui', 'off');

        %% Find and write bad channel file
            fprintf(fid, 'Subject: %s\n', subjID);
            fprintf(fid, 'Dataset: %s\n', fname_set);
            
            % Sample info
            if isfield(EEG, 'etc') && isfield(EEG.etc, 'clean_sample_mask')
                n_kept = sum(EEG.etc.clean_sample_mask);
                n_total = length(EEG.etc.clean_sample_mask);
                n_rejected = n_total - n_kept;
                fprintf(fid, '  Samples kept: %d / %d\n', n_kept, n_total);
                fprintf(fid, '  Samples rejected: %d\n', n_rejected);
            end
            
            % Check whether removedchans exists and is usable
            has_removedchans = false;
            if isfield(EEG, 'chaninfo') && isfield(EEG.chaninfo, 'removedchans') ...
                    && isstruct(EEG.chaninfo.removedchans) && ~isempty(EEG.chaninfo.removedchans)
                has_removedchans = true;
            end
            
            % Channel info
            if isfield(EEG, 'etc') && isfield(EEG.etc, 'clean_channel_mask')
            
                bad_idx = find(~EEG.etc.clean_channel_mask);
            
                if isempty(bad_idx)
                    fprintf(fid, '  No channels removed.\n');
                else
                    if has_removedchans
                        bad_labels = {EEG.chaninfo.removedchans.labels};
                        for i = 1:length(bad_idx)
                            fprintf(fid, '  Removed channel %d: %s\n', bad_idx(i), bad_labels{i});
                        end
                    else
                        for i = 1:length(bad_idx)
                            fprintf(fid, '  Removed channel %d\n', bad_idx(i));
                        end
                    end
                end
            
            elseif has_removedchans
            
                bad_labels = {EEG.chaninfo.removedchans.labels};
                for i = 1:length(bad_labels)
                    fprintf(fid, '  Removed channel: %s\n', bad_labels{i});
                end
            
            else
                fprintf(fid, '  No channels removed.\n');
            end
            
            fprintf(fid, '\n');

        eeglab redraw;
    end
end

%% Close output file
fclose(fid);
fprintf('\nDone. Removed channel log written to:\n%s\n', outFile);