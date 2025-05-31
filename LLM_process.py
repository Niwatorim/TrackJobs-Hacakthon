"""
LLM take input


-system prompts: ur an emotional translator for blind people, and I need you to explain to blind people what is sent, which you will recieve the following content, of data and coordinates etc.
-   user prompts: data object


"""
from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate

def LLM_proc(data,user):
    template = """
    You are assistance to blind people, and need to answer questions about the object. Respond with only 1 sentence. The details of the object is:
    {data}
    Here is the user request: {user}
    """
    model = OllamaLLM(model="gemma3")
    prompt =  ChatPromptTemplate.from_template(template)
    chain = prompt|model
    result = chain.invoke({"data":data,"user":user})
    print(result)
    return result
