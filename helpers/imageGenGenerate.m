function [image,message,response] = imageGenGenerate(chat,messages)
% IMAGEGENGENERATE generates image using chat api with function calling

    % generate a response to the prompt for image generation
    [txt,message,response] = generate(chat,messages);
    % if tool_call is returned
    if isfield(message,"tool_calls")
        toolCalls = message.tool_calls;
        fcn = toolCalls.function.name;
        % make sure it calls for 'generateImage'
        if strcmp(fcn,"generateImage")
            args = jsondecode(toolCalls.function.arguments);
            prompt = string(args.prompt);
            % execute 'generateImage' using the provided prompt
            [image,revisedPrompt,response] = generateImage(prompt);
            message = struct("role","assistant","content", string(revisedPrompt));
        end
    else
        image = txt;
    end
end

% helper function 'generateImage' to call DALL-E 3
function [image, revisedPrompt ,response] = generateImage(prompt)
    mdl = openAIImages(ModelName="dall-e-3");
    [images, response] = generate(mdl,string(prompt));
    image = images{1};
    revisedPrompt = response.Body.Data.data.revised_prompt;
end