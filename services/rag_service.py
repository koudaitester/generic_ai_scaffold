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
