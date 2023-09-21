function signal = remove_polynomial_fit(signal, gap_starts, blank_length, margin, polynomial_order)
    % polyfit sections to matrix
    starts = gap_starts(1:end-1) + blank_length - margin;
    ends = gap_starts(2:end) + margin;
    len = round(mean(ends-starts));
    pol_sections = zeros(size(gap_starts,1)-1,len);

    for start_idx = 1:length(starts)
        pol_sections(start_idx,:) = signal(starts(start_idx):starts(start_idx)+len-1);
    end

    poly_fit_size = size(pol_sections);
    x0 = linspace(0,100,poly_fit_size(2))';
    
    V = bsxfun(@power,x0,0:polynomial_order);
    M = V*pinv(V);
    
    polyCube = M*reshape(permute(pol_sections,[2 1]),poly_fit_size(2),[]);
    polyCube = reshape(polyCube,[poly_fit_size(2) poly_fit_size(1)]);
    polyCube = permute(polyCube,[2 1]);

    yhat_total = zeros(size(signal));
    
    for start_idx = 1:length(starts)
        yhat_total(starts(start_idx):starts(start_idx)+len-1) = polyCube(start_idx,:);
    end

    signal = signal - yhat_total;

