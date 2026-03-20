function val = returnGSStr(dat, ii, jj)

temp_array_1 = strtrim(split(dat{ii}, ';'));
if ~exist('jj', 'var')
    val = temp_array_1;
else
    val = temp_array_1{jj};
    clear temp_array_1
end

end