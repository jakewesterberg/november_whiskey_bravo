function [MAT, MAT_header] = text_log_parse(file_path)

try
    text = readlines(file_path, 'Encoding', 'system');
    gen_info_start = find(contains(text, '#Parameters#'), 1);
    trial_info_start = find(contains(text, '*Trial info*'), 1);
    gen_info = text(gen_info_start+1:trial_info_start-1);
    trial_header = text(trial_info_start+1);
    trial_info = text(trial_info_start+2:end-1);

    gen_info_splice = split(gen_info, ' = ');
    gen_info_names = gen_info_splice(:,1);
    gen_info_values = gen_info_splice(:,2);

    MAT_header_temp = textscan(trial_header, '%s', 'Delimiter', ';')';
    MAT_header_temp{1}{1} =  MAT_header_temp{1}{1}(2:end);
    for ii = 1 : numel(MAT_header_temp{1})
        MAT_header{ii} = MAT_header_temp{1}{ii};
        if ii == numel(MAT_header_temp{1})
            MAT_header{ii} = 'TrialOutcome';
        end
    end

    trial_ct = size(trial_info,1);

    for ii = 1 : trial_ct
        MAT_temp = textscan(trial_info(ii), '%s', 'Delimiter', ';')';
        for jj = 1 : numel(MAT_temp{1})
            if ~isnan(str2double(MAT_temp{1}{jj}))
                MAT(ii,jj) = str2double(MAT_temp{1}{jj});
            else
                if strcmp(MAT_temp{1}{jj}, 'Error = CorrectFixation')
                    MAT(ii,jj) = 1;
                elseif strcmp(MAT_temp{1}{jj}, 'Error = StimBreak')
                    MAT(ii,jj) = 2;
                elseif strcmp(MAT_temp{1}{jj}, 'Error = PreFixBreak')
                    MAT(ii,jj) = 3;
                end
            end
        end
    end

    for ii = 1:numel(gen_info_names)
        giv_splice =str2double(erase(split(gen_info_values(ii), ', '), ';'));
        for jj = 1 : numel(giv_splice)
            MAT_header = [MAT_header {convertStringsToChars(strcat(gen_info_names(ii), "_", num2str(jj)))}];
            MAT = [MAT repmat(giv_splice(jj), trial_ct, 1)];
        end
    end
catch
    error('HAVING TROUBLE DECODING THE TEXT FILE!!!')
end

end

