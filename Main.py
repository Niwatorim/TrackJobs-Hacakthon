from flask import Flask
from LLM_process import LLM_proc
import json
import ollama

app=Flask("Demo hacks")

ollama.pull("gemma:3b")
def img(webdata):
    pass

@app.route("/webcam",methods = ["POST"])
def webcam(web_data,user_req):
    """
    Post in json: (faster if hash)
    data=[object,coordinates, direction, distance]
    
    Boss code here
    """
    obj,direction,distance = img(web_data) 
    
    data = [f"object detect is {obj}",f"{direction}",f"{distance}", f"user input is:{user_req}"]

    try:
        print(LLM_proc(data))
        result="hello"
        return 200, result
    except Exception as e:
        return 400

