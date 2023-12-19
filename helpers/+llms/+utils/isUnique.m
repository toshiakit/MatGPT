function tf = isUnique(values)
% This function is undocumented and will change in a future release

% Simple function to check if value is unique

%   Copyright 2023 The MathWorks, Inc.
    tf = numel(values)==numel(unique(values));
end

