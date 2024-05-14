classdef(Sealed) openAIChat
%openAIChat Chat completion API from OpenAI.
%
%   CHAT = openAIChat(systemPrompt) creates an openAIChat object with the
%   specified system prompt.
%
%   CHAT = openAIChat(systemPrompt,ApiKey=key) uses the specified API key
%
%   CHAT = openAIChat(systemPrompt,Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%   Tools                   - Array of openAIFunction objects representing
%                             custom functions to be used during chat completions.
%
%   ModelName               - Name of the model to use for chat completions.
%                             The default value is "gpt-3.5-turbo".
%
%   Temperature             - Temperature value for controlling the randomness
%                             of the output. Default value is 1.
%
%   TopProbabilityMass      - Top probability mass value for controlling the
%                             diversity of the output. Default value is 1.
%
%   StopSequences           - Vector of strings that when encountered, will
%                             stop the generation of tokens. Default
%                             value is empty.
%
%   PresencePenalty         - Penalty value for using a token in the response
%                             that has already been used. Default value is 0.
%
%   FrequencyPenalty        - Penalty value for using a token that is frequent
%                             in the training data. Default value is 0.
%
%   StreamFun               - Function to callback when streaming the
%                             result
%
%   ResponseFormat          - The format of response the model returns.
%                             "text" (default) | "json"
%
%   openAIChat Functions:
%       openAIChat           - Chat completion API from OpenAI.
%       generate             - Generate a response using the openAIChat instance.
%
%   openAIChat Properties:
%       ModelName            - Model name.
%
%       Temperature          - Temperature of generation.
%
%       TopProbabilityMass   - Top probability mass to consider for generation.
%
%       StopSequences        - Sequences to stop the generation of tokens.
%
%       PresencePenalty      - Penalty for using a token in the
%                              response that has already been used.
%
%       FrequencyPenalty     - Penalty for using a token that is
%                              frequent in the training data.
%
%       SystemPrompt         - System prompt.
%
%       FunctionNames        - Names of the functions that the model can
%                              request calls.
%
%       ResponseFormat       - Specifies the response format, text or json
%
%       TimeOut              - Connection Timeout in seconds (default: 10 secs)
%

% Copyright 2023-2024 The MathWorks, Inc.

    properties        
        %TEMPERATURE   Temperature of generation.
        Temperature

        %TOPPROBABILITYMASS   Top probability mass to consider for generation.
        TopProbabilityMass

        %STOPSEQUENCES   Sequences to stop the generation of tokens.
        StopSequences

        %PRESENCEPENALTY   Penalty for using a token in the response that has already been used.
        PresencePenalty

        %FREQUENCYPENALTY   Penalty for using a token that is frequent in the training data.
        FrequencyPenalty
    end

    properties(SetAccess=private) 
        %TIMEOUT    Connection timeout in seconds (default 10 secs)
        TimeOut

        %FUNCTIONNAMES   Names of the functions that the model can request calls
        FunctionNames

        %MODELNAME   Model name.
        ModelName

        %SYSTEMPROMPT   System prompt.
        SystemPrompt = []

        %RESPONSEFORMAT     Response format, "text" or "json"       
        ResponseFormat 
    end

    properties(Access=private)
        Tools
        FunctionsStruct
        ApiKey
        StreamFun
    end

    methods
        function this = openAIChat(systemPrompt, nvp)           
            arguments
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Tools                    (1,:) {mustBeA(nvp.Tools, "openAIFunction")} = openAIFunction.empty
                nvp.ModelName                (1,1) {mustBeMember(nvp.ModelName,["gpt-4o", ...
                                                        "gpt-4o-2024-05-13","gpt-4-turbo", ...
                                                        "gpt-4-turbo-2024-04-09","gpt-4","gpt-4-0613", ...
                                                        "gpt-3.5-turbo","gpt-3.5-turbo-0125", ...
                                                        "gpt-3.5-turbo-1106"])} = "gpt-3.5-turbo"
                nvp.Temperature                    {mustBeValidTemperature} = 1
                nvp.TopProbabilityMass             {mustBeValidTopP} = 1
                nvp.StopSequences                  {mustBeValidStop} = {}
                nvp.ResponseFormat           (1,1) string {mustBeMember(nvp.ResponseFormat,["text","json"])} = "text"
                nvp.ApiKey                         {mustBeNonzeroLengthTextScalar} 
                nvp.PresencePenalty                {mustBeValidPenalty} = 0
                nvp.FrequencyPenalty               {mustBeValidPenalty} = 0
                nvp.TimeOut                  (1,1) {mustBeReal,mustBePositive} = 10
                nvp.StreamFun                (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
            end

            if isfield(nvp,"StreamFun")
                this.StreamFun = nvp.StreamFun;
            else
                this.StreamFun = [];
            end

            if isempty(nvp.Tools)
                this.Tools = [];
                this.FunctionsStruct = [];
                this.FunctionNames = [];
            else
                this.Tools = nvp.Tools;
                [this.FunctionsStruct, this.FunctionNames] = functionAsStruct(nvp.Tools);
            end
            
            if ~isempty(systemPrompt)
                systemPrompt = string(systemPrompt);
                if ~(strlength(systemPrompt)==0)
                   this.SystemPrompt = {struct("role", "system", "content", systemPrompt)};
                end
            end

            this.ModelName = nvp.ModelName;
            this.Temperature = nvp.Temperature;
            this.TopProbabilityMass = nvp.TopProbabilityMass;
            this.StopSequences = nvp.StopSequences;

            % ResponseFormat is only supported in the latest models only
            if (nvp.ResponseFormat == "json")
                if ismember(this.ModelName,["gpt-4","gpt-4-0613"])
                    error("llms:invalidOptionAndValueForModel", ...
                        llms.utils.errorMessageCatalog.getMessage("llms:invalidOptionAndValueForModel", "ResponseFormat", "json", this.ModelName));
                else
                    warning("llms:warningJsonInstruction", ...
                        llms.utils.errorMessageCatalog.getMessage("llms:warningJsonInstruction"))
                end

            end

            this.PresencePenalty = nvp.PresencePenalty;
            this.FrequencyPenalty = nvp.FrequencyPenalty;
            this.ApiKey = llms.internal.getApiKeyFromNvpOrEnv(nvp);
            this.TimeOut = nvp.TimeOut;
        end

        function [text, message, response] = generate(this, messages, nvp)
            %generate   Generate a response using the openAIChat instance.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(CHAT, MESSAGES) generates a response
            %   with the specified MESSAGES.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(__, Name=Value) specifies additional options
            %   using one or more name-value arguments:
            %
            %       NumCompletions   - Number of completions to generate.
            %                          Default value is 1.
            %
            %       MaxNumTokens     - Maximum number of tokens in the generated response.
            %                          Default value is inf.
            %
            %       ToolChoice       - Function to execute. 'none', 'auto', 
            %                          or specify the function to call.
            %
            %       Seed             - An integer value to use to obtain
            %                          reproducible responses
            %                           
            % Currently, GPT-4 Turbo with vision does not support the message.name 
            % parameter, functions/tools, response_format parameter, and stop
            % sequences. It also has a low MaxNumTokens default, which can be overridden.

            arguments
                this                    (1,1) openAIChat
                messages                (1,1) {mustBeValidMsgs}
                nvp.NumCompletions      (1,1) {mustBePositive, mustBeInteger} = 1
                nvp.MaxNumTokens        (1,1) {mustBePositive} = inf
                nvp.ToolChoice          {mustBeValidFunctionCall(this, nvp.ToolChoice)} = []
                nvp.Seed                {mustBeIntegerOrEmpty(nvp.Seed)} = []
            end

            toolChoice = convertToolChoice(this, nvp.ToolChoice);

            if isstring(messages) && isscalar(messages)
                messagesStruct = {struct("role", "user", "content", messages)};               
            else
                messagesStruct = messages.Messages;
            end

            if iscell(messagesStruct{end}.content) && any(cellfun(@(x) isfield(x,"image_url"), messagesStruct{end}.content))
                if ~ismember(this.ModelName,["gpt-4-turbo","gpt-4-turbo-2024-04-09","gpt-4o","gpt-4o-2024-05-13"]) 
                 error("llms:invalidContentTypeForModel", ...
                       llms.utils.errorMessageCatalog.getMessage("llms:invalidContentTypeForModel", "Image content", this.ModelName));
                end
            end

            if ~isempty(this.SystemPrompt)
                messagesStruct = horzcat(this.SystemPrompt, messagesStruct);
            end
            
            [text, message, response] = llms.internal.callOpenAIChatAPI(messagesStruct, this.FunctionsStruct,...
                ModelName=this.ModelName, ToolChoice=toolChoice, Temperature=this.Temperature, ...
                TopProbabilityMass=this.TopProbabilityMass, NumCompletions=nvp.NumCompletions,...
                StopSequences=this.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                PresencePenalty=this.PresencePenalty, FrequencyPenalty=this.FrequencyPenalty, ...
                ResponseFormat=this.ResponseFormat,Seed=nvp.Seed, ...
                ApiKey=this.ApiKey,TimeOut=this.TimeOut, StreamFun=this.StreamFun);

            if isfield(response.Body.Data,"error")
                err = response.Body.Data.error.message;
                text = llms.utils.errorMessageCatalog.getMessage("llms:apiReturnedError",err);
                message = struct("role","assistant","content",text);
            end

        end

        function this = set.Temperature(this, temperature)
            arguments
                this openAIChat
                temperature 
            end
            mustBeValidTemperature(temperature);
            
            this.Temperature = temperature;
        end

        function this = set.TopProbabilityMass(this,topP)
            arguments
                this openAIChat
                topP
            end
            mustBeValidTopP(topP);
            this.TopProbabilityMass = topP;
        end

        function this = set.StopSequences(this,stop)
            arguments
                this openAIChat
                stop 
            end
            mustBeValidStop(stop);
            this.StopSequences = stop;
        end

        function this = set.PresencePenalty(this,penalty)
            arguments
                this openAIChat
                penalty 
            end
            mustBeValidPenalty(penalty)
            this.PresencePenalty = penalty;
        end

        function this = set.FrequencyPenalty(this,penalty)
            arguments
                this openAIChat
                penalty
            end
            mustBeValidPenalty(penalty)
            this.FrequencyPenalty = penalty;
        end
    end

    methods(Hidden)
        function mustBeValidFunctionCall(this, functionCall)
            if ~isempty(functionCall)
                mustBeTextScalar(functionCall);
                if isempty(this.FunctionNames)
                    error("llms:mustSetFunctionsForCall", llms.utils.errorMessageCatalog.getMessage("llms:mustSetFunctionsForCall"));
                end
                mustBeMember(functionCall, ["none","auto", this.FunctionNames]);
            end
        end

        function toolChoice = convertToolChoice(this, toolChoice)
            % if toolChoice is empty
            if isempty(toolChoice)
                % if Tools is not empty, the default is 'auto'.
                if ~isempty(this.Tools) 
                    toolChoice = "auto";
                end
            elseif ~ismember(toolChoice,["auto","none"])
                % if toolChoice is not empty, then it must be "auto", "none" or in the format
                % {"type": "function", "function": {"name": "my_function"}}
                toolChoice = struct("type","function","function",struct("name",toolChoice));
            end

        end
    end
end

function mustBeNonzeroLengthTextScalar(content)
mustBeNonzeroLengthText(content)
mustBeTextScalar(content)
end

function [functionsStruct, functionNames] = functionAsStruct(functions)
numFunctions = numel(functions);
functionsStruct = cell(1, numFunctions);
functionNames = strings(1, numFunctions);

for i = 1:numFunctions
    functionsStruct{i} = struct('type','function', ...
        'function',encodeStruct(functions(i))) ;
    functionNames(i) = functions(i).FunctionName;
end
end

function mustBeValidMsgs(value)
if isa(value, "openAIMessages")
    if numel(value.Messages) == 0 
        error("llms:mustHaveMessages", llms.utils.errorMessageCatalog.getMessage("llms:mustHaveMessages"));
    end
else
    try 
        llms.utils.mustBeNonzeroLengthTextScalar(value);
    catch ME
        error("llms:mustBeMessagesOrTxt", llms.utils.errorMessageCatalog.getMessage("llms:mustBeMessagesOrTxt"));
    end
end
end

function mustBeValidPenalty(value)
validateattributes(value, {'numeric'}, {'real', 'scalar', 'nonsparse', '<=', 2, '>=', -2})
end

function mustBeValidTopP(value)
validateattributes(value, {'numeric'}, {'real', 'scalar', 'nonnegative', 'nonsparse', '<=', 1})
end

function mustBeValidTemperature(value)
validateattributes(value, {'numeric'}, {'real', 'scalar', 'nonnegative', 'nonsparse', '<=', 2})
end

function mustBeValidStop(value)
if ~isempty(value)
    mustBeVector(value);
    mustBeNonzeroLengthText(value);
    % This restriction is set by the OpenAI API
    if numel(value)>4
        error("llms:stopSequencesMustHaveMax4Elements", llms.utils.errorMessageCatalog.getMessage("llms:stopSequencesMustHaveMax4Elements"));
    end
end
end

function mustBeIntegerOrEmpty(value)
    if ~isempty(value)
        mustBeInteger(value)
    end
end