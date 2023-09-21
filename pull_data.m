function pull_data(pp, rec_info)

tic
mkdir(pp.RAW_DATA, rec_info.Identifier{1})

switch rec_info.Raw_Data_Format{1}

    case 'Blackrock NSx'

        workers = feature('numcores')*2;

        dir_parts = strsplit(rec_info.Raw_Data_Path{1}, filesep);
        parent_path = strjoin(dir_parts(1:end-1), filesep);

        files = findFiles(rec_info.Raw_Data_Path{1}, '.', 0);

        fid = fopen([pp.SCRATCH '\proc_grab_data.bat'], 'w');
        fprintf(fid, '%s\n', ...
            ['robocopy ' ...
            rec_info.Raw_Data_Path{1}  ...
            ' ' ...
            [pp.RAW_DATA, rec_info.Identifier{1}] ...
            ' ' ...
            '*params*' ...
            ' /j /np /mt:' ...
            num2str(workers)]);
        fclose('all');
        system([pp.SCRATCH '\proc_grab_data.bat']);
        delete([pp.SCRATCH '\proc_grab_data.bat']);

        pat = "_B" + digitsPattern(3);
        block_assign_all = cellfun(@(files) extract(files, pat), files, 'UniformOutput', false);
%        block_assign = [block_assign_all{:}];
        for ii = 1:numel(files)
            
            if isempty(block_assign_all{ii})
                pat = "_B" + digitsPattern(2);
                temp_block_name = extract(files{ii}, pat);
                try
                    temp_block_name = ['_B0' temp_block_name{1}(end-1:end)];
                    block_assign_all{ii} = temp_block_name;
                    movefile(files{ii}, strrep(files{ii}, ['_B' temp_block_name(end-1:end)], temp_block_name));
                end
            end

            if isempty(block_assign_all{ii})
                pat = "_B" + digitsPattern(1);
                temp_block_name = extract(files{ii}, pat);
                try
                    temp_block_name = ['_B00' temp_block_name{1}(end)];
                    block_assign_all{ii} = temp_block_name;
                    movefile(files{ii}, strrep(files{ii}, ['_B' temp_block_name(end)], temp_block_name));
                end
            end

        end
        block_assign = [block_assign_all{:}];
%         pat = "_B" + digitsPattern(1) + "_";
%         block_assign_2 = cellfun(@(files) extract(files, pat), files, 'UniformOutput', false);
%         block_assign_2 = [block_assign_2{:}];
%         block_assign = [block_assign block_assign_2];
        unique_blocks = unique(block_assign);
        unique_blocks_ex = cellfun(@(unique_blocks) str2double(unique_blocks(3:end)), unique_blocks, 'UniformOutput', false);
        unique_blocks_val = [unique_blocks_ex{:}];

        blk_ctr = 0;
        for ii = unique_blocks_val
            blk_ctr = blk_ctr + 1;

            mkdir([pp.RAW_DATA, rec_info.Identifier{1}], ['Block_' num2str(ii)])

            fid = fopen([pp.SCRATCH '\proc_grab_data.bat'], 'w');
            fprintf(fid, '%s\n', ...
                ['robocopy ' ...
                rec_info.Raw_Data_Path{1}  ...
                ' ' ...
                [pp.RAW_DATA, rec_info.Identifier{1} '\' 'Block_' num2str(ii)] ...
                ' ' ...
                ['*' unique_blocks{blk_ctr} '*'] ...
                ' /j /np /mt:' ...
                num2str(workers)]);
            fclose('all');

            system([pp.SCRATCH '\proc_grab_data.bat']);
            delete([pp.SCRATCH '\proc_grab_data.bat']);

            if exist(['\' parent_path '\' 'logs'], 'dir')

                fid = fopen([pp.SCRATCH '\proc_grab_data.bat'], 'w');
                fprintf(fid, '%s\n', ...
                    ['robocopy ' ...
                    ['\' parent_path '\' 'logs']  ...
                    ' ' ...
                    [pp.RAW_DATA, rec_info.Identifier{1} '\' 'Block_' num2str(ii)] ...
                    ' ' ...
                    ['*_' num2str(rec_info.Session) '_B' num2str(ii) '.*'] ...
                    ' /j /np /mt:' ...
                    num2str(workers)]);
                fclose('all');

                system([pp.SCRATCH '\proc_grab_data.bat']);
                delete([pp.SCRATCH '\proc_grab_data.bat']);

            end

        end
end

disp(['PULLING DATA FROM SERVER TOOK: ' toc]);

end