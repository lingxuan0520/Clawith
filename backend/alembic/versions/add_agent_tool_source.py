"""Add source and installed_by_agent_id to agent_tools

Revision ID: add_agent_tool_source
Revises: add_quota_fields
Create Date: 2026-03-06
"""
from alembic import op
import sqlalchemy as sa

revision = "add_agent_tool_source"
down_revision = "add_quota_fields"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("agent_tools", sa.Column("source", sa.String(20), nullable=False, server_default="system"))
    op.add_column("agent_tools", sa.Column("installed_by_agent_id", sa.UUID(), nullable=True))


def downgrade() -> None:
    op.drop_column("agent_tools", "installed_by_agent_id")
    op.drop_column("agent_tools", "source")
