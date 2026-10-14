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
