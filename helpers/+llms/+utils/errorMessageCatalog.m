classdef errorMessageCatalog
% This class is undocumented and will change in a future release

%errorMessageCatalog Stores the error messages from this repository

%   Copyright 2023 The MathWorks, Inc.
    properties(Constant)
        %CATALOG dictionary mapping error ids to error msgs
        Catalog = buildErrorMessageCatalog;
    end

    methods(Static)
        function msg = getMessage(messageId, slot)
            % This function is undocumented and will change in a future release

            %getMessage returns error message given a messageID and a SLOT.
            %   The value in SLOT should be ordered, where the n-th element
            %   will replace the value "{n}".

            arguments
                messageId {mustBeNonzeroLengthText}
            end
            arguments(Repeating)
                slot {mustBeNonzeroLengthText}
            end

            msg = llms.utils.errorMessageCatalog.Catalog(messageId);
            if ~isempty(slot)
                for i=1:numel(slot)
                    msg = replace(msg,"{"+i+"}", slot{i});
                end
            end
        end
    end
end

function catalog = buildErrorMessageCatalog
catalog = dictionary("string", "string");
catalog("llms:mustBeUnique") = "Values must be unique.";
catalog("llms:mustBeVarName") = "Parameter name must begin with a letter and contain not more than 'namelengthmax' characters.";
catalog("llms:parameterMustBeUnique") = "A parameter name equivalent to '{1}' already exists in Parameters. Redefining a parameter is not allowed.";
catalog("llms:mustBeAssistantCall") = "Input struct must contain field 'role' with value 'assistant', and field 'content'.";
catalog("llms:mustBeAssistantWithContent") = "Input struct must contain field 'content' containing text with one or more characters.";
catalog("llms:mustBeAssistantWithNameAndArguments") = "Field 'function_call' must be a struct with fields 'name' and 'arguments'.";
catalog("llms:assistantMustHaveTextNameAndArguments") = "Fields 'name' and 'arguments' must be text with one or more characters.";
catalog("llms:mustBeValidIndex") = "Value is larger than the number of elements in Messages ({1}).";
catalog("llms:stopSequencesMustHaveMax4Elements") = "Number of elements must not be larger than 4.";
catalog("llms:keyMustBeSpecified") = "API key not found as environment variable OPENAI_API_KEY and not specified via ApiKey parameter.";
catalog("llms:mustHaveMessages") = "Value must contain at least one message in Messages.";
catalog("llms:mustSetFunctionsForCall") = "When no functions are defined, FunctionCall must not be specified.";
catalog("llms:mustBeMessagesOrTxt") = "Messages must be text with one or more characters or an openAIMessages objects.";
end

