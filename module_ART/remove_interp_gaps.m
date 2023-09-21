function signal = remove_interp_gaps(signal, gap_starts, blank_length)%, Bhighpass, Ahighpass)
    % blanking idxs
    gap_idxs = bsxfun(@plus, gap_starts, 0:(blank_length-1));
    gap_idxs = reshape(gap_idxs,1,[]);

    % interpolate
    xx = 1:size(signal,1);
    x = xx;
    x(gap_idxs) = [];
    signal(gap_idxs,:) = [];
    signal = interp1(x,signal,xx,'linear')';
end
