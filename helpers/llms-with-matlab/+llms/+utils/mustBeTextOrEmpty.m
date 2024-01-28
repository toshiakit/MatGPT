function mustBeTextOrEmpty(value)
% This function is undocumented and will change in a future release

%   Simple function to check if value is empty or text scalar

%   Copyright 2023 The MathWorks, Inc.
    if ~isempty(value)
        mustBeTextScalar(value)
    end
end