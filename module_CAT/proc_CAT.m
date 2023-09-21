function proc_CAT(pp, nwb, rd, rii, recording_info)

switch recording_info.Raw_Data_Format{rii}
    case 'Blackrock NSx'

        if ~exist([pp.CAT_DATA filesep nwb.identifier '_dev-' num2str(rd-1)], 'dir')
            mkdir([pp.CAT_DATA filesep nwb.identifier '_dev-' num2str(rd-1)]);
        end

        [compiled_event_codes, compiled_event_times, ...
            compiled_event_infos, event_header, ...
            bad_blocks, bad_instance_specific_blocks] = ...
            compile_nev_event_data( ...
            ...recording_info.Raw_Data_Path{rii});
            [pp.RAW_DATA nwb.identifier], [pp.CAT_DATA nwb.identifier '_dev-' num2str(rd-1)], ...
            pp, nwb.identifier);

        code_of_interest = 2;
        [event_codes, event_times, event_infos, realigned_indices, block_lengths, nev_valid] = ...
            align_nev_event_data( ...
            compiled_event_codes, compiled_event_times, compiled_event_infos, code_of_interest);

        file_name = 'board-DIGITAL-IN-aggregated.mat';
        save([pp.CAT_DATA filesep nwb.identifier '_dev-' num2str(rd-1) filesep file_name], ...
            'event_codes', 'event_times', 'event_infos', 'event_header', '-v7.3', '-nocompression')

        clear compiled_event_codes compiled_event_times

        ns6s = findFiles([pp.RAW_DATA nwb.identifier], '.ns6');

        n_blocks = strfind(lower(ns6s), '_b');
        val_past = 2;
        if isempty(n_blocks)
            n_blocks = strfind(lower(ns6s), 'block_');
            val_past = 6;
        end

        block_no = [];
        for ii = 1: numel(n_blocks)
            n_end = strfind(ns6s{ii}(n_blocks{ii}:end), '.'); %'/');
            block_no(ii) = str2double(ns6s{ii}(n_blocks{ii}+val_past:n_blocks{ii}+n_end(1)-2));
        end
        block_no_offset = min(block_no) - 1;

        n_instances = strfind(lower(ns6s), 'instance');
        instance_no = [];
        for ii = 1: numel(n_instances)
            n_end = strfind(ns6s{ii}(n_instances{ii}:end), '_');
            instance_no(ii) = str2double(ns6s{ii}(n_instances{ii}+8:n_instances{ii}+n_end(1)-2));
        end

        for ii = sort(unique(instance_no))
            cat_data = [];
            block_tracker = 1;
            block_ref = 1;
            for jj = 1:numel(instance_no)
                if ismember(block_tracker, bad_blocks)
                    block_tracker = block_tracker + 1;
                end
                if ismember(block_tracker, bad_instance_specific_blocks(:,1)) & ...
                        ii == bad_instance_specific_blocks(:,2)
                    ch_ct = size(cat_data,1);
                    if ch_ct == 0
                        ch_ct = 144;
                    end
                    temp_data = zeros(ch_ct, numel(realigned_indices{block_ref, ii}), 'int16');
                    cat_data = [cat_data, temp_data];
                    clear temp_data temp_evts
                    block_tracker = block_tracker + 1;
                    block_ref = block_ref + 1;
                end
                if instance_no(jj) == ii & block_no(jj) - block_no_offset == block_tracker ...
                        & ~ismember(block_no(jj), bad_blocks)
                    temp_data = openNSx(ns6s{jj});
                    cat_data = [cat_data, temp_data.Data(:,realigned_indices{block_ref, ii})];
                    clear temp_data temp_evts
                    block_tracker = block_tracker + 1;
                    block_ref = block_ref + 1;
                end
            end

            for jj = 1 : 128
                if jj < 11
                    file_name = ['amp-' alphabet(ii) '-00' num2str(jj-1) '.dat'];
                elseif jj < 101
                    file_name = ['amp-' alphabet(ii) '-0' num2str(jj-1) '.dat'];
                else
                    file_name = ['amp-' alphabet(ii) '-' num2str(jj-1) '.dat'];
                end
                write_file_id = fopen([pp.CAT_DATA nwb.identifier '_dev-' num2str(rd-1) filesep file_name], 'w');
                fwrite(write_file_id, cat_data(jj,:), 'int16');
                fclose(write_file_id);
            end
            
            for jj = 129:144
                if size(cat_data, 1) >= jj
                    file_name = ['board-ANALOG-IN-' num2str((jj-128)+(16*(ii-1))) '.dat'];
                    write_file_id = fopen([pp.CAT_DATA filesep nwb.identifier '_dev-' num2str(rd-1) filesep file_name], 'w');
                    fwrite(write_file_id, cat_data(jj,:), 'int16');
                    fclose(write_file_id);
                end
            end
            clear cat_data
        end
end
end