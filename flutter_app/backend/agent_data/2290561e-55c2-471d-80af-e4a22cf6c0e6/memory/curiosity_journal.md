# Curiosity Journal

### 2026-03-02 - Dify Platform Latest Developments (HITL & MCP)
- **Finding**: Dify released v1.13.0 with Human-in-the-Loop (HITL) support in the community version, introducing a "Human Input" node that allows AI-human collaboration within workflows (previously workflows were either fully automated or fully manual). Additionally, Dify now supports MCP (Model Context Protocol) integration for connecting external tools and APIs. These are significant capability upgrades for the open-source LLM app platform space.
- **Source**: https://forum.dify.ai/t/1-13-0-human-in-the-loop-and-workflow-execution-upgrades-latest-community-version/1085
- **Relevance**: high — Directly impacts the BISHENG competitive analysis I recently completed. HITL is a differentiating feature that should be tracked in future competitive comparisons. MCP integration also changes the tool ecosystem landscape.
- **Follow-up**: Check if BISHENG, FastGPT, or Langflow have similar HITL capabilities. Monitor how MCP adoption progresses across competing platforms.

### 2026-03-02 - MCP & HITL Adoption Across Open-Source LLM Platforms (Follow-up)
- **Finding**: Comprehensive comparison of MCP and HITL support across the four major open-source LLM platforms:
  - **Dify**: MCP ✅ + HITL ✅ (v1.13.0, "Human Input" node)
  - **Langflow**: MCP ✅ (v1.7, both server & client, streamable HTTP + SSE) + HITL ❌ (still an open GitHub issue #6867, marked stale)
  - **BISHENG**: MCP ✅ (supports loading MCP tools, SSE protocol) + HITL status unclear (no direct evidence found)
  - **FastGPT**: MCP ✅ (v4.9.6, apps callable via MCP, SSE protocol support) + HITL ✅ (v4.9.6 added "interactive nodes" enabling human participation in batch execution loops)
  
  Key insight: MCP has become a universal standard across all four platforms — it's now table stakes. HITL is the new differentiator, with only Dify and FastGPT having shipped it. Langflow's HITL request has gone stale, suggesting it's not a priority.
- **Sources**: 
  - https://docs.langflow.org/mcp-server
  - https://github.com/langflow-ai/langflow/issues/6867
  - https://blog.csdn.net/tilamisu1321/article/details/149834372
  - https://doc.fastgpt.cn/en/docs/upgrading/4-9/496
  - https://tolearn.blog/blog/mcp-model-context-protocol-guide
- **Relevance**: high — Directly extends the BISHENG competitive analysis. MCP is now commodity; HITL is the new frontier for differentiation. This should be incorporated into future competitive reports.
- **Follow-up**: Track BISHENG's HITL roadmap. Monitor Langflow's response to HITL demand. Check if MCP Apps (UI capabilities for MCP clients, announced Jan 2026) gets adopted by these platforms.
