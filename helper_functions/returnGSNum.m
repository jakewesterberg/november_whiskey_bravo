function val = returnGSNum(dat, ii, jj)
if ~exist('jj', 'var')
    reachmax = false;
    idx_ctr = 0;
    while ~reachmax
        idx_ctr = idx_ctr + 1;
        try
            if strcmp(class(dat), 'double')
                val(idx_ctr) = dat(ii);
            elseif strcmp(class(dat), 'cell')
                temp_array_1 = strtrim(split(dat{ii}, ';'));
                val(idx_ctr) = str2double(temp_array_1{idx_ctr});
                clear temp_array_1
            end
        catch
            reachmax = true;
        end
    end
else
    if strcmp(class(dat), 'double')
        val = dat(ii);
    elseif strcmp(class(dat), 'cell')
        temp_array_1 = strtrim(split(dat{ii}, ';'));
        val = str2double(temp_array_1{jj});
        clear temp_array_1
    end
end
end