classdef errorMessageCatalog
%errorMessageCatalog Stores the error messages from this repository

%   Copyright 2023-2024 The MathWorks, Inc.

    properties(Constant)
        %CATALOG dictionary mapping error ids to error msgs
        Catalog = buildErrorMessageCatalog;
    end

    methods(Static)
        function msg = getMessage(messageId, slot)
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
catalog("llms:mustBeAssistantWithIdAndFunction") = "Field 'tool_call' must be a struct with fields 'id' and 'function'.";
catalog("llms:mustBeAssistantWithNameAndArguments") = "Field 'function' must be a struct with fields 'name' and 'arguments'.";
catalog("llms:assistantMustHaveTextNameAndArguments") = "Fields 'name' and 'arguments' must be text with one or more characters.";
catalog("llms:mustBeValidIndex") = "Value is larger than the number of elements in Messages ({1}).";
catalog("llms:stopSequencesMustHaveMax4Elements") = "Number of elements must not be larger than 4.";
catalog("llms:keyMustBeSpecified") = "API key not found as environment variable OPENAI_API_KEY and not specified via ApiKey parameter.";
catalog("llms:mustHaveMessages") = "Value must contain at least one message in Messages.";
catalog("llms:mustSetFunctionsForCall") = "When no functions are defined, ToolChoice must not be specified.";
catalog("llms:mustBeMessagesOrTxt") = "Messages must be text with one or more characters or an openAIMessages objects.";
catalog("llms:invalidOptionAndValueForModel") = "'{1}' with value '{2}' is not supported for ModelName '{3}'";
catalog("llms:invalidOptionForModel") = "{1} is not supported for ModelName '{2}'";
catalog("llms:invalidContentTypeForModel") = "{1} is not supported for ModelName '{2}'";
catalog("llms:functionNotAvailableForModel") = "This function is not supported for ModelName '{1}'";
catalog("llms:promptLimitCharacter") = "Prompt must have a maximum length of {1} characters for ModelName '{2}'";
catalog("llms:pngExpected") = "Argument must be a PNG image.";
catalog("llms:warningJsonInstruction") = "When using JSON mode, you must also prompt the model to produce JSON yourself via a system or user message.";
catalog("llms:apiReturnedError") = "OpenAI API Error: {1}";
catalog("llms:dimensionsMustBeSmallerThan") = "Dimensions must be less than or equal to {1}.";
end