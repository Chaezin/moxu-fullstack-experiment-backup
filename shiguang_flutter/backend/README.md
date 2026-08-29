# 拾光后端

## 本地启动

在 `backend` 目录执行：

```powershell
.venv\Scripts\python.exe -m uvicorn run:app --host 127.0.0.1 --port 8000 --reload
```

默认使用本地 SQLite；部署时设置 `SHIGUANG_DATABASE_URL` 为 PostgreSQL 连接串，并设置长度足够的 `SHIGUANG_SECRET_KEY`。

## 每日补偿分析

```powershell
.venv\Scripts\python.exe worker_cli.py
```

生产环境用系统计划任务每天运行一次；常驻服务也可以在消息接口之外持续调用同一 Worker 函数。

用户在页面设置每日整理时间后，建议让系统计划任务每 5 分钟执行一次到期检查：

```powershell
.venv\Scripts\python.exe scheduler_cli.py
```

调度器按每个用户保存的 IANA 时区判断本地时间，并通过运行日志保证同一用户同一天最多成功执行一次。`worker_cli.py` 保留为管理员手动清空所有待处理任务的补偿入口。

## 测试

```powershell
.venv\Scripts\python.exe -m pytest -q
```

聊天保存、用户隔离、幂等重试、技能阈值、自动卡片、删除引用和卡片纠错均有测试覆盖。

