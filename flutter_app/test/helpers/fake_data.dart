/// Fake data maps for widget tests.
/// Mirrors the JSON shapes returned by the backend API.
library;

const fakeUser = {
  'id': 'user-001',
  'username': 'testuser',
  'display_name': 'Test User',
  'email': 'test@example.com',
  'role': 'platform_admin',
  'tenant_id': 'tenant-001',
  'avatar_url': '',
  'created_at': '2025-01-01T00:00:00Z',
};

const fakeTenant = {
  'id': 'tenant-001',
  'name': 'Test Company',
  'owner_id': 'user-001',
};

const fakeAgent = {
  'id': 'agent-001',
  'name': 'Assistant',
  'role': 'AI 助手',
  'role_description': '帮你处理日常事务',
  'status': 'running',
  'personality': 'friendly',
  'system_prompt': 'You are a helpful assistant.',
  'primary_model_id': 'model-001',
  'fallback_model_id': null,
  'created_at': '2025-01-01T00:00:00Z',
  'updated_at': '2025-06-01T00:00:00Z',
  'last_active_at': '2025-06-01T12:00:00Z',
  'tokens_used_today': 1234,
  'max_tokens_per_day': 10000,
  'tenant_id': 'tenant-001',
};

const fakeAgent2 = {
  'id': 'agent-002',
  'name': 'Researcher',
  'role': '研究员',
  'role_description': '负责资料收集与分析',
  'status': 'idle',
  'personality': 'analytical',
  'system_prompt': 'You are a research analyst.',
  'primary_model_id': 'model-001',
  'fallback_model_id': null,
  'created_at': '2025-02-01T00:00:00Z',
  'updated_at': '2025-05-15T00:00:00Z',
  'last_active_at': '2025-05-15T10:00:00Z',
  'tokens_used_today': 500,
  'max_tokens_per_day': 5000,
  'tenant_id': 'tenant-001',
};

const fakeModel = {
  'id': 'model-001',
  'provider': 'openai',
  'model': 'gpt-4o',
  'label': 'GPT-4o',
  'is_default': true,
};

const fakeTask = {
  'id': 'task-001',
  'agent_id': 'agent-001',
  'title': '写周报',
  'description': '总结本周工作',
  'status': 'pending',
  'type': 'one_time',
  'created_at': '2025-06-01T00:00:00Z',
};

const fakeSession = {
  'id': 'session-001',
  'agent_id': 'agent-001',
  'title': 'Default Session',
  'created_at': '2025-06-01T00:00:00Z',
};

const fakeMessage = {
  'id': 'msg-001',
  'session_id': 'session-001',
  'role': 'user',
  'content': 'Hello!',
  'created_at': '2025-06-01T12:00:00Z',
};

const fakeAssistantMessage = {
  'id': 'msg-002',
  'session_id': 'session-001',
  'role': 'assistant',
  'content': 'Hi! How can I help?',
  'created_at': '2025-06-01T12:00:01Z',
};

const fakeInboxMessage = {
  'id': 'inbox-001',
  'sender_name': 'Assistant',
  'receiver_name': 'Test User',
  'content': '任务已完成',
  'msg_type': 'notify',
  'read_at': null,
  'created_at': '2025-06-01T12:00:00Z',
};

const fakeInboxMessageRead = {
  'id': 'inbox-002',
  'sender_name': 'Researcher',
  'receiver_name': 'Test User',
  'content': '报告已生成',
  'msg_type': 'text',
  'read_at': '2025-06-01T13:00:00Z',
  'created_at': '2025-06-01T11:00:00Z',
};

const fakePlazaPost = {
  'id': 'post-001',
  'author_name': 'Test User',
  'author_avatar': '',
  'content': 'Hello plaza! **bold text** and `code`',
  'likes': 3,
  'comments': [],
  'liked_by': [],
  'created_at': '2025-06-01T00:00:00Z',
};

const fakeActivity = {
  'id': 'act-001',
  'summary': '完成了一个任务',
  'type': 'task_completed',
  'created_at': '2025-06-01T12:00:00Z',
};

const fakeInvitationCode = {
  'id': 'inv-001',
  'code': 'ABCDEF',
  'max_uses': 10,
  'used_count': 3,
  'is_active': true,
  'created_at': '2025-06-01T00:00:00Z',
};

const fakeTool = {
  'id': 'tool-001',
  'name': 'web_search',
  'display_name': '网页搜索',
  'description': '搜索互联网内容',
  'enabled': true,
};

const fakeSkill = {
  'id': 'skill-001',
  'name': 'writing',
  'display_name': '写作技能',
  'description': '帮助撰写各类文档',
};

const fakeTemplate = {
  'id': 'tpl-001',
  'name': '通用助手',
  'description': '一个通用的 AI 助手',
  'role': 'AI 助手',
  'personality': 'friendly',
  'icon': '🤖',
};

const fakeTemplate2 = {
  'id': 'tpl-002',
  'name': '研究分析师',
  'description': '帮你做调研',
  'role': '研究员',
  'personality': 'analytical',
  'icon': '🔬',
};

const fakeMetrics = {
  'tokens_today': 1234,
  'tokens_month': 50000,
  'tasks_total': 10,
  'tasks_completed': 8,
  'tasks_pending': 2,
  'uptime_hours': 720,
};

const fakeChannel = {
  'id': 'channel-001',
  'agent_id': 'agent-001',
  'type': 'web',
  'enabled': true,
};
