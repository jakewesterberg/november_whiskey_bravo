function signal = art_removal_MUA(art_params, signal, gap_starts)

    % remove polynomial fit
    signal = remove_polynomial_fit(signal, gap_starts, art_params.blank_length, art_params.margin, art_params.polynomial_order);

    % remove gaps + interpolate
    signal = remove_interp_gaps(signal', gap_starts, art_params.blank_length);
    
    % make sure there are no NaNs
    idx = isnan(signal);
    signal(idx) = 0;
end