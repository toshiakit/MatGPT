function key = getApiKeyFromNvpOrEnv(nvp)
% This function is undocumented and will change in a future release

%getApiKeyFromNvpOrEnv Retrieves an API key from a Name-Value Pair struct or environment variable.
%
%   This function takes a struct nvp containing name-value pairs and checks
%   if it contains a field called "ApiKey". If the field is not found, 
%   the function attempts to retrieve the API key from an environment
%   variable called "OPENAI_API_KEY". If both methods fail, the function 
%   throws an error.

%   Copyright 2023 The MathWorks, Inc.

    if isfield(nvp, "ApiKey")
        key = nvp.ApiKey;
    else
        if isenv("OPENAI_API_KEY")
            key = getenv("OPENAI_API_KEY");
        else
            error("llms:keyMustBeSpecified", llms.utils.errorMessageCatalog.getMessage("llms:keyMustBeSpecified"));
        end
    end
end