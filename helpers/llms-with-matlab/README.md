# Large Language Models (LLMs) with MATLAB® [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab-deep-learning/llms-with-matlab)

This repository contains example code to demonstrate how to connect MATLAB to the OpenAI™ Chat Completions API (which powers ChatGPT™) as well as OpenAI Images API (which powers DALL·E™). This allows you to leverage the natural language processing capabilities of large language models directly within your MATLAB environment.

The functionality shown here serves as an interface to the ChatGPT and DALL·E APIs. To start using the OpenAI APIs, you first need to obtain OpenAI API keys. You are responsible for any fees OpenAI may charge for the use of their APIs. You should be familiar with the limitations and risks associated with using this technology, and you agree that you shall be solely responsible for full compliance with any terms that may apply to your use of the OpenAI APIs.

Some of the current LLMs supported are:
- gpt-3.5-turbo, gpt-3.5-turbo-1106
- gpt-4, gpt-4-1106-preview
- gpt-4-vision-preview (a.k.a. GPT-4 Turbo with Vision)
- dall-e-2, dall-e-3

For details on the specification of each model, check the official [OpenAI documentation](https://platform.openai.com/docs/models).

## Setup

If you would like to use this repository with MATLAB Online, simply click [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab-deep-learning/llms-with-matlab)

If you would like to use it with MATLAB Desktop, proceed with the following steps:

1. Clone the repository to your local machine.

    ```bash
    git clone https://github.com/matlab-deep-learning/llms-with-matlab.git
    ```
   
2. Open MATLAB and navigate to the directory where you cloned the repository.

3. Add the directory to the MATLAB path.

    ```matlab
    addpath('path/to/llms-with-matlab');
    ```

4. Set up your OpenAI API key. Create a `.env` file in the project root directory with the following content.

    ```
    OPENAI_API_KEY=<your key>
    ```
    
    Then load your `.env` file as follows:

    ```matlab
    loadenv(".env")
    ```

### MathWorks Products (https://www.mathworks.com)

- Requires MATLAB release R2023a or newer.

### 3rd Party Products:

- An active OpenAI API subscription and API key.


## Getting Started with Chat Completion API

To get started, you can either create an `openAIChat` object and use its methods or use it in a more complex setup, as needed.

### Simple call without preserving chat history

In some situations, you will want to use chat completion models without preserving chat history. For example, when you want to perform independent queries in a programmatic way.

Here's a simple example of how to use the `openAIChat` for sentiment analysis:

```matlab
% Initialize the OpenAI Chat object, passing a system prompt

% The system prompt tells the assistant how to behave, in this case, as a sentiment analyzer
systemPrompt = "You are a sentiment analyser. You will look at a sentence and output"+...
    " a single word that classifies that sentence as either 'positive' or 'negative'."+....
    "Examples: \n"+...
    "The project was a complete failure. \n"+...
    "negative \n\n"+...  
    "The team successfully completed the project ahead of schedule."+...
    "positive \n\n"+...
    "His attitude was terribly discouraging to the team. \n"+...
    "negative \n\n";

chat = openAIChat(systemPrompt);

% Generate a response, passing a new sentence for classification
txt = generate(chat,"The team is feeling very motivated")
% Should output "positive"
```

### Creating a chat system

If you want to create a chat system, you will have to create a history of the conversation and pass that to the `generate` function.

To start a conversation history, create a `openAIMessages` object:

```matlab
history = openAIMessages;
```

Then create the chat assistant:

```matlab
chat = openAIChat("You are a helpful AI assistant.");
```

Add a user message to the history and pass it to `generate`

```matlab
history = addUserMessage(history,"What is an eigenvalue?");
[txt, response] = generate(chat, history)
```

The output `txt` will contain the answer and `response` will contain the full response, which you need to include in the history as follows
```matlab
history = addResponseMessage(history, response);
```

You can keep interacting with the API and since we are saving the history, it will know about previous interactions.
```matlab
history = addUserMessage(history,"Generate MATLAB code that computes that");
[txt, response] = generate(chat,history);
% Will generate code to compute the eigenvalue
```

### Streaming the response

Streaming allows you to start receiving the output from the API as it is generated token by token, rather than wait for the entire completion to be generated. You can specifying the streaming function when you create the chat assistant. In this example, the streaming function will print the response to the command window.
```matlab
% streaming function
sf = @(x)fprintf("%s",x);
chat = openAIChat(StreamFun=sf);
txt = generate(chat,"What is Model-Based Design and how is it related to Digital Twin?")
% Should stream the response token by token
```

### Calling MATLAB functions with the API

Optionally, `Tools=functions` can be used to provide function specifications to the API. The purpose of this is to enable models to generate function arguments which adhere to the provided specifications. 
Note that the API is not able to directly call any function, so you should call the function and pass the values to the API directly. This process can be automated as shown in [ExampleFunctionCalling.mlx](/examples/ExampleFunctionCalling.mlx), but it's important to consider that ChatGPT can hallucinate function names, so avoid executing any arbitrary generated functions and only allow the execution of functions that you have defined. 

For example, if you want to use the API for mathematical operations such as `sind`, instead of letting the model generate the result and risk running into hallucinations, you can give the model direct access to the function as follows:


```matlab
f = openAIFunction("sind","Sine of argument in degrees");
f = addParameter(f,"x",type="number",description="Angle in degrees.");
chat = openAIChat("You are a helpful assistant.",Tools=f);
```

When the model identifies that it could use the defined functions to answer a query, it will return a `tool_calls` request, instead of directly generating the response:

```matlab
messages = openAIMessages;
messages = addUserMessage(messages, "What is the sine of 30?");
[txt, response] = generate(chat, messages);
messages = addResponseMessage(messages, response);
```

The variable `response` should contain a request for a function call.
```bash
>> response

response = 

  struct with fields:

             role: 'assistant'
          content: []
       tool_calls: [1×1 struct]

>> response.tool_calls

ans = 

  struct with fields:

           id: 'call_wDpCLqtLhXiuRpKFw71gXzdy'
         type: 'function'
     function: [1×1 struct]

>> response.tool_calls.function

ans = 

  struct with fields:

         name: 'sind'
    arguments: '{↵  "x": 30↵}'
```

You can then call the function `sind` with the specified argument and return the value to the API add a function message to the history:

```matlab
% Arguments are returned as json, so you need to decode it first
id = string(response.tool_calls.id);
func = string(response.tool_calls.function.name);
if func == "sind"
    args = jsondecode(response.tool_calls.function.arguments);
    result = sind(args.x);
    messages = addToolMessage(messages,id,func,"x="+result);
    [txt, response] = generate(chat, messages);
else
    % handle calls to unknown functions
end
```

The model then will use the function result to generate a more precise response:

```shell
>> txt

txt = 

    "The sine of 30 degrees is approximately 0.5."
```

### Extracting structured information with the API

Another useful application for defining functions is extract structured information from some text. You can just pass a function with the output format that you would like the model to output and the information you want to extract. For example, consider the following piece of text:

```matlab
patientReport = "Patient John Doe, a 45-year-old male, presented " + ...
    "with a two-week history of persistent cough and fatigue. " + ...
    "Chest X-ray revealed an abnormal shadow in the right lung." + ...
    " A CT scan confirmed a 3cm mass in the right upper lobe," + ...
    " suggestive of lung cancer. The patient has been referred " + ...
    "for biopsy to confirm the diagnosis.";
```

If you want to extract information from this text, you can define a function as follows:
```matlab
f = openAIFunction("extractPatientData","Extracts data about a patient from a record");
f = addParameter(f,"patientName",type="string",description="Name of the patient");
f = addParameter(f,"patientAge",type="number",description="Age of the patient");
f = addParameter(f,"patientSymptoms",type="string",description="Symptoms that the patient is having.");
```

Note that this function does not need to exist, since it will only be used to extract the Name, Age and Symptoms of the patient and it does not need to be called:

```matlab
chat = openAIChat("You are helpful assistant that reads patient records and extracts information", ...
    Tools=f);
messages = openAIMessages;
messages = addUserMessage(messages,"Extract the information from the report:" + newline + patientReport);
[txt, response] = generate(chat, messages);
```

The model should return the extracted information as a function call:
```shell
>> response

response = 

  struct with fields:

             role: 'assistant'
          content: []
        tool_call: [1×1 struct]

>> response.tool_calls

ans = 

  struct with fields:

           id: 'call_4VRtN7jb3pTPosMSb4ZaLoWP'
         type: 'function'
     function: [1×1 struct]

>> response.tool_calls.function

ans = 

  struct with fields:

         name: 'extractPatientData'
    arguments: '{↵  "patientName": "John Doe",↵  "patientAge": 45,↵  "patientSymptoms": "persistent cough, fatigue"↵}'
```

You can extract the arguments and write the data to a table, for example.

### Understand the content of an image

You can use gpt-4-vision-preview to experiment with image understanding. 
```matlab
chat = openAIChat("You are an AI assistant.", ModelName="gpt-4-vision-preview"); 
image_path = "peppers.png";
messages = openAIMessages;
messages = addUserMessageWithImages(messages,"What is in the image?",image_path);
[txt,response] = generate(chat,messages);
% Should output the description of the image
```

### Obtaining embeddings

You can extract embeddings from your text with OpenAI using the function `extractOpenAIEmbeddings` as follows:
```matlab
exampleText = "Here is an example!";
emb = extractOpenAIEmbeddings(exampleText);
```

The resulting embedding is a vector that captures the semantics of your text and can be used on tasks such as retrieval augmented generation and clustering.

```matlab
>> size(emb)

ans =

           1        1536
```
## Getting Started with Images API

To get started, you can either create an `openAIImages` object and use its methods or use it in a more complex setup, as needed.

```matlab
mdl = openAIImages(ModelName="dall-e-3");
images = generate(mdl,"Create a 3D avatar of a whimsical sushi on the beach. He is decorated with various sushi elements and is playfully interacting with the beach environment.");
figure
imshow(images{1})
% Should output an image based on the prompt
```

## Examples
To learn how to use this in your workflows, see [Examples](/examples/).

- [ExampleStreaming.mlx](/examples/ExampleStreaming.mlx): Learn to implement a simple chat that stream the response. 
- [ExampleSummarization.mlx](/examples/ExampleSummarization.mlx): Learn to create concise summaries of long texts with ChatGPT. (Requires Text Analytics Toolbox™)
- [ExampleChatBot.mlx](/examples/ExampleChatBot.mlx): Build a conversational chatbot capable of handling various dialogue scenarios using ChatGPT. (Requires Text Analytics Toolbox)
- [ExampleFunctionCalling.mlx](/examples/ExampleFunctionCalling.mlx): Learn how to create agents capable of executing MATLAB functions. 
- [ExampleParallelFunctionCalls.mlx](/examples/ExampleParallelFunctionCalls.mlx): Learn how to take advantage of parallel function calling. 
- [ExampleRetrievalAugmentedGeneration.mlx](/examples/ExampleRetrievalAugmentedGeneration.mlx): Learn about retrieval augmented generation with a simple use case. (Requires Text Analytics Toolbox™)
- [ExampleGPT4Vision.mlx](/examples/ExampleGPT4Vision.mlx): Learn how to use GPT-4 Turbo with Vision to understand the content of an image. 
- [ExampleJSONMode.mlx](/examples/ExampleJSONMode.mlx): Learn how to use JSON mode in chat completions
- [ExampleDALLE.mlx](/examples/ExampleDALLE.mlx): Learn how to generate images, create variations and edit the images. 

## License

The license is available in the license.txt file in this GitHub repository.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2023-2024 The MathWorks, Inc.
