classdef RGBImage < types.core.Image & types.untyped.DatasetClass
% RGBIMAGE A color image.



methods
    function obj = RGBImage(varargin)
        % RGBIMAGE Constructor for RGBImage
        obj = obj@types.core.Image(varargin{:});
        if strcmp(class(obj), 'types.core.RGBImage')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.Image(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end