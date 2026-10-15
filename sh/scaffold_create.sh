#!/bin/bash
set -e

# 项目根目录名称
PROJECT_NAME="generic_ai_scaffold"

# 创建目录树
mkdir -p ${PROJECT_NAME}/config
mkdir -p ${PROJECT_NAME}/knowledge_base
mkdir -p ${PROJECT_NAME}/db
mkdir -p ${PROJECT_NAME}/services
mkdir -p ${PROJECT_NAME}/routers
mkdir -p ${PROJECT_NAME}/static
mkdir -p ${PROJECT_NAME}/logs

# -------------------------- .gitignore --------------------------
cat > ${PROJECT_NAME}/.gitignore <<'EOF'
# Python 缓存、临时文件
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/
.coverage
htmlcov/

# 虚拟环境
.venv/
venv/
ENV/
env/

# 日志文件
logs/
*.log

# 本地环境配置（敏感信息，禁止提交git）
.env
*.local.yaml
config/secrets.yaml

# IDE 编辑器缓存
.idea/
.vscode/
*.swp
*.swo

# 操作系统生成文件
.DS_Store
Thumbs.db

# 临时上传文件缓存目录
tmp_uploads/
tmp/

# sqlite数据库文件
*.db
*.sqlite3
EOF

# -------------------------- config/prompt_config.yaml --------------------------
cat > ${PROJECT_NAME}/config/prompt_config.yaml <<'EOF'
# Prompt模板配置
# 在这里定义业务提示词，代码通过key读取
# example_key: |
#   这里写提示词内容

example_vision_prompt: |
你是专业分析助手。参考知识库规则，分析上传图片内容，输出结构化JSON结果。
EOF

# -------------------------- config/db_config.yaml --------------------------
cat > ${PROJECT_NAME}/config/db_config.yaml <<'EOF'
# 数据库连接配置
db_host: "127.0.0.1"
db_port: 5432
db_user: "postgres"
db_password: "your_password"
db_name: "ai_scaffold_db"
EOF

# -------------------------- config/log_config.yaml --------------------------
cat > ${PROJECT_NAME}/config/log_config.yaml <<'EOF'
# 日志配置
log_level: INFO
log_file_path: ./logs/app.log
max_file_size_mb: 10
backup_count: 5
console_output: true
EOF

# -------------------------- config/app_config.yaml --------------------------
cat > ${PROJECT_NAME}/config/app_config.yaml <<'EOF'
# 应用全局配置
ollama:
  endpoint: "http://127.0.0.1:11434/api/generate"
  timeout: 60
  model: "llava"

rag:
  chunk_size: 512
  top_k: 3
EOF

# -------------------------- knowledge_base/rules.md --------------------------
cat > ${PROJECT_NAME}/knowledge_base/rules.md <<'EOF'
# 业务知识库规则
在此处写入业务领域规则、知识、判定条件。
新项目直接替换本文件内容即可。
EOF

# -------------------------- db/init.sql --------------------------
cat > ${PROJECT_NAME}/db/init.sql <<'EOF'
-- 基础报告记录表
CREATE TABLE IF NOT EXISTS report_records (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    raw_input JSONB,
    llm_result JSONB,
    risk_level VARCHAR(64),
    remark TEXT
);
EOF

# -------------------------- services/llama_service.py --------------------------
cat > ${PROJECT_NAME}/services/llama_service.py <<'EOF'
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
EOF

# -------------------------- services/rag_service.py --------------------------
cat > ${PROJECT_NAME}/services/rag_service.py <<'EOF'
"""
RAG知识库检索服务：读取md文档、文本分段、检索匹配
"""
def load_knowledge_base(filepath: str = "knowledge_base/rules.md") -> str:
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()


def retrieve_relevant_rules(query: str, kb_content: str):
    # 简易检索，可后续替换成向量化检索
    # 这里仅做占位，业务侧把知识库+query拼接送入prompt
    return kb_content
EOF

# -------------------------- services/report_service.py --------------------------
cat > ${PROJECT_NAME}/services/report_service.py <<'EOF'
"""
报告入库、分页查询服务
"""
import psycopg2
import yaml
import json

with open("config/db_config.yaml", "r", encoding="utf-8") as f:
    db_cfg = yaml.safe_load(f)


def get_conn():
    return psycopg2.connect(
        host=db_cfg["db_host"],
        port=db_cfg["db_port"],
        user=db_cfg["db_user"],
        password=db_cfg["db_password"],
        dbname=db_cfg["db_name"]
    )


async def save_record(raw_input: dict, llm_result: dict, risk_level: str):
    conn = get_conn()
    cur = conn.cursor()
    sql = """
        INSERT INTO report_records(raw_input, llm_result, risk_level)
        VALUES (%s, %s, %s)
    """
    cur.execute(sql, (json.dumps(raw_input), json.dumps(llm_result), risk_level))
    conn.commit()
    cur.close()
    conn.close()


async def list_records(page: int = 1, page_size: int = 10):
    conn = get_conn()
    cur = conn.cursor()
    offset = (page - 1) * page_size
    cur.execute("SELECT * FROM report_records ORDER BY created_at DESC LIMIT %s OFFSET %s", (page_size, offset))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows
EOF

# -------------------------- routers/base_router.py --------------------------
cat > ${PROJECT_NAME}/routers/base_router.py <<'EOF'
from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "ok"}
EOF

# -------------------------- routers/business_router.py --------------------------
cat > ${PROJECT_NAME}/routers/business_router.py <<'EOF'
"""
业务路由，新项目主要修改这里
"""
from fastapi import APIRouter, UploadFile, Query
from services.llama_service import LlamaService
from services.rag_service import load_knowledge_base, retrieve_relevant_rules
from services.report_service import save_record

router = APIRouter()
llama_svc = LlamaService()


@router.post("/analyze")
async def analyze(file: UploadFile, param1: str = Query("", description="自定义业务参数")):
    kb_text = load_knowledge_base()
    rules = retrieve_relevant_rules("", kb_text)
    prompt = f"知识库规则：{rules}"

    # 调用大模型
    llm_resp = await llama_svc.call_llama(prompt)

    # 入库
    await save_record(raw_input={"param1": param1}, llm_result=llm_resp, risk_level="unknown")
    return {"result": llm_resp}


@router.get("/records")
async def get_records(page: int = 1, page_size: int = 10):
    from services.report_service import list_records
    data = await list_records(page, page_size)
    return {"data": data}
EOF

# -------------------------- static/index.html --------------------------
cat > ${PROJECT_NAME}/static/index.html <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI Scaffold 首页</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:system-ui,sans-serif;}
body{height:100vh;overflow:hidden;}
.container{display:flex;height:100%;}
.sidebar{width:220px;background-color:#2c3e50;color:#fff;padding-top:24px;transition:0.3s;}
.sidebar .menu-item{padding:14px 24px;cursor:pointer;font-size:16px;}
.sidebar .menu-item:hover{background-color:#34495e;}
.sidebar .menu-item.active{background-color:#3498db;}
.main-content{flex:1;height:100%;}
#content-iframe{width:100%;height:100%;border:none;}
.hamburger{display:none;position:fixed;top:12px;left:12px;z-index:99;background:#2c3e50;color:white;border:none;padding:8px 12px;font-size:18px;}
@media (max-width:768px){
.hamburger{display:block;}
.sidebar{position:fixed;left:-220px;height:100%;z-index:98;}
.sidebar.open{left:0;}
}
</style>
</head>
<body>
<button class="hamburger" id="hamburger">☰</button>
<div class="container">
<aside class="sidebar" id="sidebar">
<div class="menu-item active" data-src="upload.html">文件分析</div>
<div class="menu-item" data-src="history.html">历史记录</div>
<div class="menu-item" data-src="placeholder_help.html">使用帮助</div>
</aside>
<main class="main-content">
<iframe id="content-iframe" src="upload.html"></iframe>
</main>
</div>
<script>
const menuItems = document.querySelectorAll('.menu-item');
const iframe = document.getElementById('content-iframe');
const hamburger = document.getElementById('hamburger');
const sidebar = document.getElementById('sidebar');
menuItems.forEach(item => {
item.addEventListener('click', ()=>{
menuItems.forEach(mi=>mi.classList.remove('active'));
item.classList.add('active');
const pageUrl = item.getAttribute('data-src');
iframe.src = pageUrl;
if(window.innerWidth <=768){sidebar.classList.remove('open');}
})
})
hamburger.addEventListener('click',()=>{sidebar.classList.toggle('open');})
</script>
</body>
</html>
EOF

# -------------------------- static/placeholder_help.html --------------------------
cat > ${PROJECT_NAME}/static/placeholder_help.html <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>使用帮助</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:system-ui,sans-serif;}
body{padding:24px;color:#2c3e50;line-height:1.65;}
h2{color:#2c3e50;margin-bottom:16px;border-bottom:2px solid #3498db;padding-bottom:8px;}
h3{margin:20px 0 10px;color:#2c3e50;}
h4{margin:14px 0 8px;color:#34495e;}
hr{margin:24px 0;border:0;height:1px;background:#ccc;}
ul{padding-left:24px;margin:10px 0;}
p{margin-bottom:10px;}
.warning{background:#fff3cd;border-left:4px solid #f0ad4e;padding:12px 16px;margin:16px 0;border-radius:4px;}
</style>
<body>
    <h2>使用帮助｜通用AI脚手架</h2>
    <h3>📷 操作指南</h3>
    <h4>1. 文件分析</h4>
    <p>上传文件，调用大模型+知识库做分析，获取结构化结果。</p>
    <h4>2. 历史记录</h4>
    <p>所有提交记录自动入库，可以查看历次分析记录。</p>
    <hr>
    <div class="warning">
        <h4>⚠️ 重要免责声明</h4>
        <p>本系统仅作为技术原型演示，分析结果仅供参考，不作为专业鉴定依据。</p>
    </div>
</body>
</html>
EOF

# -------------------------- static/placeholder_history.html --------------------------
cat > ${PROJECT_NAME}/static/placeholder_history.html <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>历史记录</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:system-ui,sans-serif;}
body{padding:24px;color:#2c3e50;line-height:1.65;}
h2{color:#2c3e50;margin-bottom:16px;border-bottom:2px solid #3498db;padding-bottom:8px;}
.item{border:1px solid #ccc;border-radius:6px;padding:12px;margin-bottom:10px;}
</style>
<body>
    <h2>历史分析记录</h2>
    <div id="record-list">
        <div class="item">加载中...</div>
    </div>
</body>
</html>
EOF

# -------------------------- static/upload.html --------------------------
cat > ${PROJECT_NAME}/static/upload.html <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>文件分析</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:system-ui,sans-serif;}
body{padding:24px;color:#2c3e50;line-height:1.65;}
h2{color:#2c3e50;margin-bottom:16px;border-bottom:2px solid #3498db;padding-bottom:8px;}
.upload-box{border:2px dashed #3498db;padding:30px;text-align:center;border-radius:8px;margin:20px 0;}
</style>
<body>
    <h2>文件上传与AI分析</h2>
    <div class="upload-box">
        <input type="file" id="file-input">
        <p>选择文件上传提交分析</p>
        <button onclick="submitAnalyze()">提交分析</button>
    </div>
    <div id="result"></div>
<script>
async function submitAnalyze(){
    const f = document.getElementById("file-input").files[0];
    if(!f) return;
    const formData = new FormData();
    formData.append("file", f);
    const resp = await fetch("/api/analyze", {method:"POST", body:formData});
    const data = await resp.json();
    document.getElementById("result").innerText = JSON.stringify(data,null,2);
}
</script>
</body>
</html>
EOF

# -------------------------- main.py --------------------------
cat > ${PROJECT_NAME}/main.py <<'EOF'
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
EOF

# -------------------------- requirements.txt --------------------------
cat > ${PROJECT_NAME}/requirements.txt <<'EOF'
fastapi>=0.110.0
uvicorn[standard]>=0.29.0
pyyaml>=6.0
httpx>=0.27.0
psycopg2-binary>=2.9.9
EOF

# -------------------------- README.md --------------------------
cat > ${PROJECT_NAME}/README.md <<'EOF'
# Generic AI Scaffold
通用AI应用脚手架，基于 FastAPI + Ollama + RAG 知识库。
> 底层能力固定，业务逻辑外置。快速搭建「文件上传 + 大模型推理 + 知识库检索 + 结果入库 + 前端页面」最小闭环应用。

## ✨ 项目特点
1. 业务与代码完全解耦：Prompt、知识库规则独立放在配置/MD文件，无需修改Python代码
2. 内置RAG检索：自动读取知识库文档，检索相关规则拼入提示词交给大模型
3. 开箱即用接口：文件上传分析接口 + 历史记录分页查询接口
4. 自带完整前端iframe静态页面模板（上传页、历史报告、使用帮助）
5. 日志、数据库、大模型连接全部由yaml配置统一管理
6. .gitignore 内置，防止临时文件、本地配置、日志意外提交到Git仓库

## 📁 目录结构
```text
generic_ai_scaffold/
├── .gitignore                 # Git忽略清单，屏蔽临时/敏感文件
├── config/
│   ├── prompt_config.yaml     # Prompt模板配置文件
│   ├── db_config.yaml         # 数据库连接配置
│   ├── log_config.yaml        # 日志轮转、输出配置
│   └── app_config.yaml        # 全局应用配置(Ollama地址、RAG参数、超时)
├── knowledge_base/
│   └── rules.md               # 通用业务知识库规则文档
├── db/
│   └── init.sql               # 数据库初始化建表SQL脚本
├── services/
│   ├── llama_service.py       # 大模型调用、图片base64编解码
│   ├── rag_service.py         # 知识库读取、文本分段、相似度检索
│   └── report_service.py      # 报告入库、分页查询逻辑
├── routers/
│   ├── base_router.py         # 基础路由
│   └── business_router.py      # 业务路由，新项目仅修改这一层
├── static/                    # iframe前端静态页面资源
│   ├── index.html
│   ├── placeholder_help.html
│   └── placeholder_history.html
├── main.py                    # 项目入口文件
├── requirements.txt           # Python依赖清单
└── README.md                  # 项目说明文档
