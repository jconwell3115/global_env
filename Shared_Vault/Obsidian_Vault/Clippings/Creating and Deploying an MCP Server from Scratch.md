---
title: "Creating and Deploying an MCP Server from Scratch"
source: "https://towardsdatascience.com/creating-and-deploying-an-mcp-server-from-scratch/"
author:
  - "[[Vyacheslav Efimov]]"
published: 2025-09-22
created: 2025-09-24
description: "A step-by-step guide for putting an MCP server online in minutes"
tags:
  - "clippings"
---
[Skip to content](https://towardsdatascience.com/creating-and-deploying-an-mcp-server-from-scratch/#wp--skip-link--target)

## Introduction

During one of the weekends in September 2025, I took part in a hackathon organized by Mistral in Paris. All the teams had to create an MCP server and integrate it into Mistral.

Though my team did not win anything, it was a fantastic personal experience! Additionally, I had never created an MCP server before, so it allowed me to gain direct experience with new technologies.

As a result, we created [**Prédictif**](https://www.youtube.com/watch?v=5tNjjvV4B6g)  —  an MCP server allowing to train and test machine learning models directly in the chat and persist saved datasets, results and models across different conversations.

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/predictif-1024x360.webp)

Prédictif logo

> *Given that I really enjoyed the event, I decided to take it a step further and write this article to provide other engineers with a simple introduction to MCP and also offer a guide on creating an MCP server from scratch.*

> *If you are curious, the hackathon’s solutions from all teams are [here](https://cerebralvalley.ai/e/mistral-mcp-hackathon/hackathon/gallery)*.

## MCP

AI agents and MCP servers are relatively new technologies that are currently in high demand in the machine learning world.

**MCP** stands for *“Model Context Protocol”* and was initially developed in 2024 by Anthropic and then open-sourced. The motivation for creating MCP was the fact that different LLM vendors (OpenAI, Google, Mistral, etc.) provided different APIs for creating external tools (connectors) for their LLMs.

As a result, if a developer created a connector for OpenAI, then they would have to perform another integration if they wanted to plug it in for Mistral and so on. This approach did not allow the simple reuse of connectors. That is where MCP stepped in.

With MCP, developers can create a tool and reuse it across multiple MCP-compatible LLMs. It results in a much simpler workflow for developers as they no longer need to perform additional integrations. The same is compatible with many LLMs.

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/MCP-2-1024x509.png)

Two diagrams illustrating the developers’ workflow in the past, when there was no MCP (left), and after the MCP’s introduction (right). As we can see, MCP unifies the integration process; thus, the same tool can be connected agnostically to multiple vendors without additional steps.

> *For information, MCP uses **JSON-RPC** protocol.*

## Example

### Step 1

We are going to build a very simple MCP server that will have only one tool, whose goal will be to greet the user. For that, we are going to use FastMCP — a library that allows us to build MCP servers in a Pythonic way.  
First of all, we need to setup the environment:

```bash
uv init hello-mcp
cd hello-mcp
```

Add a fastmcp dependency (this will update the *pyproject.toml* file):

```bash
uv add fastmcp
```

Create a main.py file and put the following code there:

```python
from mcp.server.fastmcp import FastMCP
from pydantic import Field

mcp = FastMCP(
    name="Hello MCP Server",
    host="0.0.0.0",
    port=3000,
    stateless_http=True,
    debug=False,
)

@mcp.tool(
    title="Welcome a user",
    description="Return a friendly welcome message for the user.",
)
def welcome(
    name: str = Field(description="Name of the user")
) -> str:
    return f"Welcome {name} from this amazing application!"

if __name__ == "__main__":
    mcp.run(transport="streamable-http")
```

Great! Now the MCP server is complete and can even be deployed locally:

```bash
uv run python main.py
```

From now on, create a GitHub repository and push the local project directory there.

### Step 2

Our MCP server is ready, but is not deployed. For deployment, we are going to use [**Alpic**](https://alpic.ai/) — a platform that allows us to deploy MCP servers in literally several clicks. For that, create an account and sign in to Alpic.

In the menu, choose an option to create a new project. Alpic proposes to import an existing Git repository. If you connect your GitHub account to Alpic, you should be able to see the list of available repositories that can be used for deployment. Select the one corresponding to the MCP server and click “Import”.

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/Frame-7-1024x354.png)

In the following window, Alpic proposes several options to configure the environment. For our example, you can leave these options by default and click *“Deploy”*.

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/Frame-8-1024x508.png)

After that, Alpic will construct a Docker container with the imported repository. Depending on the complexity, deployment may take some time. If everything goes well, you will see the *“Deployed”* status with a green circle near it.

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/Frame-3-1024x507.png)

Under the label *“Domain”*, there is a JSON-RPC address of the deployed server. Copy it for now, as we will need to connect it in the next step.

### Step 3

The MCP server is built. Now we need to connect it to the LLM provider so that we can use it in conversations. In our example, we will use Mistral, but the connection process should be similar for other LLM providers.

In the left menu, select the “Connectors” option, which will open a new window with available connectors. Connectors enable LLMs to connect to MCP servers. For example, if you add a GitHub connector to Mistral, then in the chat, if needed, LLM will be able to search code in your repositories to provide an answer to a given prompt.

In our case, we want to import a custom MCP server we have just built, so we click on the “Add connector” button.

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/Frame-4-1024x411.png)

In the modal window, navigate to “Custom MVP Connector” and fill in the necessary information as shown in the screenshot below. For the connector server, use the HTTPS address of the deployed MCP server in step 2.

After the connector is added, you can see it in the connectors’ menu:

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/7-1024x542.png)

If you click on the MCP connector, in the *“Functions”* subwindow, you will see a list of implemented tools in the MCP server. In our example, we have only implemented a single tool *“Welcome”*, so it is the only function we see here.

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/8-1024x548.png)

### Step 4

Now, return to the chat and click the *“Enable tools”* button, which allows you to specify the tools or MCP servers the LLM is permitted to use.

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/Frame-6-1024x295.png)

Click on the checkbox corresponding to our connector.

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/Frame-1-1024x496.png)

Now it is time to test the connector. We can ask the LLM to use the “Welcome” tool to greet the user. In Mistral chat, if the LLM recognizes that it needs to use an external tool, a modal window appears, displaying the tool name (*“Welcome”*) and the arguments it will take (*name = “Francisco”*).

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/Frame-5-1024x366.png)

To confirm the choice, click on *“Continue”*. In that case, we will get a response:

![](https://contributor.insightmediagroup.io/wp-content/uploads/2025/09/12-1024x432.png)

Excellent! Our MCP server is working correctly. Similarly, we can create more complex tools.

## Conclusion

In this article, we introduce MCP as an efficient mechanism for creating connectors with LLM vendors. Its simplicity and reusability have made MCP very popular nowadays, allowing developers to reduce the time required to implement LLM plugins.

Furthermore, we have examined a simple example that demonstrates how to create an MCP server. In reality, nothing prevents developers from building more advanced MCP applications and leveraging additional functionality from LLM providers.

For example, in the case of Mistral, MCP servers can utilize the functionality of Libraries and Documents, allowing tools to take as input not only text prompts but also uploaded files. These results can be saved in the chat and made persistent across different conversations.

## Resources

- [Introducing the Model Context Protocol | Anthropic](https://www.anthropic.com/news/model-context-protocol)

*All images unless otherwise noted are by the author.*

---

Towards Data Science is a community publication. Submit your insights to reach our global audience and earn through the TDS Author Payment Program.

[Write for TDS](https://towardsdatascience.com/questions-96667b06af5/)

## Related Articles

- ![](https://towardsdatascience.com/wp-content/uploads/2024/08/0c09RmbCCpfjAbSMq.png)
	## Implementing Convolutional Neural Networks in TensorFlow
	Step-by-step code guide to building a Convolutional Neural Network
	6 min read
- ## What Do Large Language Models “Understand”?
	A deep dive on the meaning of understanding and how it applies to LLMs
	31 min read
- ![Photo by Krista Mangulsone on Unsplash](https://towardsdatascience.com/wp-content/uploads/2024/08/0GyVVTbgotH-DhGPH-scaled.jpg)
	Photo by Krista Mangulsone on Unsplash
	## How to Forecast Hierarchical Time Series
	A beginner’s guide to forecast reconciliation
	13 min read
- ![Image from Canva.](https://towardsdatascience.com/wp-content/uploads/2024/08/1UAA9jQVdqMXnwzYiz8Q53Q.png)
	Image from Canva.
	## 3 AI Use Cases (That Are Not a Chatbot)
	Feature engineering, structuring unstructured data, and lead scoring
	7 min read
- ![Sample transaction chatbot conversation, Image by Authors](https://towardsdatascience.com/wp-content/uploads/2024/08/1HTULJI9sLlOrIHytzAx4wQ.png)
	Sample transaction chatbot conversation, Image by Authors
	## Integrating LLM Agents with LangChain into VICA
	Learn how we use LLM Agents to improve and customise transactions in a chatbot!
	17 min read
- ![Image by author](https://towardsdatascience.com/wp-content/uploads/2024/07/1Zf6XTb6jDQXVOt-N9S_YTg.png)
	Image by author
	## Deep Dive into LSTMs & xLSTMs by Hand ✍️
	Explore the wisdom of LSTM leading into xLSTMs - a probable competition to the present-day LLMs
	13 min read
- ![Photo by Rohan Makhecha on Unsplash](https://towardsdatascience.com/wp-content/uploads/2022/03/0B5fQH3hQtbD7a_CC-scaled.jpg)
	Photo by Rohan Makhecha on Unsplash
	## Check Your Biases
	Symbolic Engines and Unexpected Results - A Personal Coding Experience
	9 min read

Some areas of this page may shift around if you resize the browser window. Be sure to check heading and document order.

### Unlock Towards Data Science with a Free Account

All articles on Towards Data Science are available to registered users. Create a free account today to access this article and thousands more.