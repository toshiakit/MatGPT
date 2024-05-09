function [emb, response] = extractOpenAIEmbeddings(text, nvp)
% EXTRACTOPENAIEMBEDDINGS  Generate text embeddings using the OpenAI API
%
%   emb = EXTRACTOPENAIEMBEDDINGS(text) generates an embedding of the input
%   TEXT using the OpenAI API.
%
%   emb = EXTRACTOPENAIEMBEDDINGS(text,Name=Value) specifies optional
%   specifies additional options using one or more name-value pairs:
%
%   'ModelName'                 - The ID of the model to use.
%
%   'ApiKey'                    - OpenAI API token. It can also be specified by
%                                setting the environment variable OPENAI_API_KEY
%
%   'TimeOut'                   - Connection Timeout in seconds (default: 10 secs)
%
%   'Dimensions'                - Number of dimensions the resulting output
%                                 embeddings should have.
%
%   [emb, response] = EXTRACTOPENAIEMBEDDINGS(...) also returns the full
%   response from the OpenAI API call.
%
%   Copyright 2023-2024 The MathWorks, Inc.

arguments
    text           (1,:) {mustBeNonzeroLengthText}
    nvp.ModelName  (1,1) {mustBeMember(nvp.ModelName,["text-embedding-ada-002", ...
                        "text-embedding-3-large", "text-embedding-3-small"])} = "text-embedding-ada-002"
    nvp.TimeOut    (1,1) {mustBeReal,mustBePositive} = 10
    nvp.Dimensions (1,1) {mustBeInteger,mustBePositive}
    nvp.ApiKey           {llms.utils.mustBeNonzeroLengthTextScalar}
end

END_POINT = "https://api.openai.com/v1/embeddings";

key = llms.internal.getApiKeyFromNvpOrEnv(nvp);

parameters = struct("input",text,"model",nvp.ModelName);

if isfield(nvp, "Dimensions")
    if nvp.ModelName=="text-embedding-ada-002"
        error("llms:invalidOptionForModel", ...
            llms.utils.errorMessageCatalog.getMessage("llms:invalidOptionForModel", "Dimensions", nvp.ModelName));
    end
    mustBeCorrectDimensions(nvp.Dimensions,nvp.ModelName);
    parameters.dimensions = nvp.Dimensions;
end


response = llms.internal.sendRequest(parameters,key, END_POINT, nvp.TimeOut);

if isfield(response.Body.Data, "data")
    emb = [response.Body.Data.data.embedding];
    emb = emb';
else
    emb = [];
end
end

function mustBeCorrectDimensions(dimensions,modelName)
    model2dim = ....
    dictionary(["text-embedding-3-large", "text-embedding-3-small"], ...
    [3072,1536]);

    if dimensions>model2dim(modelName)
        error("llms:dimensionsMustBeSmallerThan", ...
            llms.utils.errorMessageCatalog.getMessage("llms:dimensionsMustBeSmallerThan", ...
            string(model2dim(modelName))));
    end
end