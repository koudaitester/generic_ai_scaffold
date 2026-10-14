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

