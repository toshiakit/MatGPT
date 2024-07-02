# MatGPT - MATLAB&reg; app to access ChatGPT API from OpenAI&trade;
[![View MatGPT on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/126665-matgpt)
[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=toshiakit/MatGPT&file=MatGPT.mlapp)

![MatGPT Logo](images/MatGPTlogo.png)

MatGPT is a MATLAB app that allows you to easily access OpenAI's ChatGPT API. With the app, you can load a list of prompts for specific use cases and engage in conversations with ease. If you're new to ChatGPT and prompt engineering, MatGPT is a great way to learn. 

The app simply serves as an interface to the ChatGPT API. You should be familiar with the limitations and risks associated with using this technology as well as with [OpenAI terms and policies](https://openai.com/policies). You are responsible for any fees OpenAI may charge for the use of their API. 

MatGPT requires '[Large Language Models (LLMs) with MATLAB](https://github.com/matlab-deep-learning/llms-with-matlab/)' library maintained by MathWorks.

[MATLAB AI Chat Playground](https://www.mathworks.com/matlabcentral/playground/) is a great alternative to MatGPT on MATLAB Central. 

## What's New

* MatGPT loads 'LLMs with MATLAB' library as a submodule.
* MatGPT stores your API in MATLAB Vault on R2024a or later. The stored API will persist from session to session.
* MatGPT supports streaming API where response tokens are displayed as they come in.
* MatGPT detects a URL included in a prompt, and retrieves its web content into the chat.
* MatGPT lets you import a .m, .mlx, .csv or .txt file into the chat. PDF files are also supported if Text Analytics Toolbox is available.
* MatGPT supports GPT-4 Turbo with Vision. You can pass the URL to an image, or a local image file path ask questions about the image.
* MatGPT lets you generate an image via DALL·E 3 API. 
* MatGPT supports voice chat via Whisper API. 

Please note that:

* imported content will be truncated if it exceeds the context window limit.
* Streaming must be disabled to use image generation via DALL·E 3.

## Requirements

* **Submodule**: '[Large Language Models (LLMs) with MATLAB](https://github.com/matlab-deep-learning/llms-with-matlab/) 
* **MathWorks Products (https://www.mathworks.com)**: Use MatGPT to run on [MATLAB Online](https://www.mathworks.com/products/matlab-online.html) that comes with the most commonly used toolboxes. To use it on desktop, you must have MATLAB R2023a or later installed on your computer. 
* **OpenAI API Key**: Additionally, you will need your own API key from [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys). If you don’t want to set up an API access with OpenAI, [MATLAB AI Chat Playground](https://www.mathworks.com/matlabcentral/playground/) is a better option. 
* GPT-4 models are [available to all API users who have a history of successful payments](https://openai.com/blog/gpt-4-api-general-availability). If you have not made any payment to OpenAI, the GPT-4 models are not accessible. 

## Installation

### MATLAB Online

To use MatGPT on MATLAB Online, simply click [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=toshiakit/MatGPT&file=MatGPT.mlapp) MATLAB Online pulls the content of this repo, including "LLMS with MATLAB" submodule. 

#### MATLAB Desktop

Use Git commands to clone the repo to your local directory, and then clone the submodules. This will ensure you get the 'LLMs with MATLAB' library. 
```
git clone https://github.com/toshiakit/MatGPT.git
git submodule update --init
```
If you download MatGPT as a Zip file, the zip file will not contain the submodule. You need to download 'LLMs with MATLAB' separately and unzip into the 'LLMs with MATLAB' folder in the helpers folder. 

## How to use: MatGPT app

![MatGPT Chat Tab](images/MatGPT.gif)

1. Click on `+ New Chat` in the left nav to add a new chat. This opens the `Settings` tab. 
2. In the `Settings` tab, either choose a preset to populate the settings or customize on your own. Once you have completed the settings, click `Start New Chat` to initiate a chat. This will take you back to the `Main` tab. 
* Presets are loaded from [Presets.csv](contents/presets.csv) - feel free to customize your prompts. 
3. In the `Main` tab, a sample prompt is already provided based on the preset you selected, but feel free to replace it with your own. When you click `Send` button, the response will be shown in the 'Chat' tab. 
* The paperclip button lets you include the content of a m-file, live script file or csv file in the chat.
* If the prompt contains a URL, MatGPT ask you to confirm that you want to open the page. 
* The `Send` button and Paperclip button are disabled until a chat is configured in the `Settings` tab.
* If you want suggestion for follow-up questions in the response, check `Suggest follow-up questions` checkbox. Suggested questions appear as clickable buttons. You can copy a suggested question to the prompt box by clicking it.  
* If your prompt is intended to generate MATLAB code, check `Test Generated MATLAB Code` checkbox to test the returned code.
* The `Usage` tab shows the number of tokens used in the current chat session. 
* Add stop sequences in `Advanced` tab to specify the sequences where the API will stop generating further tokens.
4. Continue the conversation by keep adding more prompts and clicking `Send`. 
5. You can right-click or double-click a chat in the left navigation panel to rename, delete, or save the chat to a text file. 
6. When you close the app, the chat will be saved and will be reloaded into the left nav when you relaunch the app.

### Note:

* You can increase the connection timeout in the `Settings`. You can add proxy via [Web Preferences](https://www.mathworks.com/help/matlab/ref/preferences.html) in MATLAB.
* Streaming is enabled by default, but you can turn it off in the `Settings` tab. Usage data is not available in streaming mode. 

## What happened to chatGPT class?

chatGPT class was replaced by the framework provided via the '[Large Language Models (LLMs) with MATLAB](https://github.com/matlab-deep-learning/llms-with-matlab/)' repo. The new framework supports function calling and other latest features. Please refer to the documentation in the repo to learn how to use it.

## Acknowledgements
This code is adapted from [this MATLAB Answers comment](https://www.mathworks.com/matlabcentral/answers/1894530-connecting-to-chatgpt-using-api#answer_1154780) by [Hans Scharler](https://www.mathworks.com/matlabcentral/profile/authors/5863695) and uses [Brian Buechel](https://github.com/brianbuechel)'s [CodeChecker](helpers/CodeChecker.m) and other great contributions. The video shown above was created by [Angel Gonzalez Llacer](https://www.mathworks.com/matlabcentral/profile/authors/12391728). 
   
## License
The license for MatGPT is available in the [LICENSE.txt](LICENSE.txt) file in this GitHub repository.