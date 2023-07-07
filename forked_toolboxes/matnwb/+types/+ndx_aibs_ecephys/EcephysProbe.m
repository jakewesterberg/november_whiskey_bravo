classdef EcephysProbe < types.core.Device & types.untyped.GroupClass
% ECEPHYSPROBE A neuropixels probe device


% REQUIRED PROPERTIES
properties
    probe_id; % REQUIRED (int) Unique ID of the neuropixels probe
    sampling_rate; % REQUIRED (float64) The sampling rate for the device
end

methods
    function obj = EcephysProbe(varargin)
        % ECEPHYSPROBE Constructor for EcephysProbe
        obj = obj@types.core.Device(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'probe_id',[]);
        addParameter(p, 'sampling_rate',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.probe_id = p.Results.probe_id;
        obj.sampling_rate = p.Results.sampling_rate;
        if strcmp(class(obj), 'types.ndx_aibs_ecephys.EcephysProbe')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.probe_id(obj, val)
        obj.probe_id = obj.validate_probe_id(val);
    end
    function obj = set.sampling_rate(obj, val)
        obj.sampling_rate = obj.validate_sampling_rate(val);
    end
    %% VALIDATORS
    
    function val = validate_probe_id(obj, val)
        val = types.util.checkDtype('probe_id', 'int', val);
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
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_sampling_rate(obj, val)
        val = types.util.checkDtype('sampling_rate', 'float64', val);
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
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.Device(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/probe_id'], obj.probe_id);
        io.writeAttribute(fid, [fullpath '/sampling_rate'], obj.sampling_rate);
    end
end

end