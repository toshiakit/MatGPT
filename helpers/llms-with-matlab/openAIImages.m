classdef openAIImages
%openAIImages Connect to Images API from OpenAI.
%
%   MDL = openAIImages creates an openAIImages object with dall-e-2
%
%   MDL = openAIImages(ModelName) uses the specified model
%
%       ModelName            - Name of the model to use for image generation.
%                             "dall-e-2" (default) or "dall-e-3".
%
%   MDL = openAIImages(ModelName, ApiKey=key) uses the specified API key
%
%   MDL = openAIImages(__, Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%       TimeOut              - Connection Timeout in seconds (default: 10 secs)
%
%   openAIImages Functions:
%       openAIImages    - Text to Images API from OpenAI.
%       generate             - Generate images using the openAIImages instance.
%       edit                 - Edit image from a given image and prompt.
%       createVariation      - Generate variations for a given image.
%
%   openAIImages Properties:
%       ModelName            - Name of the model to use for image generation.
%                             "dall-e-2" (default) or "dall-e-3"
%
%       TimeOut              - Connection Timeout in seconds (default: 10 secs)
%

% Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)  
        %ModelName   Model name.
        ModelName

        %TimeOut    Connection timeout in seconds (default 10 secs)
        TimeOut
    end

    properties (Access=private)
        ApiKey
    end

    methods
        function this = openAIImages(nvp)
            arguments
                nvp.ModelName   (1,1) {mustBeMember(nvp.ModelName,["dall-e-2", "dall-e-3"])} = "dall-e-2"
                nvp.ApiKey            {mustBeNonzeroLengthTextScalar} 
                nvp.TimeOut     (1,1) {mustBeReal,mustBePositive} = 10
            end

            this.ModelName = nvp.ModelName;
            this.ApiKey = llms.internal.getApiKeyFromNvpOrEnv(nvp);
            this.TimeOut = nvp.TimeOut;
        end

        function [images, response] = generate(this,prompt,nvp)
            %generate Generate images using the openAIImages instance
            % 
            %   [IMAGES, RESPONSE] = generate(MDL, PROMPT) generates images
            %   with the specified prompt.  The PROMPT should be a text description
            %   of the desired image(s). 
            %
            %   [IMAGES, RESPONSE] = generate(__, Name=Value) specifies
            %   additional options.
            %       
            %       NumImages        - Number of images to generate. 
            %                          Default value is 1. 
            %                          For "dall-e-3" only 1 output is supported. 
            %
            %       Size             - Size of the generated images. 
            %                          Defaults to 1024x1024
            %                          "dall-e-2" supports 256x256, 
            %                          512x512, or 1024x1024.
            %                          "dall-e-3" supports 1024x1024, 
            %                          1792x1024, or 1024x1792
            %
            %       Quality          - Quality of the images to generate. 
            %                          "standard" (default) or "hd". 
            %                          Only "dall-e-3" supports this parameter.
            %
            %       Style            - The style of the generated images. 
            %                          "vivid" (default) or "natural". 
            %                          Only "dall-e-3" supports this parameter.

            arguments
                this                    (1,1)  openAIImages
                prompt                        {mustBeTextScalar}
                nvp.NumImages           (1,1) {mustBePositive, mustBeInteger,...
                                                mustBeLessThanOrEqual(nvp.NumImages,10)} = 1
                nvp.Size                (1,1) string {mustBeMember(nvp.Size, ["256x256", "512x512", ...
                                                                "1024x1024", "1792x1024", ...
                                                                "1024x1792"])} = "1024x1024"
                nvp.Quality             (1,1) string {mustBeMember(nvp.Quality,["standard", "hd"])} 
                nvp.Style               (1,1) string {mustBeMember(nvp.Style,["vivid", "natural"])} 
            end

            endpoint = "https://api.openai.com/v1/images/generations";

            validatePromptSize(this.ModelName, prompt)
            validateSizeNVP(this.ModelName, nvp.Size)

             params = struct("prompt",prompt,...
                "model",this.ModelName,...
                "n",nvp.NumImages,...
                "size",nvp.Size);

            if this.ModelName=="dall-e-2"
                % dall-e-3 only params
                if isfield(nvp, "Quality") 
                    error("llms:invalidOptionForModel", ...
                        llms.utils.errorMessageCatalog.getMessage("llms:invalidOptionForModel", ...
                        "Quality", this.ModelName));
                end
                if isfield(nvp, "Style") 
                    error("llms:invalidOptionForModel", ...
                        llms.utils.errorMessageCatalog.getMessage("llms:invalidOptionForModel", ...
                        "Style", this.ModelName));
                end
            else
                % dall-e-3 only supports NumImages==1
                if nvp.NumImages>1
                    error("llms:invalidOptionAndValueForModel", ...
                        llms.utils.errorMessageCatalog.getMessage("llms:invalidOptionAndValueForModel", ...
                        "NumImages", string(nvp.NumImages), this.ModelName));
                end

                if isfield(nvp, "Quality")
                    params.quality = nvp.Quality;
                end
                if isfield(nvp, "Style")
                    params.style = nvp.Style;
                end
            end

            % Send the HTTP Request
            response = sendRequest(this, endpoint, params);

            % Output the images
            images = extractImages(response);
        end

        function [images, response] = edit(this,imagePath,prompt,nvp)
            %edit Generate an edited or extended image from a given image and prompt
            % 
            %   [IMAGES, RESPONSE] = edit(MDL, IMAGEPATH, PROMPT) 
            %   generates new images from an original image and prompt
            %
            %       imagePath        - The path to the source image file. 
            %                          Must be a valid PNG file, less than 4MB, 
            %                          and square. If mask is not provided, 
            %                          image must have transparency, which 
            %                          will be used as the mask.
            %
            %       prompt           - A text description of the desired image(s). 
            %                          The maximum length: 1000 characters
            %
            %   [IMAGES, RESPONSE] = edit(__, Name=Value) specifies
            %   additional options.
            %
            %       MaskImagePath    - The path to the image file whose
            %                          fully transparent area indicates
            %                          where the source image should be edited. 
            %                          Must be a valid PNG file, less than 4MB, 
            %                          and have the same dimensions as
            %                          source image. 
            %       
            %       NumImages        - Number of images to generate.  
            %                          Default value is 1. The max is 10. 
            %
            %       Size             - Size of the generated images. 
            %                          Must be one of 256x256, 512x512, or 
            %                          1024x1024 (default)

            arguments
                this                    (1,1)  openAIImages
                imagePath                     {mustBeValidFileType(imagePath)}
                prompt                        {mustBeTextScalar}
                nvp.MaskImagePath             {mustBeValidFileType(nvp.MaskImagePath)}
                nvp.NumImages           (1,1) {mustBePositive, mustBeInteger,...
                                                mustBeLessThanOrEqual(nvp.NumImages,10)} = 1
                nvp.Size                (1,1) string {mustBeMember(nvp.Size,["256x256", ...
                                                            "512x512", ...
                                                            "1024x1024"])} = "1024x1024"
            end
    
            % For now, this is only supported for "dall-e-2"
            if this.ModelName~="dall-e-2"
                error("llms:functionNotAvailableForModel", ...
                        llms.utils.errorMessageCatalog.getMessage("llms:functionNotAvailableForModel", ...
                        this.ModelName));
            end

            validatePromptSize(this.ModelName, prompt)

            endpoint = 'https://api.openai.com/v1/images/edits';

            % Required params
            numImages = num2str(nvp.NumImages);
            body = matlab.net.http.io.MultipartFormProvider( ...
                'image',matlab.net.http.io.FileProvider(imagePath), ...
                'prompt',matlab.net.http.io.FormProvider(prompt), ...
                'n',matlab.net.http.io.FormProvider(numImages),...
                'size',matlab.net.http.io.FormProvider(nvp.Size));

            % Optional param
            if isfield(nvp,"MaskImagePath")
                body.Names = [body.Names,"mask"];
                body.Parts = [body.Parts,{matlab.net.http.io.FileProvider(nvp.MaskImagePath)}];
            end

            % Send the HTTP Request
            response = sendRequest(this, endpoint, body);
            % Output the images
            images = extractImages(response);
        end

        function [images, response] = createVariation(this,imagePath,nvp)
            %createVariation Generate variations from a given image
            % 
            %   [IMAGES, RESPONSE] = createVariation(MDL, IMAGEPATH) generates new images
            %   from an original image
            %
            %       imagePath        - The path to the source image file. 
            %                          Must be a valid PNG file, less than 4MB, 
            %                          and square.
            %
            %   [IMAGES, RESPONSE] = createVariation(__, Name=Value) specifies
            %   additional options.
            %       
            %       NumImages        - Number of images to generate.  
            %                          Default value is 1. The max is 10. 
            %
            %       Size             - Size of the generated images. 
            %                          Must be one of "256x256", "512x512", or 
            %                          "1024x1024" (default)

            arguments
                this                    (1,1) openAIImages
                imagePath                     {mustBeValidFileType(imagePath)}
                nvp.NumImages           (1,1) {mustBePositive, mustBeInteger,...
                                                mustBeLessThanOrEqual(nvp.NumImages,10)} = 1
                nvp.Size                (1,1) string {mustBeMember(nvp.Size,["256x256", ...
                                                "512x512","1024x1024"])} = "1024x1024"
            end

            % For now, this is only supported for "dall-e-2"
            if this.ModelName~="dall-e-2"
                error("llms:functionNotAvailableForModel", ...
                        llms.utils.errorMessageCatalog.getMessage("llms:functionNotAvailableForModel", ...
                        this.ModelName));
            end

            endpoint = 'https://api.openai.com/v1/images/variations';

            numImages = num2str(nvp.NumImages);
            body = matlab.net.http.io.MultipartFormProvider(...
                'image',matlab.net.http.io.FileProvider(imagePath),...
                'n',matlab.net.http.io.FormProvider(numImages),...
                'size',matlab.net.http.io.FormProvider(nvp.Size));

            % Send the HTTP Request
            response = sendRequest(this, endpoint, body);
            % Output the images
            images = extractImages(response);
        end

        function response = sendRequest(this, endpoint, body)
        %sendRequest send request to the given endpoint, return response
            headers =  matlab.net.http.HeaderField('Authorization', "Bearer " + this.ApiKey);
            if isa(body,'struct')
                headers(2) =  matlab.net.http.HeaderField('Content-Type', 'application/json');
            end
            request =  matlab.net.http.RequestMessage('post', headers, body);

            httpOpts = matlab.net.http.HTTPOptions;
            httpOpts.ConnectTimeout = this.TimeOut;
            response = send(request, matlab.net.URI(endpoint), httpOpts);
        end
    end

    methods(Hidden)
        % Argument Validation Functions
        function mustBeValidSize(this, imagesize)
            if strcmp(this.ModelName,"dall-e-2")
                mustBeMember(imagesize,["256x256", "512x512","1024x1024"]);
            else
                mustBeMember(imagesize,["1024x1024","1792x1024","1024x1792"])
            end
        end
    end
end

function images = extractImages(response)

if response.StatusCode=="OK" &&  isfield(response.Body.Data.data,"url")
    % Output the images
    if isfield(response.Body.Data.data,"url")
        urls = arrayfun(@(x) string(x.url), response.Body.Data.data);
        images = arrayfun(@imread,urls,UniformOutput=false);
    else
        images = [];
    end

else
    images = [];
end
end

function validateSizeNVP(model, size)
if ismember(size,["1792x1024", "1024x1792"]) && model=="dall-e-2"
    error("llms:invalidOptionAndValueForModel", ...
        llms.utils.errorMessageCatalog.getMessage("llms:invalidOptionAndValueForModel", ...
        "Size", size, model));
end

if ismember(size,["256x256", "512x512"]) && model=="dall-e-3"
    error("llms:invalidOptionAndValueForModel", ...
        llms.utils.errorMessageCatalog.getMessage("llms:invalidOptionAndValueForModel", ...
        "Size", size, model));
end
end

function validatePromptSize(model, prompt)
numChars = numel(char(prompt));
if model=="dall-e-3"
    limitDalle3 = 4000;
    if numChars>limitDalle3
        error("llms:promptLimitCharacter", ...
            llms.utils.errorMessageCatalog.getMessage("llms:promptLimitCharacter", ...
            string(limitDalle3), model));
    end
else
    % dall-e-2
    limitDalle2 = 1000;
    if numChars>limitDalle2
        error("llms:promptLimitCharacter", ...
            llms.utils.errorMessageCatalog.getMessage("llms:promptLimitCharacter", ...
            string(limitDalle2), model));
    end
end
end

function mustBeValidFileType(filePath)
    mustBeFile(filePath);
    s = dir(filePath);
    if ~endsWith(s.name, ".png")
        error("llms:pngExpected", ...
            llms.utils.errorMessageCatalog.getMessage("llms:pngExpected"));
    end
    mustBeLessThan(s.bytes,4e+6)
end

function mustBeNonzeroLengthTextScalar(content)
mustBeNonzeroLengthText(content)
mustBeTextScalar(content)
end