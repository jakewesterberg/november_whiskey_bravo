classdef StimulusTemplate < types.core.ImageSeries & types.untyped.GroupClass
% STIMULUSTEMPLATE Each image shown to the animals is warped to account for distance and eye position relative to the monitor. This  extension stores the warped images that were shown to the animal as well as an unwarped version of each image in which a mask has been applied such that only the pixels visible after warping are included


% REQUIRED PROPERTIES
properties
    unwarped; % REQUIRED ((float) ) Original image with mask applied such that only the pixels visible after warping are included
end

methods
    function obj = StimulusTemplate(varargin)
        % STIMULUSTEMPLATE Constructor for StimulusTemplate
        obj = obj@types.core.ImageSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'unwarped',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.unwarped = p.Results.unwarped;
        if strcmp(class(obj), 'types.ndx_aibs_stimulus_template.StimulusTemplate')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.unwarped(obj, val)
        obj.unwarped = obj.validate_unwarped(val);
    end
    %% VALIDATORS
    
    function val = validate_unwarped(obj, val)
        val = types.util.checkDtype('unwarped', 'float', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[Inf,Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.ImageSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if startsWith(class(obj.unwarped), 'types.untyped.')
            refs = obj.unwarped.export(fid, [fullpath '/unwarped'], refs);
        elseif ~isempty(obj.unwarped)
            io.writeDataset(fid, [fullpath '/unwarped'], obj.unwarped, 'forceArray');
        end
    end
end

end