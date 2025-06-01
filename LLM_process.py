"""
LLM take input


-system prompts: ur an emotional translator for blind people, and I need you to explain to blind people what is sent, which you will recieve the following content, of data and coordinates etc.
-   user prompts: data object

"""

def LLM_proc(data, user,chain):
    if "where" in user.lower():
        response = "Say the location of the spoon and if it is close or not, in one sentence"
    elif "cutlery" in user.lower():
        response = "If any cutlery is found, say only that it exists and its direction"
    elif "is this" in user.lower():
        response = "Only respond if it is an object or not"
    else:
        response = ""

    result = chain.invoke({
        "data": data,
        "user": user,
        "response": response
    })
    return result


