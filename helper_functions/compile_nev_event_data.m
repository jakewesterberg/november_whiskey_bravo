function [compiled_event_codes, compiled_event_times, ...
    compiled_event_infos, compiled_event_header, ...
    bad_blocks, bad_instance_specific_blocks, ...
    good_blocks] = ...
    compile_nev_event_data(dir_in, dir_out, pp, ident)

% event codes are the only temporally coherent signal sent to the
% different instances, therefore, lets use them to pad the data correctly.
% First we need to grab all codes and times...

n_event_threshold = 25;

logs = [];
logfile = findFiles(dir_in, 'log');
if isempty(logfile)
    files = findFiles(dir_in, '.mat');
    is_data = cellfun(@(files) extract(files, 'instance'), files, 'UniformOutput', false);
    is_para = cellfun(@(files) extract(files, 'params'), files, 'UniformOutput', false);
    is_log = find(cellfun(@isempty, is_data) & cellfun(@isempty, is_para));
    logs = files(is_log);
end

trial_param_files = findFiles(dir_in, 'trial_params'); %'.mat');

nevs = findFiles(dir_in, '.nev');
mats = findFiles(dir_in, 'ERF'); %'.mat');
if ~isempty(mats)
    mats = sort(mats);
end

n_blocks = strfind(lower(nevs), '_b');
val_past = 2;
if isempty(n_blocks)
    n_blocks = strfind(lower(nevs), 'block_');
    val_past = 6;
end

block_no = [];
for ii = 1: numel(n_blocks)
    n_end = strfind(nevs{ii}(n_blocks{ii}:end), '.'); %'/');
    block_no(ii) = str2double(nevs{ii}(n_blocks{ii}+val_past:n_blocks{ii}+n_end(1)-2));
end

n_instances = strfind(lower(nevs), 'instance');
instance_no = [];
for ii = 1: numel(n_instances)
    n_end = strfind(nevs{ii}(n_instances{ii}:end), '_');
    instance_no(ii) = str2double(nevs{ii}(n_instances{ii}+8:n_instances{ii}+n_end(1)-2));
end

unique_blocks = sort(unique(block_no));
unique_instances = sort(unique(instance_no));

compiled_event_codes = {};
compiled_event_times = {};
compiled_event_infos = {};
compiled_event_header = [];

for ii = 1 : numel(unique_blocks)

    if ~isempty(mats)
        if numel(mats) ~= numel(unique_blocks)
            txts = findFiles(dir_in, '.log');
            if numel(txts) ~= numel(unique_blocks)
                error('MISMATCHED NUMBER OF INFO FILES RELATIVE TO UNIQUE BLOCKS')
            else
                [MAT, compiled_event_header] = text_log_parse(txts{ii});
            end
        else
            load(mats{ii}, 'MAT', 'TZ')
        end

        if size(MAT, 2) > size(MAT, 1)
            MAT = MAT';
        end

        if exist('TZ', 'var')
            if size(MAT, 1) ~= TZ
                MAT = [MAT; zeros(TZ - size(MAT, 1), size(MAT, 2))];
            end
        end

        compiled_event_infos{ii} = MAT;

        clear MAT; if exist('TZ', 'var'); clear TZ; end
    end

    if ~isempty(logs)
        if numel(logs) ~= numel(unique_blocks)
            error('MISSING LOG FILES')
        else
            log = load(logs{ii});
            filepath = fileparts(logs{ii});
            allPara = log.allPara;
            allPara = [allPara; log.allValidTrialFlag; string(log.allerrorcodestr); log.allMicroStimFlag];
            load([pp.RAW_DATA ident filesep 'tracker_params.mat'])
            params = array2table(allPara', "VariableNames", var_names);
            trial_params_all{ii} = params;
            allPara2 = [];
            for ap = 1 : size(allPara,1)
                if ~unique(isnan(double(allPara(ap,:))))
                    allPara2(:,ap) = double(allPara(ap,:));
                else
                    allPara2(:,ap) = zeros(size(allPara,2),1);
                    allPara2(strcmp(allPara(ap,:), "correct"), ap) = 1; 
                end
            end
            compiled_event_infos{ii,1} = allPara2;
            compiled_event_header = cellstr(var_names);
        end
    end

    for jj = 1 : numel(unique_instances)
  
        found_file = false;
        while_ctr = 0;
        while ~found_file
            while_ctr = while_ctr + 1;

            if while_ctr <= numel(instance_no)
                if instance_no(while_ctr) == unique_instances(jj) & ...
                        block_no(while_ctr) == unique_blocks(ii)
                    temp_evts = openNEV(nevs{while_ctr}, 'nosave');
                    compiled_event_codes{ii, jj} = temp_evts.Data.SerialDigitalIO.UnparsedData;
                    compiled_event_times{ii, jj} = temp_evts.Data.SerialDigitalIO.TimeStamp';
                    clear temp_evts
                    found_file = true;
                end
            else
                warning('MISSING DATA FOR AN INSTANCE/BLOCK - NANing the data there...')
                found_file = true;
                compiled_event_codes{ii, jj} = [];
                compiled_event_times{ii, jj} = [];
            end
        end
    end
end

codes_per_block = median(cellfun(@numel, compiled_event_codes), 2);
bad_blocks = codes_per_block < n_event_threshold;
compiled_event_times = compiled_event_times(~bad_blocks,:);
compiled_event_codes = compiled_event_codes(~bad_blocks,:);

if ~isempty(compiled_event_infos)
    compiled_event_infos = compiled_event_infos(~bad_blocks,:);
end

if ~isempty(compiled_event_infos) & exist('trial_params_all', 'var')
    trial_params = vertcat(trial_params_all{~bad_blocks});
    trial_params.Properties.VariableNames = var_names;
    writetable(trial_params, [dir_out filesep 'trial_params.csv'])
end

bad_blocks = unique_blocks(bad_blocks);
good_blocks = unique_blocks(~bad_blocks);
if isempty(good_blocks)
    good_blocks = unique_blocks;
end

bisb = cellfun(@isempty, compiled_event_codes);
[bad_instance_specific_blocks(:,1), bad_instance_specific_blocks(:,2)] = ind2sub(size(bisb), find(bisb));

end

