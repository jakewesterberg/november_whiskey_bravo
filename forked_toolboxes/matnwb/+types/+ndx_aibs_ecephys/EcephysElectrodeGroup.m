classdef EcephysElectrodeGroup < types.core.ElectrodeGroup & types.untyped.GroupClass
% ECEPHYSELECTRODEGROUP A group consisting of the channels on a single neuropixels probe


% REQUIRED PROPERTIES
properties
    has_lfp_data; % REQUIRED (logical) Indicates availability of LFP data
    lfp_sampling_rate; % REQUIRED (float64) The sampling rate at which data were acquired on this electrode group's channels
    probe_id; % REQUIRED (int) Unique ID of the neuropixels probe
end

methods
    function obj = EcephysElectrodeGroup(varargin)
        % ECEPHYSELECTRODEGROUP Constructor for EcephysElectrodeGroup
        obj = obj@types.core.ElectrodeGroup(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'has_lfp_data',[]);
        addParameter(p, 'lfp_sampling_rate',[]);
        addParameter(p, 'probe_id',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.has_lfp_data = p.Results.has_lfp_data;
        obj.lfp_sampling_rate = p.Results.lfp_sampling_rate;
        obj.probe_id = p.Results.probe_id;
        if strcmp(class(obj), 'types.ndx_aibs_ecephys.EcephysElectrodeGroup')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.has_lfp_data(obj, val)
        obj.has_lfp_data = obj.validate_has_lfp_data(val);
    end
    function obj = set.lfp_sampling_rate(obj, val)
        obj.lfp_sampling_rate = obj.validate_lfp_sampling_rate(val);
    end
    function obj = set.probe_id(obj, val)
        obj.probe_id = obj.validate_probe_id(val);
    end
    %% VALIDATORS
    
    function val = validate_has_lfp_data(obj, val)
        val = types.util.checkDtype('has_lfp_data', 'logical', val);
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
    function val = validate_lfp_sampling_rate(obj, val)
        val = types.util.checkDtype('lfp_sampling_rate', 'float64', val);
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
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.ElectrodeGroup(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/has_lfp_data'], obj.has_lfp_data);
        io.writeAttribute(fid, [fullpath '/lfp_sampling_rate'], obj.lfp_sampling_rate);
        io.writeAttribute(fid, [fullpath '/probe_id'], obj.probe_id);
    end
end

end