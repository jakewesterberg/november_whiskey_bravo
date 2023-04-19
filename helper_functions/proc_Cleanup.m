function proc_Cleanup(pp, keepers)

if nargin < 2
    keepers = {'RAW', 'NWB'};
end

if (exist([pp.SCRATCH '\i2n_cleanup.bat'],'file'))
    delete([pp.SCRATCH '\i2n_cleanup.bat']);
end

% Cleanup
workers = feature('numcores');
fid = fopen([pp.SCRATCH '\i2n_cleanup.bat'], 'w');

% RAW DATA
if any(strcmp(keepers, 'RAW'))
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.RAW_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_0_RAW_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /j /mt:' ...
        num2str(workers) ' &']);
else
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.RAW_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_0_RAW_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /move /j /mt:' ...
        num2str(workers) ' &']);
end

% RAW DATA
if any(strcmp(keepers, 'CAT'))
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.CAT_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_1_CAT_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /j /mt:' ...
        num2str(workers) ' &']);
else
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.CAT_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_1_CAT_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /move /j /mt:' ...
        num2str(workers) ' &']);
end

% RAW DATA
if any(strcmp(keepers, 'BIN'))
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.BIN_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_2_BIN_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /j /mt:' ...
        num2str(workers) ' &']);
else
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.BIN_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_2_BIN_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /move /j /mt:' ...
        num2str(workers) ' &']);
end

% RAW DATA
if any(strcmp(keepers, 'SPK'))
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.SPK_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_3_SPK_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /j /mt:' ...
        num2str(workers) ' &']);
else
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.SPK_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_3_SPK_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /move /j /mt:' ...
        num2str(workers) ' &']);
end

% RAW DATA
if any(strcmp(keepers, 'SSC'))
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.SSC_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_4_SSC_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /j /mt:' ...
        num2str(workers) ' &']);
else
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.SSC_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_4_SSC_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /move /j /mt:' ...
        num2str(workers) ' &']);
end

% RAW DATA
if any(strcmp(keepers, 'CNX'))
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.CNX_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_5_CNX_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /j /mt:' ...
        num2str(workers) ' &']);
else
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.CNX_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_5_CNX_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /move /j /mt:' ...
        num2str(workers) ' &']);
end

% NWB DATA
if any(strcmp(keepers, 'NWB'))
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.NWB_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_6_NWB_DATA' ...
        ' /xf "manifest.txt"' ... ...
        ' /e /j /mt:' ...
        num2str(workers) ' &']);
else
    fprintf(fid, '%s\n', ...
        ['robocopy ' ...
        pp.NWB_DATA(1:end-1) ...
        ' ' ...
        pp.DATA_DEST '_6_NWB_DATA' ...
        ' /xf "manifest.txt"' ...
        ' /e /move /j /mt:' ...
        num2str(workers) ' &']);
end

fclose('all');

system([pp.SCRATCH '\i2n_cleanup.bat']);

end