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
