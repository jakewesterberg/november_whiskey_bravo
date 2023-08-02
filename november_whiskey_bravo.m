%% Header
% Jake Westerberg, PhD (westerberg-science)
% Netherlands Institute for Neuroscience (prev. Vanderbilt University)
% jakewesterberg@gmail.com

% Requirements
% Certain aspects of the data processing require toolboxes found in other
% github repos. Original or forked versions of all required can be found on
% Jake's github page (westerberg-science). Kilosort (2 is used here) is
% required for spike sorting. Also, this of course requires the matnwb
% toolbox.

function november_whiskey_bravo(ID, varargin)

%% Defaults - need to ammend
skip_completed                  = true;
this_ident                      = []; % used to specify specific session(s) with their ident

%% Varargin
varStrInd = find(cellfun(@ischar,varargin));
for iv = 1:length(varStrInd)
    switch varargin{varStrInd(iv)}
        case {'skip'}
            skip_completed = varargin{varStrInd(iv)+1};
        case {'this_ident'}
            this_ident = varargin{varStrInd(iv)+1};
    end
end

%% pathing...can change to varargin or change function defaults for own machine
pp = pipeline_paths();

% add toolboxes
addpath(genpath(pp.TBOXES));

recording_info = readmatrix( ...
    ID, ...
    'OutputType', 'char', ...
    'UseExcel', true, ...
    'Range', 1);

recording_info = array2table( ...
    recording_info(2:end,:), ...
    'VariableNames', recording_info(1,:));

rif = fields(recording_info);
rif = rif(1:end-3);
for ii = rif'
    if iscell(recording_info.(ii{:}))
    if ~isnan(cellfun(@str2double, recording_info.(ii{:})))
        recording_info.(ii{:}) = cellfun(@str2double, recording_info.(ii{:}));
    end
    end
end

% Create default processing list
to_proc = 1:length(unique(recording_info.Identifier));

% Limit to a specific session in a specific subject (ie identifier)
if ~isempty(this_ident)
    for ii = 1 : numel(this_ident)
        to_proc = find(strcmp(recording_info.Identifier, this_ident{ii}), 1);
    end
end

n_procd = 0;
%% Loop through sessions
for ii = to_proc

    % Skip files already processed if desired
    if (exist([pp.DATA_DEST '_6_NWB_DATA' filesep recording_info.Identifier{ii} '.nwb'], 'file') & skip_completed) | ...
            recording_info.Preprocessor_Ignore_Flag(ii) == 1
        continue;
    end

    % Initialize nwb file
    nwb                                 = NwbFile;
    nwb.identifier                      = recording_info.Identifier{ii};
    nwb.session_start_time              = datetime(datestr(datenum(num2str(recording_info.Session(ii)), 'yyyymmdd')));
    nwb.general_experimenter            = recording_info.Investigator{ii};
    nwb.general_institution             = recording_info.Institution{ii};
    nwb.general_lab                     = recording_info.Lab{ii};
    nwb.general_session_id              = recording_info.Identifier{ii};
    nwb.general_experiment_description  = recording_info.Experiment_Description{ii};

    num_recording_devices = numel(unique(eval(['[' recording_info.Probe_System{ii} ']' ])));

    if strcmp(recording_info.Raw_Data_Path{ii}(1:2), '\\') & isempty(findDir(pp.RAW_DATA, nwb.identifier))
        pull_data(pp, recording_info(ii,:));
    end

    for rd = 1 : num_recording_devices
        if strcmp(recording_info.Raw_Data_Format{ii}, 'Blackrock NSx')
            if ~exist([pp.CAT_DATA filesep nwb.identifier '_dev-' num2str(rd-1)], 'dir')
                proc_CAT(pp, nwb, rd, ii, recording_info);
            end
        end
    end

    [nwb, recdev, probe] = proc_PRO(pp, nwb, recording_info, ii, num_recording_devices);

    probe_ctr = 0;
    for rd = 1 : num_recording_devices

        % Record analog traces
        nwb = proc_AIO(pp, nwb, recdev{rd}, ii, recording_info);

        % Digital events
        nwb = proc_DIO(pp, nwb, recdev{rd});

        % Loop through probes to setup nwb tables
        for jj = 1 : sum(recdev{rd}.local_probes)

            % LFP AND MUA CALC
            nwb = proc_CDS(nwb, recdev{rd}, probe{probe_ctr+1});

            % BIN DATA
            if ~exist([pp.BIN_DATA nwb.identifier filesep ...
                    nwb.identifier '_probe-' num2str(probe{probe_ctr+1}.num) ...
                    '.bin'], 'file')
                proc_BIN(pp, nwb, recdev{rd}, probe{probe_ctr+1});
            end

            % SPIKE SORTING
            nwb = proc_SPK(pp, nwb, recdev{rd}, probe{probe_ctr+1});

            probe_ctr = probe_ctr + 1;

        end
    end
    
    workers = feature('numcores')*2;
    n_procd = n_procd + 1;
    nwbExport(nwb, [pp.NWB_DATA nwb.identifier '.nwb']);
    if strcmp(recording_info.Raw_Data_Path{ii}(1:2), '\\')
        fid = fopen([pp.SCRATCH '\proc_push_data.bat'], 'w');
        fprintf(fid, '%s\n', ...
            ['robocopy ' ...
            pp.NWB_DATA  ...
            ' ' ...
            recording_info.Raw_Data_Path{ii} ...
            ' *' ...
            [nwb.identifier '.nwb'] ...
            ' /j /np /mt:' ...
            num2str(workers)]);
        fclose('all');

        system([pp.SCRATCH '\proc_push_data.bat']);
        delete([pp.SCRATCH '\proc_push_data.bat']);
    end

    n_procd = n_procd + 1;

end
disp(['SUCCESSFULLY PROCESSED ' num2str(n_procd) ' FILES.'])
end

%% Deprecated (but maybe still useful) bits of code
% Read recording session information
% url_name = sprintf('https://docs.google.com/spreadsheets/d/%s/gviz/tq?tqx=out:csv&sheet=%s', ID, 1);
% recording_info = webread(url_name, webo);
%
% Process AIBS data
%     if strcmp(recording_info.Raw_Data_Format{ii}, 'AI-NWB')
%
%         raw_data_dir = [pp.RAW_DATA 'dandi' filesep '000253' ...
%             filesep 'sub_' recording_info.Subject{ii} ...
%             filesep 'sub_' recording_info.Subject{ii} ...
%             'sess_' num2str(recording_info.Session(ii)) ...
%             filesep 'sub_' recording_info.Subject{ii} ...
%             '+sess_' num2str(recording_info.Session(ii)) ...
%             '_ecephys.nwb'];
%
%         fpath = fileparts(raw_data_dir);
%
%         if ~exist(raw_data_dir, 'file')
%             warning('raw allen data not detected.')
%             continue
%         end
%
%         copyfile(raw_data_dir, [pp.NWB_DATA recording_info.Identifier{ii} '.nwb'])
%         nwb = nwbRead([pp.NWB_DATA recording_info.Identifier{ii} '.nwb']);
%
%         proc_AIC(pp, nwb, recording_info, ii, fpath);
%
%         n_procd = n_procd + 1;
%         continue
%
%     end
%
% Vanderbilt grab data
%     for rd = 1 : num_recording_devices
%
%         % RAW DATA
%         fd1 = findDir(pp.RAW_DATA, nwb.identifier);
%         fd2 = findDir(pp.RAW_DATA, ['dev-' num2str(rd-1)]);
%         raw_data_present = sum(ismember(fd2, fd1));
%         clear fd*
%
%         if ~raw_data_present
%
%             if (exist([pp.SCRATCH '\proc_grab_data.bat'],'file'))
%                 delete([pp.SCRATCH '\proc_grab_data.bat']);
%             end
%
%             fd1 = findDir(pp.DATA_SOURCE, nwb.identifier);
%             fd2 = findDir(pp.DATA_SOURCE, ['dev-' num2str(rd-1)]);
%             raw_data_temp = fd2(ismember(fd2, fd1));
%             raw_data_temp = raw_data_temp{1};
%
%             [~, dir_name_temp] = fileparts(raw_data_temp);
%
%             % Grab data if missing
%             workers = feature('numcores');
%             fid = fopen([pp.SCRATCH '\proc_grab_data.bat'], 'w');
%
%             fprintf(fid, '%s\n', ...
%                 ['robocopy ' ...
%                 raw_data_temp ...
%                 ' ' ...
%                 [pp.RAW_DATA dir_name_temp] ...
%                 ' /e /j /mt:' ...
%                 num2str(workers)]);
%
%             fclose('all');
%             system([pp.SCRATCH '\proc_grab_data.bat']);
%             delete([pp.SCRATCH '\proc_grab_data.bat']);
%
%         end
%     end