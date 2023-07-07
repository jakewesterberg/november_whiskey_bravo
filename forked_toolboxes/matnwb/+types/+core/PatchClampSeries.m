classdef PatchClampSeries < types.core.TimeSeries & types.untyped.GroupClass
% PATCHCLAMPSERIES An abstract base class for patch-clamp data - stimulus or response, current or voltage.


% REQUIRED PROPERTIES
properties
    electrode; % REQUIRED (IntracellularElectrode) 
    stimulus_description; % REQUIRED (char) Protocol/stimulus name for this patch-clamp dataset.
end
% OPTIONAL PROPERTIES
properties
    gain; % OPTIONAL ((float32) ) Gain of the recording, in units Volt/Amp (v-clamp) or Volt/Volt (c-clamp).
    sweep_number; % OPTIONAL (uint32) Sweep number, allows to group different PatchClampSeries together.
end

methods
    function obj = PatchClampSeries(varargin)
        % PATCHCLAMPSERIES Constructor for PatchClampSeries
        varargin = [{'data_conversion' types.util.correctType(1, 'float32') 'data_resolution' types.util.correctType(-1, 'float32')} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'electrode',[]);
        addParameter(p, 'stimulus_description',[]);
        addParameter(p, 'gain',[]);
        addParameter(p, 'sweep_number',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.electrode = p.Results.electrode;
        obj.stimulus_description = p.Results.stimulus_description;
        obj.gain = p.Results.gain;
        obj.sweep_number = p.Results.sweep_number;
        if strcmp(class(obj), 'types.core.PatchClampSeries')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.electrode(obj, val)
        obj.electrode = obj.validate_electrode(val);
    end
    function obj = set.gain(obj, val)
        obj.gain = obj.validate_gain(val);
    end
    function obj = set.stimulus_description(obj, val)
        obj.stimulus_description = obj.validate_stimulus_description(val);
    end
    function obj = set.sweep_number(obj, val)
        obj.sweep_number = obj.validate_sweep_number(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
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
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_data_continuity(obj, val)
        val = types.util.checkDtype('data_continuity', 'char', val);
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
    function val = validate_data_conversion(obj, val)
        val = types.util.checkDtype('data_conversion', 'float32', val);
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
    function val = validate_data_resolution(obj, val)
        val = types.util.checkDtype('data_resolution', 'float32', val);
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
    function val = validate_data_unit(obj, val)
        val = types.util.checkDtype('data_unit', 'char', val);
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
    function val = validate_electrode(obj, val)
        val = types.util.checkDtype('electrode', 'types.core.IntracellularElectrode', val);
    end
    function val = validate_gain(obj, val)
        val = types.util.checkDtype('gain', 'float32', val);
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
    function val = validate_stimulus_description(obj, val)
        val = types.util.checkDtype('stimulus_description', 'char', val);
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
    function val = validate_sweep_number(obj, val)
        val = types.util.checkDtype('sweep_number', 'uint32', val);
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
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.electrode.export(fid, [fullpath '/electrode'], refs);
        if ~isempty(obj.gain)
            if startsWith(class(obj.gain), 'types.untyped.')
                refs = obj.gain.export(fid, [fullpath '/gain'], refs);
            elseif ~isempty(obj.gain)
                io.writeDataset(fid, [fullpath '/gain'], obj.gain);
            end
        end
        io.writeAttribute(fid, [fullpath '/stimulus_description'], obj.stimulus_description);
        if ~isempty(obj.sweep_number)
            io.writeAttribute(fid, [fullpath '/sweep_number'], obj.sweep_number);
        end
    end
end

end