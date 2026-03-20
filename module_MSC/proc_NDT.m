function nwb = proc_NDT(pp, nwb, recording_info, ii)

added_sec       = 0;

mua_data        = [];
lfp_data        = [];
pup_data        = [];
eye_data        = [];
stm_info        = [];

timestamps      = [];
blk_pts         = [];

for kk = returnGSNum(recording_info.Block_Specification, ii)

    blk_path = [pp.RAW_DATA nwb.identifier filesep 'block-' num2str(kk)];
    tdt_data = TDTbin2mat(blk_path);
    log_file = findFiles(blk_path, '.mat');
    log_data = load(log_file{1});

    if ~added_sec
        lfp_fs = tdt_data.streams.LFP1.fs;
        mua_fs = tdt_data.streams.ENV1.fs;
        eye_fs = tdt_data.streams.Eye_.fs;
    end

    min_length = min([ ...
        size(tdt_data.streams.Eye_.data,2), ...
        size(tdt_data.streams.ENV1.data,2), ...
        size(tdt_data.streams.ENV2.data,2), ...
        size(tdt_data.streams.LFP1.data,2), ...
        size(tdt_data.streams.LFP2.data,2) ...
        ]);

    tmp_blk_pts(1) = added_sec;
    tmp_blk_pts(3) = size(eye_data, 2) + 1;

    eye_data = [eye_data, tdt_data.streams.Eye_.data(1:2, 1:min_length)];

    pup_data = [pup_data, tdt_data.streams.Eye_.data(3:4, 1:min_length)];

    mua_data = [mua_data,   [tdt_data.streams.ENV1.data(:, 1:min_length); ...
        tdt_data.streams.ENV2.data(:, 1:min_length)]];

    lfp_data = [lfp_data,   [tdt_data.streams.LFP1.data(:, 1:min_length); ...
        tdt_data.streams.LFP2.data(:, 1:min_length)]];

    timestamps = [timestamps, added_sec : 1/mua_fs : added_sec+1/mua_fs*min_length];

    if size(log_data.STMMAT, 1) ~= numel(tdt_data.epocs.Corr.onset)
        warning('MISMATCHED STM MAT SIZE AND CORRECT TRIALS')
        if size(log_data.STMMAT, 1) > numel(tdt_data.epocs.Corr.onset)
            log_data.STMMAT = log_data.STMMAT(1:numel(tdt_data.epocs.Corr.onset),:);
        elseif size(log_data.STMMAT, 1) < numel(tdt_data.epocs.Corr.onset)
            tdt_data.epocs.Corr.onset = tdt_data.epocs.Corr.onset(1:size(log_data.STMMAT, 1));
            tdt_data.epocs.Corr.offset = tdt_data.epocs.Corr.offset(1:size(log_data.STMMAT, 1));
        end
    end

    tmp_stm_times       = nan(numel(tdt_data.epocs.Corr.onset), 1);
    tmp_stm2rew_times   = nan(numel(tdt_data.epocs.Corr.onset), 1);
    for jj = 1 : numel(tdt_data.epocs.Corr.onset)
        tmp_diffs                   = tdt_data.epocs.Corr.onset(jj) - tdt_data.epocs.Stim.onset;
        tmp_diffs(tmp_diffs < 0)    = [];
        [tmp_stm2rew_times(jj,1), tmp_stm_times(jj)]      = min(tmp_diffs);
    end

    tmp_times = [   tdt_data.epocs.Stim.onset(tmp_stm_times), ...
        tdt_data.epocs.Stim.offset(tmp_stm_times), ...
        tdt_data.epocs.Corr.onset, ...
        tdt_data.epocs.Corr.offset    ];

    t_max       = min_length / mua_fs;

    tmp_info                                = [tmp_times, tmp_stm2rew_times, log_data.STMMAT];
    tmp_info(tmp_info(:,4) > t_max, :)      = [];
    tmp_info(:,1:4)                         = tmp_info(:,1:4)  + added_sec;

    tmp_info = [tmp_info, zeros(size(tmp_info, 1), 1) + kk];

    stm_info = [stm_info; tmp_info];

    added_sec   = added_sec + t_max + 1/tdt_data.streams.ENV1.fs;

    tmp_blk_pts(2) = added_sec;
    tmp_blk_pts(4) = size(eye_data, 2);

    blk_pts = [blk_pts; tmp_blk_pts];

end

%%%%%%% MAPPING DOES NOT SEEM TO BE REQUIRED FOR THE 2DMAP FILES - LOOKS
%%%%%%% LIKE IT IS ALREADY MAPPED FROM COMPARISONS WITH THE PREPROCESSED
%%%%%%% DATAFILES.
if strcmp(recording_info.Subject{ii},'Bo')

    chnorder1 = [88 84 80 76 72 68 60 6 2 8 86 82 78 64 56 52 21 23 4 66 74 70 71 67 17 19 7 11 62 50 69 63 13 15 91 3 54 58 65 59 9 5 87 83 95 57 61 55 1 93 85 79 75 96 92 53 89 81 77 73 94 90 49 51 24 20 16 12 22 18 14 10 26 30 34 38 42 46 25 29 33 37 41 45 28 32 36 40 44 48 27 31 36 39 43 47];
    chnorder2 = [88 84 80 76 72 68 60 6 2 8 86 82 78 64 56 52 21 23 4 66 74 70 71 67 17 19 7 11 62 50 69 63 13 15 91 3 54 58 65 59 9 5 87 83 95 57 61 55 1 93 85 79 75 96 92 53 89 81 77 73 94 90 49 51 32 28 24 20 16 12 30 26 22 18 14 10 42 46 25 29 33 37 41 45 28 32 36 40 44 48 27 31 36 39 43 47];
    %Chnorders are subtley different between the two!
    chnorder = [chnorder2,chnorder1+96];
    chnorder = chnorder([1:76, 97:116]);
% 
% %     unmapped_mapping = [45 88 84 80 76 72 68 60 47 6 2 8 86 82 78 64 56 52 41 43 21 23 4 ...
% %         66 74 70 71 67 39 37 17 19 7 11 62 50 69 63 35 33 13 15 91 3 54 ...
% %         58 65 59 31 29 9 5 87 83 95 57 61 55 25 27 1 93 85 79 75 96 92 53 ...
% %         46 48 44 89 81 77 73 94 90 49 42 40 36 32 28 24 20 16 12 51 38 ...
% %         34 30 26 22 18 14 10];
% 
%     unmapped_mapping = [    88 84 80 76 72 68 60 6  2  8  86 82 78 64 56 52 21 23 4  66 ...
%                             74 70 71 67 17 19 7  11 62 50 69 63 13 15 91 3  54 58 65 59 ...
%                             9  5  87 83 95 57 61 55 1  93 85 79 75 96 92 53 89 81 77 73 ...
%                             94 90 49 51 32 28 24 20 16 12 30 26 22 18 14 10 ...
%                             42 46 25 29 33 37 41 45 28 32 36 40 44 48 27 31 36 39 43 47     ];
% 
%     mua_data = mua_data(unmapped_mapping, :);
%     lfp_data = lfp_data(unmapped_mapping, :);
% 
elseif strcmp(recording_info.Subject{ii},'Da')
% 
%     unmapped_mapping = [45 88 84 80 76 72 68 60 47 6 2 8 86 82 78 64 56 52 41 43 21 23 4 ...
%         66 74 70 71 67 39 37 17 19 7 11 62 50 69 63 35 33 13 15 91 3 54 ...
%         58 65 59 31 29 9 5 87 83 95 57 61 55 25 27 1 93 85 79 75 96 92 53 ...
%         46 48 44 89 81 77 73 94 90 49 42 40 36 32 28 24 20 16 12 51 38 ...
%         34 30 26 22 18 14 10];
% 
%     unmapped_mapping = [unmapped_mapping unmapped_mapping+96];
% 
%     mua_data = mua_data(unmapped_mapping, :);
%     lfp_data = lfp_data(unmapped_mapping, :);
% 
end

temp_fields = { ...
    'start_time', 'stop_time', 'reward_on_time', 'reward_off_time', 'stim2rew_time',...
    'trial_number', 'digital_word', 'x_pos_idx', 'y_pos_idx', ...
    'figure_tilt_idx', 'x_pos_pix', 'y_pos_pix', 'block_number'};

if size(stm_info, 2) < numel(temp_fields)
    stm_info = [stm_info(:,1:9), zeros(size(stm_info, 1), 1)-1, stm_info(:,10:end)];
end

stm_info = [stm_info, zeros(size(stm_info, 1), 1)+log_data.GridSz];
temp_fields = [temp_fields, 'pix_per_deg'];

if          strcmp(recording_info.Preprocess_Notes{ii}, '4dva texture figure/ground')

    stm_info = [stm_info, zeros(size(stm_info, 1), 1) + 4];
    stm_info = [stm_info, ones(size(stm_info, 1), 1)];
    stm_info = [stm_info, zeros(size(stm_info, 1), 1)];

elseif      strcmp(recording_info.Preprocess_Notes{ii}, '7dva texture figure/ground')

    stm_info = [stm_info, zeros(size(stm_info, 1), 1) + 7];
    stm_info = [stm_info, ones(size(stm_info, 1), 1)];
    stm_info = [stm_info, zeros(size(stm_info, 1), 1)];

elseif      strcmp(recording_info.Preprocess_Notes{ii}, '4dva black-white figure/ground')

    stm_info = [stm_info, zeros(size(stm_info, 1), 1) + 4];
    stm_info = [stm_info, zeros(size(stm_info, 1), 1)];
    stm_info = [stm_info, ones(size(stm_info, 1), 1)];

elseif      strcmp(recording_info.Preprocess_Notes{ii}, '7dva black-white figure/ground')

    stm_info = [stm_info, zeros(size(stm_info, 1), 1) + 7];
    stm_info = [stm_info, zeros(size(stm_info, 1), 1)];
    stm_info = [stm_info, ones(size(stm_info, 1), 1)];

end

temp_fields = [temp_fields, 'figure_size_dva', 'figure_texture_version', 'figure_blackwhite_version'];

eval_str = [];
for kk = 1 : numel(temp_fields)
    eval_str = ...
        [ eval_str ...
        ',convertStringsToChars("' ...
        temp_fields{kk} ...
        '"), types.hdmf_common.VectorData(convertStringsToChars("data"), stm_info(:,' num2str(kk) ')' ...
        ', convertStringsToChars("description"), convertStringsToChars("placeholder"))'];
end
eval_str = [
    'trials=types.core.TimeIntervals(convertStringsToChars("description"), convertStringsToChars("events"), convertStringsToChars("colnames"),temp_fields' ...
    eval_str ');'];

eval(eval_str); clear eval_str
nwb.intervals.set('FigureGround_2DMap', trials); clear trials

nwb.general_extracellular_ephys_electrodes = nwb.general_extracellular_ephys_electrodes;

% eye data
eye_position = types.core.SpatialSeries( ...
    'description', 'The position of the eye. Actual sampling rate different than reported (Actual=240Hz)', ...
    'data', eye_data, ...
    'starting_time_rate', eye_fs, ... % Hz
    'timestamps', timestamps, ...
    'timestamps_unit', 'seconds' ...
    );

eye_tracking = types.core.EyeTracking();
eye_tracking.spatialseries.set('eye_1_tracking_data', eye_position);
nwb.acquisition.set('eye_1_tracking_dev_0', eye_tracking);

pup_data = (mean(pup_data)/2 .* pi).^2;
pupil_diameter = types.core.TimeSeries( ...
    'description', 'Pupil diameter.', ...
    'data', pup_data, ...
    'starting_time_rate', eye_fs, ... % Hz
    'data_unit', 'arbitrary units', ...
    'timestamps', timestamps, ...
    'timestamps_unit', 'seconds' ...
    );

pupil_tracking = types.core.PupilTracking();
pupil_tracking.timeseries.set('pupil_1_diameter_data', pupil_diameter);
nwb.acquisition.set('pupil_1_tracking_dev_0', pupil_tracking);

% Create device
e_variables = {'location', 'group', 'label' ,'probe', ...
    'probe_mean_rf_x', 'probe_mean_rf_y', ...
    'rf_center_x', 'rf_center_y', ...
    'rf_x', 'rf_y', ...
    'rf_size_x', 'rf_size_y', ...
    'rf_correlation_r'};
electrode_table = [];

probe_ctr = -1;
ielec_ctr = 0;
for jj = returnGSStr(recording_info.Probe_Ident,ii)'

    try jj{1}(1);
    catch
        continue
    end

    probe_ctr = probe_ctr + 1;

    device = types.core.Device(...
        'description', jj{1}, ...
        'manufacturer', 'Blackrock Neurotech', ...
        'probe_id', probe_ctr, ...
        'sampling_rate', mua_fs ...
        );

    nwb.general_devices.set(['probe' alphabet(probe_ctr+1)], device);

    electrode_group = types.core.ElectrodeGroup( ...
        'has_lfp_data', true, ...
        'lfp_sampling_rate', lfp_fs, ...
        'probe_id', probe_ctr, ...
        'description', ['electrode group for probe' alphabet(probe_ctr+1)], ...
        'location', returnGSStr(recording_info.Area, ii, probe_ctr+1), ...
        'device', types.untyped.SoftLink(device) ...
        );

    nwb.general_extracellular_ephys.set(['probe' alphabet(probe_ctr+1)], electrode_group);

    group_object_view = types.untyped.ObjectView(electrode_group);

    ind_e_table = cell2table(cell(0, length(e_variables)), ...
        'VariableNames', e_variables);

    for ielec = 0:returnGSNum(recording_info.Probe_Channels, ii, probe_ctr+1)-1

        ielec_ctr = ielec_ctr + 1;

        probe_label = ['probe' alphabet(probe_ctr+1)];
        electrode_label = ['probe' alphabet(probe_ctr+1) '_e' num2str(ielec)];

        switch recording_info.Subject{ii}
            case 'Bo'

                ctx = [15.4716440774010	    0.532121919211876	0.812258333914299	0.528925721955339	0.955925540891148	15.0858989533806	0.494214216748689	15.3339676049340	15.4894676307741	15.4718721582269	0.599861426135070	1.39746683115801	0.741819251340415	0.470362295573585	0.733930491445757	0.961176227352456	0.488254399223683	0.511110632239706	15.8457972179544	1.56726245888258	6.44938149521198	15.4479607254067	15.4481741361738	-0.375859549583065	-0.388025231370664	15.4515899133787	-0.466199405766973	5.65111601396018	-0.144005644188364	0.240963610422276	-3.34587071551131	15.7838000881591	-3.22294703536343	-0.212576211042796	9.39330342136067	5.15748900068450	-3.60642033294257	9.40557044922444	-2.09026013258932	-3.30561882148381	1.11652549174852	1.13607799583531	1.89045272316271	0.915136886787329	1.95107798463229	1.87854417479186	2.82972691655837	2.90306895096214	2.48777443242998	2.35040244275833	2.14747161666227	9.79026932649073	2.34028074621740	2.45617294567542	2.99847403965186	3.92658805957203	2.06408079274835	2.08484669026227	2.98825690637312	-2.09514559133682	6.41340174392366	3.14684913686457	3.31100665281699	-3.17308718863029	5.06118742064360	4.92567109700351	4.12110177725180	4.84942957200225	5.64132875178065	5.97877271912245	9.64653651888255	5.83589364287913	6.44474608826081	6.07491414899210	6.41529265023804	6.22444773005093	15.3571642446681	1.09909033714935	1.55297405406794	1.37020242521675	1.38768866497577	0.874151502418828	1.01781490991588	1.33399329859214	1.32769912673387	0.972146709437027	1.05244263683073	1.84013951235826	1.56374940410698	1.51755282217838	0.990317762893134	0.159575427721777	1.58960217591902	1.18580146137966	1.37617584156468	0.509342773346941];
                cty = [-9.12667250359993	-2.13479032082274	-0.0874130977121419	-2.49021778918241	-1.22891909462029	-10.9589905844028	-2.03372543910771	-9.96340265272420	-9.07255795637378	-9.05551697970500	-1.35101661453450	-2.17122246231418	-1.07362149307560	-1.60964348701573	-1.35372520834695	-1.66963127411616	-1.98134328321565	-1.26452302047710	5.10531773579647	-1.79452621216237	1.80298016395443	-9.10222370919702	-9.14705825582950	-3.55569050883394	-4.29946660111802	-9.18043272607210	-4.22276563490362	-12.3804135406834	-3.74908202814970	-3.60073207107955	-10.7005699097793	-9.03878828875179	-9.57967576298618	-4.32671210995420	-0.0867985403567807	-13.4544846562664	-11.1854577216076	-10.0815841008130	-13.7228749274777	-2.03004625753827	-4.15313332966032	-4.26079039090867	-5.11396420819761	-3.63627629637087	-3.78574725075587	-3.78876624064140	-4.69326927710931	-4.58327223435050	-3.75221803800757	-3.74116511217639	-4.09641360790397	2.48529471649685	-3.65698485459758	-3.54456431680746	-4.05787168511569	-4.49866007651644	-3.39350883844095	-3.44730388180924	-3.27712619601111	2.87623615098999	-11.4436615814045	-7.61293226413595	-10.0949719880420	-1.46187807039704	-7.72195847234281	-8.36231910185453	-10.2780236522074	-10.3290393037975	-6.73716907354486	-7.67369106634602	-4.72757930871079	-10.7699816628895	-7.13564084576439	-7.55940487165435	-8.40532648483406	-10.5626198813840	-7.09773756541934	-3.11888939259289	-3.12399319831761	-2.72774973626982	-2.09598906200049	-3.34056430695175	-3.19526544636773	-2.26633457108632	-2.64820087814028	-3.06983953453794	-3.13501000851603	-2.35024645418392	-1.59895489781897	-2.54307069540828	-2.59189980106818	-2.05961155955414	-3.16716444575433	-2.47193325143464	-1.84257883485051	-3.48102581367049];
                rfx = [-9.35824801345139	0.0610385406179286	-30225258.9950358	0.552931069446826	1.01867938556237	-2970.40132321698	16.0929273978078	-291550208123.572	-2555.17646202687	-1426.73499092347	799.189562222051	1.45315004416982	0.782375805743526	0.509366257725135	0.811121815098885	1.09856293669730	-2297.35584585764	0.390737912021177	15.1345953051881	1.60113194284309	6.39408799259365	0.201495839952556	-188.299204985576	-1587.34739485769	-0.418642566881744	-0.440774660414332	-0.0468465832588076	-120208.039388966	-0.482485326273765	-0.401918880674061	-69.8847263904578	-0.591016406418265	-1138.39932845801	-0.105893565201039	5.92339175655507	-88.1241275993165	14.0766018018342	4.14752600564601	0.102940322210324	11.6136994002377	1.26359144145245	1.53951569410329	2.15579953954392	-7.48468612206433	2.13711161189057	2.18273514318498	2.97976653689793	3.03709096388263	2.87316332414541	2.60961882900894	2.65278109849748	-15.2145354849905	2.41580170682861	2.68339847779297	3.00725536858720	4.11507811068379	2.27182961501123	2.51957613249287	3.15741576233698	2062.25734974273	-617.944160217523	3.68800592318172	3.58223854036256	14.0354104091742	5.57419563783455	5.40612091128073	4.37797565460908	4.64234811917920	6.36064036736297	6.02607936300859	15.0656486964627	5.79745472252789	6.86293512982698	6.90865287899931	7.49170847917922	6.72277890481351	0.690639374630950	0.952047867424413	1.19538428138791	1.28683322898410	0.796304455089805	0.947093013759161	1.22298023999956	1.46420715039759	0.942448195858968	1.02666706177294	1.24436391186792	1.48736841834314	0.922225261839133	1.00030606286426	1.21323776017633	13.6800561479539	0.912822717757725	1.32214205528762	1.32171470251721	1.43800078697066];
                rfy = [-30.7705741230826	-1.64573801046301	-99779965.1541655	-2.03840831933706	-1.26514500101253	-3970.43919451485	-6.94706465138371	-522403934492.701	-3767.12622986294	-1902.28261144813	399.122623530028	-1.80499965280238	-0.956200020679763	-1.50980191516287	-1.12563118300914	-1.57046194680524	-3425.81679194847	-1.34290047390261	5.97891372089949	-1.60742928096285	1.97851089556589	-11.8185187523895	-13.6212973640694	-1866.74474798694	-4.20376093224463	-2.83113526333135	-4.40424591726863	-134044.704750844	-4.27867064555841	-4.19695894271197	-139.245232732143	-3.29032362354411	-1424.71961305440	-4.49106198542343	4.68498088902805	-86.3089324750121	-8.71128817874551	-3.86670170794185	-0.0619569997863741	-1.60678118182522	-4.14727848858685	-5.06511615457801	-5.59852595155464	-31.0166808794652	-4.04606081792364	-4.10503934542040	-5.02086818822624	-4.61288405531556	-4.13354045589071	-4.04009564592881	-4.28365192383004	-8.54075396172373	-3.68887147098816	-3.49233363389858	-3.98845538600674	-4.69242086784762	-3.18561994276893	-3.30154604578699	-3.34189275471850	5489.41452222675	-761.571385960146	-9.03878926555776	-10.2281029812602	-7.96401538123381	-8.36201487001241	-9.22960135653239	-10.7983330158434	-10.5311742693602	-7.35268953024436	-8.40822350973060	4.00778446324992	-10.6868795677762	-7.64766098618044	-8.68684977569885	-8.89672074945475	-10.8406720469357	-0.242189797793448	-2.64312896854683	-2.52742708572585	-2.48858565876912	-2.91675730720141	-2.84845037809670	-2.68770991213391	-2.63846189450433	-2.98063671181045	-2.77598085975655	-2.70753340336496	-2.66497572534069	-2.87297789262356	-2.96320255873493	-2.93339212849179	-9.76388541150369	-3.03495384458629	-3.11674138603546	-2.95245472175715	-3.12910653612464];
                xsz = [0.758035396473558	1.17337509579821	3964448.04626402	1.62842313290618	1.10980464540475	110.478530545760	0.392986270255628	4889582923.23358	63.6103103823521	37.1530962387657	582.187746012293	1.84489783802811	1.58923958970271	1.49517186183908	1.60901224390530	1.65370671265286	93.0010113600269	1.35070831055184	0.354468050460498	1.79425297501645	1.03921550328061	0.528039168850315	6935.05769579021	121.758018508038	0.995500022003897	0.439344329395867	1.67442697520591	9838.87069903197	0.905855122279778	1.16276819160385	97.9616037102801	1.08317486943918	39.1362320109618	1.03659291610382	0.888431469902161	68.8232380276476	0.714695141471585	0.994958205878056	1.66518909242408	0.375484299005782	2.61260662574941	2.77470950995631	2.78841211296291	1.07324201988040	2.74848232412078	2.95083167767867	3.00120178592027	2.86377630416766	2.99597083360816	2.61481955580130	2.81092536179748	13.2354271851309	2.51542133797994	2.56356244914304	2.62086229767116	3.21279547550500	2.49347271890436	2.83515266297283	2.31429682759333	25.6241596256745	18.9542331093477	4.85875921338749	5.25259966647911	0.445180004888212	4.24329116592653	5.61769652168864	6.69030102921306	5.17621968449017	4.04419496331094	4.45510734147996	0.480505090859412	5.26770467481027	3.81593805044168	5.39949878797740	5.08315455372962	5.09181447748176	0.985683581968105	0.845016655175910	0.704504501204478	0.778583039607953	0.802830044523263	0.603305334783068	0.738511791554636	0.844918745791827	0.686377403537945	0.784061815478641	0.811294361407495	0.774467128504755	0.968947110792437	0.876837247573307	0.673023303321961	0.422028973567157	0.763226106644297	0.701840026847448	0.830508651480040	0.760854250171977];
                ysz = [21.4544255724658	    2.59946014889744	64431068.2170462	1.95777789321373	1.31636637234751	3430.02230909668	0.480734354234855	399640635742.451	2642.03918937748	1645.78081880182	92.2015207443795	1.77798938963575	2.04869850392358	1.84602422957728	2.70947607950988	1.66871289410765	2233.02411840107	1.89939874648722	0.701639214901985	1.37813541788328	0.838859686749566	0.713664955823135	0.297753071623695	1714.66658761333	0.794236439035131	3.11581938458875	0.926538225523917	120481.570584889	1.02595603455092	0.723206018425389	71.2012763739348	3.70650827072607	928.553763002720	1.05546586750436	0.516126953150871	17.4217413689103	0.920732269601253	1.09850967408477	-1.61399825177209e-05	5.77637183157365	2.65739250866716	3.09027245468496	2.88813976064953	19.7201420503010	2.25255370798847	2.31849018175977	2.50686400409526	2.04883558180994	2.18124074366454	2.10877050671894	2.31233014550731	0.472935181221758	1.96906045818879	1.97967518571097	2.10430481430850	2.33836199398246	2.40559120415396	2.24761443031166	2.21636855470648	4199.65125792397	569.990659295515	3.95800766061639	3.93425437214177	0.433273668808141	3.19282342711248	3.91194824157470	4.37565239834932	3.49775051450787	2.94652475877344	3.05309718785764	0.931066418789267	3.77445273094968	3.39979695011902	3.78636854581299	3.75690138712402	3.66373037119679	0.432004666455463	1.12869286045488	0.907824687674588	0.819574915456848	0.581977155716754	0.630467569201026	0.820957943680052	0.783339946666514	0.614916943148941	0.930396795831722	0.932692612265536	0.840423439254806	0.707857215654665	0.794950927299619	0.774655812336516	2.06014217464485	0.873284912501534	0.707692983432631	0.772966269422397	0.667195490862282];
                rfr = [0.0129506135701767	0.0706571053983325	9.33636668872198e-07	0.542937306351759	0.481003383842179	0.00125115430675666	0.0212707225828308	0.000970121236468144	0.00188477874875165	0.00193167624353627	0.00112487164261491	0.396529504400383	0.226226151244924	0.227327690421906	0.125025671406446	0.258593395771018	0.000432496777821867	0.116247530752018	0.0447825310475249	0.403197748803619	0.0298261114766811	0.0198498081045737	0.0107606079339533	0.00174780706842126	0.348932865493907	0.0358665762291091	0.0686944706137846	2.43843887139999e-07	0.387104869066140	0.113543853189592	0.00819758664352073	0.0296263237852283	0.00536425014432634	0.225038878854208	0.0144289724341895	0.0153429737469585	0.0304484140958274	0.0358027331567256	0.0316080864917261	0.0147657542916540	0.419116795081803	0.220164887662232	0.231797616188725	0.0118765944385986	0.650892565090674	0.666325092563631	0.640835311757567	0.238536114897799	0.481421720356632	0.748117330528304	0.610838856371874	0.0247130852265456	0.233615935157320	0.664569382199714	0.429222504329807	0.662722829495424	0.416528005104561	0.107598119473940	0.459849334364234	6.49064689049516e-05	0.0204659010793369	0.860527895948964	0.830556005046489	0.0442139001626938	0.836884130598097	0.889081606881181	0.916713899460982	0.785431724277067	0.748939217415663	0.575074636842751	0.0221959416522409	0.847683769192607	0.786195078603567	0.772147080550080	0.764495827758376	0.838311817175519	0.0302075956932672	0.354874490547029	0.286956612837781	0.306089079479490	0.308976940922492	0.319244705534629	0.344315809098612	0.297758984708570	0.212264531263033	0.210781791853916	0.323652491383272	0.392236910250008	0.133181981579769	0.150523651831455	0.333245339305968	0.0297453490987371	0.122944970797522	0.146525145883084	0.202796131838709	0.211178688972859];

                if probe_ctr == 0
                    probe_mean_rf_x = 0.87;
                    probe_mean_rf_y = -1.63;
                elseif probe_ctr == 1
                    probe_mean_rf_x = -0.13;
                    probe_mean_rf_y = -3.99;
                elseif probe_ctr == 2
                    probe_mean_rf_x = 2.33;
                    probe_mean_rf_y = -3.99;
                elseif probe_ctr == 3
                    probe_mean_rf_x = 5.23;
                    probe_mean_rf_y = -8.71;
                elseif probe_ctr == 4
                    probe_mean_rf_x = 1.25;
                    probe_mean_rf_y = -2.71;
                end

                ind_e_table = [ind_e_table; {...
                    returnGSStr(recording_info.Area, ii, probe_ctr+1),  ...
                    group_object_view, ...
                    electrode_label, ...
                    probe_label, ...
                    probe_mean_rf_x, ...
                    probe_mean_rf_y, ...
                    ctx(ielec_ctr), ...
                    cty(ielec_ctr), ...
                    rfx(ielec_ctr), ...
                    rfy(ielec_ctr), ...
                    xsz(ielec_ctr), ...
                    ysz(ielec_ctr), ...
                    rfr(ielec_ctr)}];


            case 'Da'

                ind_e_table = [ind_e_table; {...
                    returnGSStr(recording_info.Area, ii, probe_ctr+1),  ...
                    group_object_view, ...
                    electrode_label, ...
                    probe_label, ...
                    0, ...
                    0, ...
                    0, ...
                    0, ...
                    0, ...
                    0, ...
                    0, ...
                    0, ...
                    0}];


        end
    end

    electrode_table = [electrode_table; ind_e_table];

end

nwb.general_extracellular_ephys_electrodes = util.table2nwb(electrode_table);

e_ctr = 0;
probe_ctr = 0;
for jj = 1 : recording_info.Probe_Count(ii)

    electrode_table_region = types.hdmf_common.DynamicTableRegion( ...
        'table', types.untyped.ObjectView(nwb.general_extracellular_ephys_electrodes), ...
        'description', ['probe' alphabet(probe_ctr+1)], ...
        'data', (0+e_ctr:returnGSNum(recording_info.Probe_Channels, ii, probe_ctr+1)+e_ctr-1)');

    lfp_electrical_series = types.core.ElectricalSeries( ...
        'electrodes', electrode_table_region,...
        'starting_time', 0.0, ... % seconds
        'starting_time_rate', lfp_fs, ... % Hz
        'data', lfp_data(e_ctr+1:returnGSNum(recording_info.Probe_Channels, ii, probe_ctr+1)+e_ctr, :), ...
        'data_unit', 'uV', ...
        'filtering', '???', ...
        'timestamps', timestamps);

    lfp_series = types.core.LFP(['probe_' num2str(probe_ctr) '_lfp_data'], lfp_electrical_series);
    nwb.acquisition.set(['probe_' num2str(probe_ctr) '_lfp'], lfp_series);

    muae_electrical_series = types.core.ElectricalSeries( ...
        'electrodes', electrode_table_region,...
        'starting_time', 0.0, ... % seconds
        'starting_time_rate', mua_fs, ... % Hz
        'data', mua_data(e_ctr+1:returnGSNum(recording_info.Probe_Channels, ii, probe_ctr+1)+e_ctr, :), ...
        'data_unit', 'uV', ...
        'filtering', '???', ...
        'timestamps', timestamps);

    muae_series = types.core.LFP(['probe_' num2str(probe_ctr) '_muae_data'], muae_electrical_series);
    nwb.acquisition.set(['probe_' num2str(probe_ctr) '_muae'], muae_series);

    e_ctr = e_ctr + returnGSNum(recording_info.Probe_Channels, ii, probe_ctr+1);
    probe_ctr = probe_ctr + 1;

end

nwbExport(nwb, [pp.NWB_DATA nwb.identifier '.nwb']);

end