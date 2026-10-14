"""
大模型调用服务：图片base64处理、ollama请求封装
"""
import httpx
import yaml
import json

with open("config/app_config.yaml", "r", encoding="utf-8") as f:
    app_cfg = yaml.safe_load(f)
ollama_cfg = app_cfg["ollama"]


class LlamaService:
    def __init__(self):
        self.model = ollama_cfg["model"]
        self.endpoint = ollama_cfg["endpoint"]
        self.timeout = ollama_cfg["timeout"]

    async def call_llama(self, prompt: str, image_b64=None):
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
        }
        if image_b64:
            payload["images"] = [image_b64]

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            resp = await client.post(self.endpoint, json=payload)
            return resp.json()
