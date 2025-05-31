"""
LLM take input


-system prompts: ur an emotional translator for blind people, and I need you to explain to blind people what is sent, which you will recieve the following content, of data and coordinates etc.
-   user prompts: data object


"""
import ollama

ollama.pull("gemma:3b")
async def LLM_proc(data):
    system_prompt = "You are an emotional translator for blind people. Explain to blind people what is sent, including data and coordinates."
    full_prompt = f"{system_prompt}\n{data}"
    response = ollama.generate(
        model="gemma:3b",
        prompt=full_prompt,
        stream=True
    )
