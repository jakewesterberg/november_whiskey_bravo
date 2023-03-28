function [realigned_nev_event_codes, realigned_nev_event_times, realigned_indices, block_lengths] = ...
    align_nev_event_data(compiled_nev_event_codes, compiled_nev_event_times, events_of_interest)

if nargin < 3
    events_of_interest = [1, 2];
end

realigned_indices = {};

for ii = 1 : size(compiled_nev_event_codes, 1)

    temp_events = [];
    temp_times = [];
    for jj = 1 : size(compiled_nev_event_codes, 2)
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
                nan(size(temp_times, 1) - numel(compiled_nev_event_times{ii,jj}), 1)];
        else
            temp_events = [temp_events; nan(numel(compiled_nev_event_codes{ii,jj}) - ...
                size(temp_events, 1), size(temp_events, 2))];
            temp_events(:,jj) = double(compiled_nev_event_codes{ii,jj});
            temp_times = [temp_times; nan(numel(compiled_nev_event_times{ii,jj}) - ...
                size(temp_times, 1), size(temp_times, 2))];
            temp_times(:,jj) = double(compiled_nev_event_times{ii,jj});
        end
    end

    good_ind = zeros(size(temp_events), 'logical');
    for jj = events_of_interest
        good_ind(temp_events == jj) = 1;
    end

    events_per_instance = sum(good_ind);
    if numel(unique(events_per_instance)) ~= 1
        error('EVENTS INCONSISTENT ACROSS INSTANCES')
    end

    temp_eoi = reshape(temp_events(good_ind), events_per_instance(1), []);
    temp_toi = reshape(temp_times(good_ind), events_per_instance(1), []);

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

for ii = 1 : size(compiled_nev_event_codes, 1)
    block_lengths(ii) = numel(realigned_indices{ii,1});
    if ii > 1
        realigned_nev_event_times{ii} = realigned_nev_event_times{ii} + sum(block_lengths(1:ii-1));
    end
end

temp_event_times = [];
temp_event_codes = [];
for ii = 1:  size(realigned_nev_event_times, 2)
    temp_event_times = [temp_event_times; realigned_nev_event_times{ii}];
    temp_event_codes = [temp_event_codes; realigned_nev_event_codes{ii}];
end

realigned_nev_event_codes = temp_event_codes;
realigned_nev_event_times = temp_event_times;

end