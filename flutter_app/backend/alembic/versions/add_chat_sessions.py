"""Add chat_sessions table and update existing chat_messages conversation_ids."""

import uuid
import sqlalchemy as sa
from alembic import op

revision = "add_chat_sessions"
down_revision = "add_agent_tool_source"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create chat_sessions table
    op.create_table(
        "chat_sessions",
        sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("agent_id", sa.dialects.postgresql.UUID(as_uuid=True), sa.ForeignKey("agents.id"), nullable=False, index=True),
        sa.Column("user_id", sa.dialects.postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("title", sa.String(200), nullable=False, server_default="New Session"),
        sa.Column("source_channel", sa.String(20), nullable=False, server_default="web"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), index=True),
        sa.Column("last_message_at", sa.DateTime(timezone=True), nullable=True),
    )

    # For existing installs where chat_sessions already exists (without source_channel)
    conn = op.get_bind()
    try:
        conn.execute(sa.text(
            "ALTER TABLE chat_sessions ADD COLUMN IF NOT EXISTS source_channel VARCHAR(20) NOT NULL DEFAULT 'web'"
        ))
    except Exception:
        pass  # Table didn't exist yet (handled by create_table above)

    # Migrate existing messages: for each unique (agent_id, user_id, old_conv_id) combo,
    # create a chat_session and update conversation_id on messages.
    conn = op.get_bind()

    # Get all distinct (agent_id, user_id, conversation_id) from existing chat_messages
    rows = conn.execute(
        sa.text("SELECT DISTINCT agent_id, user_id, conversation_id FROM chat_messages")
    ).fetchall()

    for row in rows:
        agent_id, user_id, old_conv_id = row
        new_session_id = str(uuid.uuid4())
        # Determine created_at from earliest message in this conversation
        first_msg = conn.execute(
            sa.text(
                "SELECT MIN(created_at), MAX(created_at) FROM chat_messages "
                "WHERE agent_id = :a AND user_id = :u AND conversation_id = :c"
            ),
            {"a": str(agent_id), "u": str(user_id), "c": old_conv_id},
        ).fetchone()
        created_at = first_msg[0]
        last_msg_at = first_msg[1]

        # Derive a title from old conversation_id
        title = "Imported conversation"

        conn.execute(
            sa.text(
                "INSERT INTO chat_sessions (id, agent_id, user_id, title, created_at, last_message_at) "
                "VALUES (:id, :agent_id, :user_id, :title, :created_at, :last_msg_at)"
            ),
            {
                "id": new_session_id,
                "agent_id": str(agent_id),
                "user_id": str(user_id),
                "title": title,
                "created_at": created_at,
                "last_msg_at": last_msg_at,
            },
        )
        # Update messages to use new session UUID
        conn.execute(
            sa.text(
                "UPDATE chat_messages SET conversation_id = :new_id "
                "WHERE agent_id = :a AND user_id = :u AND conversation_id = :c"
            ),
            {"new_id": new_session_id, "a": str(agent_id), "u": str(user_id), "c": old_conv_id},
        )


def downgrade() -> None:
    op.drop_table("chat_sessions")
