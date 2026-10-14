"""
项目入口文件
"""
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from routers import base_router, business_router
import yaml
import logging.config

app = FastAPI(title="Generic AI Scaffold")

# 挂载静态资源
app.mount("/static", StaticFiles(directory="static"), name="static")

# 注册路由
app.include_router(base_router.router, prefix="/api")
app.include_router(business_router.router, prefix="/api")

@app.get("/")
async def root():
    return {"msg": "Welcome to Generic AI Scaffold, visit /static/index.html for frontend page"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
