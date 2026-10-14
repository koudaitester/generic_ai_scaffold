-- 基础报告记录表
CREATE TABLE IF NOT EXISTS report_records (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    raw_input JSONB,
    llm_result JSONB,
    risk_level VARCHAR(64),
    remark TEXT
);
