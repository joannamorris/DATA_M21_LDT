%% Clear memory and the command window
clear;
clc;


%% Load eeglab, erplab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
ALLERP = buildERPstruct([]);
%% Set up variables holding key values 
    
% Dialog box to get info about script variables 
prompt    = {'Enter name of subject list file:',...
             'Enter task ID:',...
             'Enter data collection location:',...
             'Enter the part of the file names that comes after the subject and task IDs. If there are no filename extensions, leave the box empty:',...
             'Enter list of bin numbers to plot:'};
dlgtitle  =  'Input';
dims      = [1 70];
definput  = {'temp.txt', 'LDT', 'hampshire','diff_waves', '3 4 5 6' };
my_input  = inputdlg(prompt,dlgtitle,dims,definput);

DIR       = pwd;                       % Current folder (where the script should be located)
subjlist  = importdata(my_input{1});   % list of subject ids
location  = my_input{3};

if isempty(my_input{2})                         % which task
    taskID     = '';
else
    taskID     = ['_' my_input{2}];
end

if isempty(my_input{4})
    f_string = '';
else
    f_string  = ['_' my_input{4}];
end

bins      = str2num(my_input{4});
nsubj     = length(subjlist);         % number of subjects

if strcmp(location, 'hampshire')   % strcmp(s1,s2) compares s1 and s2 and returns 1 (true) if the two are identical and 0 (false) otherwise
    channels = [3 2 25 7 20 21 12 11 16];
else
    channels = [3 2 29 8 23 24 14 13 19];
end


%% Load the  ERPsets and make them available in the ERPLAB GUI
CURRENTERP = 0;  % Initialize it to 0 before the loop starts

for subject = 1:nsubj
    subjID = subjlist{subject};
    subject_DIR = [DIR filesep subjID];

    fname = [subjID taskID f_string '.erp'];  % Include taskID if it's not empty
   
    

     %% Check to make sure the dataset file exists
    if  exist([subject_DIR filesep fname ], 'file')<=0
        fprintf('\n *** WARNING: %s does not exist *** \n', fname);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else 
        
    fprintf('\n******\nProcessing subject %s\n******\n\n', subjID);
    
    
    ERP = pop_loaderp('filename', fname, 'filepath', subject_DIR);
	CURRENTERP = CURRENTERP + 1;
    ALLERP(CURRENTERP) = ERP;  

    

    % Plot Grand Average Waveform
    ERP = pop_ploterps( ERP, bins, channels,...
                        'AutoYlim', 'on', ...
                        'Axsize', [0.05 0.08],...
                        'BinNum', 'on', ...
                        'Blc', '-200 0',...
                        'Box', [3 3],...
                        'ChLabel', 'on',...
                        'FontSizeChan', 14,...
                        'FontSizeLeg', 12, ...
                        'FontSizeTicks', 12, ...
                        'LegPos', 'right',...
                        'Linespec', {'b-.', 'r-.', 'c-', 'm-' },...
                        'LineWidth', 2,...
                        'Maximize', 'on',...
                        'Position', [68.6429 15.0714 106.857 31.9286], ...
                        'Style', 'Classic', ...
                        'Tag', 'ERP_figure',...
                        'Transparency', 0,...
                        'xscale', [-200.0 550.0   -200:100:550], ...
                        'YDir', 'reverse');



    end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects
erplab redraw;


