% This script creates a grand average erp file and then low pass filters it
% at 30 Hz

%% Clear memory and the command window
clear;
clc;


%% Load eeglab, erplab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
ALLERP = buildERPstruct([]);
CURRENTERP = 1;  % Initialize CURRENTERP to 1

%% Set up variables holding key values 
    
%  Dialog box to get info about script variables 
prompt      = {'Enter name of grand average file:',...
               'Enter the data collection location:'};  % Two prompts in the dialog box
dlgtitle    = 'Grand average filename';                  
dims        = [1 70];
definput    = {'M21_LDT_GA1', 'hampshire'};  % Provide two default inputs to match two prompts
my_input    = inputdlg(prompt, dlgtitle, dims, definput);
    
DIR         = pwd;  % Current folder (where the script should be located)
ga_name     = my_input{1};
location    = my_input{2};
  
if strcmp(location, 'hampshire')
    chan_num = 33;
else
    chan_num = 31;
end

fname = [ga_name '.erp']

%% Load the ERPset and make it available in the ERPLAB GUI
       
if exist([DIR filesep fname], 'file') <= 0
    fprintf('\n *** WARNING: %s does not exist *** \n', [DIR filesep ga_name]);
else 
    %% Load erpset
    ERP = pop_loaderp('filename', fname, 'filepath', DIR);
    CURRENTERP = length(ALLERP) + 1;  % Ensure this increments correctly
    ALLERP(CURRENTERP) = ERP;    
end
erplab redraw;

%% Filter Grand Average Waveform
ERP = pop_filterp(ERP, 1:chan_num ,...
                  'Cutoff',  30,...
                  'Design', 'butter',...
                  'Filter', 'lowpass',...
                  'Order',  2 );
ERP = pop_savemyerp(ERP,...
                    'erpname', [ga_name '_FLT'],...
                    'filename', [ga_name '_FLT.erp'],...
                    'filepath', DIR , ...
                    'Warning', 'on');
CURRENTERP = CURRENTERP + 1;
ALLERP(CURRENTERP) = ERP; 
erplab redraw;
