function [realigned_nev_event_codes, realigned_nev_event_times, ...
    realigned_nev_event_infos, realigned_indices, block_lengths, ...
    nev_valid] = ...
    align_nev_event_data(compiled_nev_event_codes, compiled_nev_event_times, ...
    compiled_nev_event_infos, events_of_interest)

if nargin < 3
    compiled_nev_event_infos = {};
end
if nargin < 4
    events_of_interest = 2;
end

realigned_indices = {};

for ii = 1 : size(compiled_nev_event_codes, 1)

    temp_events = [];
    temp_times = [];
    for jj = 1 : size(compiled_nev_event_codes, 2)
        if ~isempty(compiled_nev_event_codes{ii,jj})
            if jj == 1
                temp_events(:,jj) = double(compiled_nev_event_codes{ii,jj});
                temp_times(:,jj) = double(compiled_nev_event_times{ii,jj});
            elseif numel(compiled_nev_event_codes{ii,jj}) == size(temp_events, 1)
                temp_events(:,jj) = double(compiled_nev_event_codes{ii,jj});
                temp_times(:,jj) = double(compiled_nev_event_times{ii,jj});
            elseif numel(compiled_nev_event_codes{ii,jj}) < size(temp_events, 1)
                temp_events(:,jj) = [double(compiled_nev_event_codes{ii,jj}); ...
                    nan(size(temp_events, 1) - numel(compiled_nev_event_codes{ii,jj}), 1)];
                temp_times(:,jj) = [double(compiled_nev_event_times{ii,jj}); ...
                    nan(size(temp_times, 1) -  numel(compiled_nev_event_times{ii,jj}), 1)];
            else
                temp_events = [temp_events; nan(numel(compiled_nev_event_codes{ii,jj}) - ...
                    size(temp_events, 1), size(temp_events, 2))];
                temp_events(:,jj) = double(compiled_nev_event_codes{ii,jj});
                temp_times = [temp_times; nan(numel(compiled_nev_event_times{ii,jj}) - ...
                    size(temp_times, 1), size(temp_times, 2))];
                temp_times(:,jj) = double(compiled_nev_event_times{ii,jj});
            end
            nev_valid(ii,jj) = 1;
        else
            % Fake it till you make it
            temp_events(:,jj) = temp_events(:,1);
            temp_times(:,jj) = temp_times(:,1);
            nev_valid(ii,jj) = 0;
        end
    end

    % replace missing event codes with approximate times based on the other
    % instances
    if ~numel(unique(temp_events(1,:))) == 1
        error('task seemed to start before all the instances were up and running. this will take some work to add in as a feature if needed.')
    end
    reasonable_values = [2^1 2^2 2^3 2^4 2^5 2^6 2^7 2^8 2^9 2^10 2^11 2^12 2^13 2^14 2^15 2^16];
    for jj = 1 : size(temp_events, 1)
        if any(isnan(temp_events(jj,:)))
            break
        end
        try
            while numel(unique(temp_events(jj,:)))>1
                a = temp_events(jj,:);
                b = unique(temp_events(jj,:));
                c = cell2mat(arrayfun(@(x)length(find(a == x)), unique(temp_events(jj,:)), 'Uniform', false));
                [~,indbad] = min(c);
                indbad = indbad(1);
                badval = find(temp_events(jj,:) == b(indbad), 1);
                if c(1) == 4 & c(2) == 4
                    val1 = find(temp_events(jj,:) == b(1), 1);
                    val2 = find(temp_events(jj,:) == b(2), 1);
                    if temp_events(jj,val1) == temp_events(jj+1,val2)
                        temp_events(jj+1:end,a==a(val1)) = temp_events(jj:end-1,a==a(val1));
                        temp_events(jj, a==a(val1)) = a(val2);
                        temp_times(jj+1:end,a==a(val1)) = temp_times(jj+1:end,a==a(val1));
                        temp_times(jj, a==a(val1)) = temp_times(jj-1, a==a(val1)) + ...
                            median(temp_times(jj, a==a(val2)) - temp_times(jj-1, a==a(val2)));
                    elseif temp_events(jj,val2) == temp_events(jj+1,val1)
                        temp_events(jj+1:end,a==a(val2)) = temp_events(jj:end-1,a==a(val2));
                        temp_events(jj, a==a(val2)) = a(val1);
                        temp_times(jj+1:end,a==a(val2)) = temp_times(jj+1:end,a==a(val2));
                        temp_times(jj, a==a(val2)) = temp_times(jj-1, a==a(val2)) + ...
                            median(temp_times(jj, a==a(val1)) - temp_times(jj-1, a==a(val1)));
                    elseif temp_events(jj,val1) == temp_events(jj+1,val1)
                        temp_events(jj, a==a(val1)) = a(val2);
                    elseif temp_events(jj,val2) == temp_events(jj+1,val2)
                        temp_events(jj, a==a(val2)) = a(val1);
                    else
                        warning('weird scenario')
                        temp_events(jj,:) = [];
                        temp_times(jj,:) = [];
                    end
                else
                    if ~any(temp_events(jj,badval) == reasonable_values)
                        temp_events(jj,badval) = mode(temp_events(jj,:));
                    elseif temp_events(jj,badval) == temp_events(jj-1,badval)
                        temp_events(jj:end-1,badval) = temp_events(jj+1:end,badval);
                        temp_events(end, badval) = NaN;
                        temp_times(jj:end-1,badval) = temp_times(jj+1:end,badval);
                        temp_times(end, badval) = NaN;
                    elseif ~isempty(find(temp_events(jj+1,:)==temp_events(jj,badval)))
                        temp_events(jj, badval) = mode(temp_events(jj,:));
                    elseif numel(unique(temp_events(jj+1,:))) == 1
                        temp_events(jj, badval) = mode(temp_events(jj,:));
                    else
                        warning('unexpected error')
                        temp_events(jj:end-1,badval) = temp_events(jj+1:end,badval);
                        temp_events(end, badval) = NaN;
                        temp_times(jj:end-1,badval) = temp_times(jj+1:end,badval);
                        temp_times(end, badval) = NaN;
                    end
                end
            end
        end
    end

    good_ind = zeros(size(temp_events), 'logical');
    for jj = events_of_interest
        good_ind(temp_events == jj) = 1;
    end
 
    events_per_instance = sum(good_ind);
    if numel(unique(events_per_instance)) ~= 1
        warning('EVENTS INCONSISTENT ACROSS INSTANCES, ATTEMPTING CROP')
        for jj = 1 : size(temp_events,2)
            if any(isnan(temp_events(:,jj)))
                early_nan(jj) = find(isnan(temp_events(:,jj)), 1);
            else
                early_nan(jj) = NaN;
            end
        end
        earliest_nan = min(early_nan);
        temp_events = temp_events(1:earliest_nan-1,:);
        temp_times = temp_times(1:earliest_nan-1,:);
        good_ind = zeros(size(temp_events), 'logical');
        for jj = events_of_interest
            good_ind(temp_events == jj) = 1;
        end
        events_per_instance = sum(good_ind);
    end

    temp_eoi = reshape(temp_events(good_ind), events_per_instance(1), []);
    temp_toi = reshape(temp_times(good_ind), events_per_instance(1), []);

    clear temp_events temp_times good_ind events_per_instance

    diff_toi = diff(temp_toi, 1);
    mode_toi = mode(diff_toi, 2);
    cumsum_toi = cumsum(mode_toi) + 30001;

    modify_by = diff_toi - repmat(mode_toi, 1, size(diff_toi, 2));

    for jj = 1 : size(compiled_nev_event_codes, 2)
        realigned_indices{ii, jj} = (temp_toi(1,jj)-30000:temp_toi(end,jj)+30000)';
        for kk = size(modify_by, 1) : -1 : 1
            if modify_by(kk,jj) ~= 0
                if modify_by(kk,jj) > 0
                    alter_point = find(realigned_indices{ii,jj} == temp_toi(kk,jj));
                    realigned_indices{ii,jj} = ...
                        [ realigned_indices{ii,jj}(1:alter_point-modify_by(kk,jj)); ...
                        realigned_indices{ii,jj}(alter_point+1:end) ];
                else
                    alter_point = find(realigned_indices{ii,jj} == temp_toi(kk,jj));
                    realigned_indices{ii,jj} = ...
                        [ realigned_indices{ii,jj}(1:alter_point); ...
                        repmat(realigned_indices{ii,jj}(alter_point), -1*modify_by(kk,jj), 1); ...
                         realigned_indices{ii,jj}(alter_point+1:end) ];
                end
            end
        end
    end

    realigned_nev_event_codes{ii} = temp_eoi(:,1);
    realigned_nev_event_times{ii} = [30001; cumsum_toi];

end

if ~isempty(compiled_nev_event_infos)
    realigned_nev_event_infos = compiled_nev_event_infos{1};
else
    realigned_nev_event_infos = [];
end

for ii = 1 : size(compiled_nev_event_codes, 1)
    block_lengths(ii) = numel(realigned_indices{ii,1});
    if ii > 1
        realigned_nev_event_times{ii} = realigned_nev_event_times{ii} + sum(block_lengths(1:ii-1));
        if ~isempty(realigned_nev_event_infos)
            realigned_nev_event_infos = [realigned_nev_event_infos; ...
                compiled_nev_event_infos{ii}];
        end
    end
end

temp_event_times = [];
temp_event_codes = [];
realigned_nev_event_infos = [realigned_nev_event_infos, ...
    zeros(sum(cellfun(@numel, realigned_nev_event_codes)), 1)];
ind_pre = 1;
ind_post = 0;
for ii = 1 : size(realigned_nev_event_times, 2)
    temp_event_times = [temp_event_times; realigned_nev_event_times{ii}];
    temp_event_codes = [temp_event_codes; realigned_nev_event_codes{ii}];
    ind_post = ind_post + numel(realigned_nev_event_codes{ii});
    realigned_nev_event_infos(ind_pre:ind_post, end) = ii;
    ind_pre = ind_post + 1;
end

realigned_nev_event_codes = temp_event_codes;
realigned_nev_event_times = temp_event_times ./ 30000;

if ~isempty(realigned_nev_event_infos)
    if size(realigned_nev_event_infos,1) ~= numel(realigned_nev_event_codes) & ...
            ~iscell(realigned_nev_event_infos)
        warning('INFOS SIZE DOES NOT MATCH NUMBER OF DETECTED TRIALS. CHECK EVENTS OF INTEREST')
        realigned_nev_event_infos = [realigned_nev_event_infos; ...
            zeros(numel(realigned_nev_event_codes) - size(realigned_nev_event_infos,1), ...
            size(realigned_nev_event_infos, 2))];
    end
end

end