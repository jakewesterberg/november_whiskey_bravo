function proc_ART(pp, nwb, rd, ii, recording_info, recdev, probe, bit2volt)
%primary function for artifact removal. original version by M vd Grinten,
%edits (functionified) by JAW 11-09-2023

if nargin < 8
    bit2volt = 0.25; % BR default;
end

%% read parameters
% load parameters for artifact removal or use default parameters if not loaded
if exist([pp.RAW_DATA recording_info.Identifier{ii} filesep 'ART_params.mat'], 'file')
    load([pp.RAW_DATA recording_info.Identifier{ii} filesep 'ART_params.mat'])
    ART_params = ART_params.ART_params;
else
    disp("Using default artifact removal parameters")
    ART_params.TTL_instance = 1;
    ART_params.TTL_channel_set = 135:141;
    ART_params.threshold = 3000; %TTL threshold
    
    %analysis params
    ART_params.pre_stim_window = 0.2; %gap removal 'jump' will be placed around here
    % post_stim_window = 1.0;
    
    %artifact removal params
    ART_params.blank_length = 30;
    ART_params.margin = 2; %margins around the polynomial fit windows
    ART_params.polynomial_order = 5;
end

%% for testing purposes, all of these values should be provided by probe, recdev or nwb structures.

data_path = [pp.CAT_DATA nwb.identifier '_dev-' num2str(rd-1)];

trial_params = readtable([data_path filesep 'trial_params.csv'],'ReadRowNames',true, 'ReadVariableNames', false);

ANALOG_filetag = "board-ANALOG-IN-";

electrode_string = num2str(0,'%03d'); 
instance_string = "A";

dat_filepath1 = data_path + "\amp-" + instance_string + "-" + electrode_string + ".dat";
current_fid = fopen(dat_filepath1 , 'r');
fseek(current_fid, 0, 'eof');
filesize = ftell(current_fid);
fclose(current_fid);

num_samples = probe{1}.num_samples;
samplerate = recdev{1}.sampling_rate;

pulse_start_idx = round(ART_params.pre_stim_window*samplerate);

%% set up filter
% band pass 250 - 4000 Hz, 
Fn = samplerate/2;
Fbp= [250 5000];
N  = 5;    % filter order
[Bbp, Abp] = butter(N, [min(Fbp./Fn),max(Fbp./Fn)],'bandpass'); % BandPass

%% load stim moments
% seven stimulator channels. These channels can change (e.g. because one
% stimulator gets taken away to be used in Brazil) so I made this a
% parameter in the ART_params file.
TTL_channels = ART_params.TTL_channel_set;
TTL_channels = TTL_channels - 128; %To analog channel IDs

% Sum the TTL channels
TTL_data = nan(length(TTL_channels),num_samples);
ch_ctr = 1;
for ch = TTL_channels
    TTL_filepath = data_path + "\"+ ANALOG_filetag + num2str(ch) + ".dat";
    fid = fopen(TTL_filepath , 'r');
    T_data = double(fread(fid, num_samples, 'int16')) .* bit2volt;
    TTL_data(ch_ctr,:) = T_data;
    ch_ctr = ch_ctr+1;
end
TTL = sum(TTL_data,1);

% Get the TTL start and stop timestamps (one per stimulation train)
crossings = diff(TTL > ART_params.threshold);
starts = crossings == 1;
ends = crossings == -1;
n_trials = sum(starts);
disp(['nr of trials found: ', num2str(n_trials)])

%% get start of pulse train and actual frequencies per trial
% This only needs to be calculated once per task, it's the same for all
% instances / electrodes (assuming correct alignment)
n_pulses = table2array(trial_params("numPulses",:));
n_pulses = n_pulses(table2array(trial_params("microStimFlag",:)) == 1);
pulse_train_starts = find(starts);
pulse_train_end = find(ends);

TTL_lengths = pulse_train_end - pulse_train_starts;
trial_lengths = pulse_train_starts(2:end)-pulse_train_starts(1:end-1);
trial_lengths = [trial_lengths, numel(TTL)-pulse_train_starts(end)];

try
    actual_freqs = 1./(TTL_lengths/samplerate./n_pulses);
catch
    if numel(unique(samplerate./n_pulses)) == 1
        actual_freqs = ones(1, numel(TTL_lengths)) .* unique(samplerate./n_pulses);
    end
end

%% compute gap starts over entire block
% We remove gaps along the entire signal to have a fair analysis compared
% to during the stimulation where the artifacts are blanked
gap_starts = [];
for i = 1:n_trials
    freq_a = actual_freqs(i); %exact frequency != what was set on stimulator
    
    period = (1/freq_a)*samplerate;
    if i==1
        n_samples_prestim = pulse_train_starts(1);
    else
        n_samples_prestim = pulse_start_idx;
    end
    prestim_offset = floor(n_samples_prestim/period)*period;
    gap_starts_seq = pulse_train_starts(i):period:pulse_train_starts(i)+(n_samples_prestim - pulse_start_idx)+trial_lengths(i);
    gap_starts = [gap_starts, round(gap_starts_seq - prestim_offset)];
    if gap_starts(1) == 0
        gap_starts(1) = 1;
    end
end
gap_starts = gap_starts';

%% Actual artifact removal

savedir = [pp.ART_DATA nwb.identifier '_dev-' num2str(rd-1)];

if ~exist(savedir, 'dir')
    mkdir(savedir);
end

for jj = 1 : numel(probe)
    instance_string = probe{jj}.port;
    parfor ch = 1:probe{jj}.num_channels
        disp("Working on electrode "+num2str(ch))
        % Open file and init data
        electrode_string = num2str(ch-1,'%03d');
        file_name = "amp-" + instance_string + "-" + electrode_string + ".dat";
        dat_file_path            = data_path + "\" + file_name;
        current_fid             = fopen(dat_file_path, 'r');
        current_data            = double(fread(current_fid, num_samples, 'int16'));% .* bit2volt;

        % artifact removal for MUA
        art_removed_data_MUA = art_removal_MUA(ART_params, current_data', gap_starts, Abp, Bbp);

        % Save file
        write_file_id = fopen(savedir + "\" + "MUA_" + file_name, 'w');
        fwrite(write_file_id, art_removed_data_MUA, 'int16');
        fclose(write_file_id);

        % artifact removal for LFP
        art_removed_data_LFP = art_removal_LFP(ART_params, current_data', gap_starts, Abp, Bbp);

        % Save file
        write_file_id = fopen(savedir + "\" + "LFP_" + file_name, 'w');
        fwrite(write_file_id, art_removed_data_LFP, 'int16');
        fclose(write_file_id);
    end
end

end