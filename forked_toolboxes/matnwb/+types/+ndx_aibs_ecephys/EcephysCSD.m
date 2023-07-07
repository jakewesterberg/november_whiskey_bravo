classdef EcephysCSD < types.core.NWBDataInterface & types.untyped.GroupClass
% ECEPHYSCSD A group containing current source density (CSD) data and virtual electrode locations


% REQUIRED PROPERTIES
properties
    timeseries; % REQUIRED (TimeSeries) A timeseries containing current source density (CSD) data
    virtual_electrode_x_positions; % REQUIRED ((float32) ) Virtual horizontal positions of electrodes from which CSD was calculated
    virtual_electrode_x_positions_unit; % REQUIRED (char) Unit of measurement for the data
    virtual_electrode_y_positions; % REQUIRED ((float32) ) Virtual vertical positions of electrodes from which CSD was calculated
    virtual_electrode_y_positions_unit; % REQUIRED (char) Unit of measurement for the data
end

methods
    function obj = EcephysCSD(varargin)
        % ECEPHYSCSD Constructor for EcephysCSD
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        [obj.timeseries,ivarargin] = types.util.parseAnon('types.core.TimeSeries', varargin{:});
        varargin(ivarargin) = [];
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'virtual_electrode_x_positions',[]);
        addParameter(p, 'virtual_electrode_x_positions_unit',[]);
        addParameter(p, 'virtual_electrode_y_positions',[]);
        addParameter(p, 'virtual_electrode_y_positions_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.virtual_electrode_x_positions = p.Results.virtual_electrode_x_positions;
        obj.virtual_electrode_x_positions_unit = p.Results.virtual_electrode_x_positions_unit;
        obj.virtual_electrode_y_positions = p.Results.virtual_electrode_y_positions;
        obj.virtual_electrode_y_positions_unit = p.Results.virtual_electrode_y_positions_unit;
        if strcmp(class(obj), 'types.ndx_aibs_ecephys.EcephysCSD')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.timeseries(obj, val)
        obj.timeseries = obj.validate_timeseries(val);
    end
    function obj = set.virtual_electrode_x_positions(obj, val)
        obj.virtual_electrode_x_positions = obj.validate_virtual_electrode_x_positions(val);
    end
    function obj = set.virtual_electrode_x_positions_unit(obj, val)
        obj.virtual_electrode_x_positions_unit = obj.validate_virtual_electrode_x_positions_unit(val);
    end
    function obj = set.virtual_electrode_y_positions(obj, val)
        obj.virtual_electrode_y_positions = obj.validate_virtual_electrode_y_positions(val);
    end
    function obj = set.virtual_electrode_y_positions_unit(obj, val)
        obj.virtual_electrode_y_positions_unit = obj.validate_virtual_electrode_y_positions_unit(val);
    end
    %% VALIDATORS
    
    function val = validate_timeseries(obj, val)
        val = types.util.checkDtype('timeseries', 'types.core.TimeSeries', val);
    end
    function val = validate_virtual_electrode_x_positions(obj, val)
        val = types.util.checkDtype('virtual_electrode_x_positions', 'float32', val);
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
    function val = validate_virtual_electrode_x_positions_unit(obj, val)
        val = types.util.checkDtype('virtual_electrode_x_positions_unit', 'char', val);
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
    function val = validate_virtual_electrode_y_positions(obj, val)
        val = types.util.checkDtype('virtual_electrode_y_positions', 'float32', val);
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
    function val = validate_virtual_electrode_y_positions_unit(obj, val)
        val = types.util.checkDtype('virtual_electrode_y_positions_unit', 'char', val);
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
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.timeseries.export(fid, [fullpath '/'], refs);
        if startsWith(class(obj.virtual_electrode_x_positions), 'types.untyped.')
            refs = obj.virtual_electrode_x_positions.export(fid, [fullpath '/virtual_electrode_x_positions'], refs);
        elseif ~isempty(obj.virtual_electrode_x_positions)
            io.writeDataset(fid, [fullpath '/virtual_electrode_x_positions'], obj.virtual_electrode_x_positions, 'forceArray');
        end
        if ~isempty(obj.virtual_electrode_x_positions)
            io.writeAttribute(fid, [fullpath '/virtual_electrode_x_positions/unit'], obj.virtual_electrode_x_positions_unit);
        end
        if startsWith(class(obj.virtual_electrode_y_positions), 'types.untyped.')
            refs = obj.virtual_electrode_y_positions.export(fid, [fullpath '/virtual_electrode_y_positions'], refs);
        elseif ~isempty(obj.virtual_electrode_y_positions)
            io.writeDataset(fid, [fullpath '/virtual_electrode_y_positions'], obj.virtual_electrode_y_positions, 'forceArray');
        end
        if ~isempty(obj.virtual_electrode_y_positions)
            io.writeAttribute(fid, [fullpath '/virtual_electrode_y_positions/unit'], obj.virtual_electrode_y_positions_unit);
        end
    end
end

end