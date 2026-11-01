import logging
from datetime import datetime, timezone
from typing import Optional, List
from fastapi import APIRouter, Header, HTTPException, status
from ..database import get_db
from ..security import verify_token
from ..schemas import (
    ChatSendMessageRequest,
    ChatSendMessageResponse,
    ChatNewConversationRequest,
    ChatConversationSummary,
    ChatConversationDetail,
    ChatMessageResponse,
    GenericMessageResponse,
)
from ..ai_service import generate_ai_chat_response

logger = logging.getLogger("poshan_saathi.chat")

router = APIRouter(prefix="/chat", tags=["AI Chatbot"])

def get_authenticated_user_id(authorization: Optional[str]) -> int:
    """Helper to extract and validate the authenticated user ID from Authorization header."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed authorization token. Bearer token required.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = authorization.split(" ")[1].strip()
    payload = verify_token(token)
    if not payload or not payload.get("uid"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session expired or invalid token. Please log in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return int(payload["uid"])

@router.post("/send", response_model=ChatSendMessageResponse)
async def send_chat_message(
    req: ChatSendMessageRequest,
    authorization: Optional[str] = Header(None)
):
    """
    Sends a message to the PoshanSaathi Child Nutrition AI chatbot.
    - Persists user message and AI response in SQLite.
    - Personalizes recommendations using the selected child's verified profile & measurements.
    - Enforces clinical safety instructions (no honey < 12m, choking hazard precautions).
    """
    user_id = get_authenticated_user_id(authorization)

    user_text = req.message.strip()
    if not user_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message content cannot be empty."
        )

    now_str = datetime.now(timezone.utc).isoformat()
    conversation_id = req.conversation_id
    child_id = req.child_id

    with get_db() as conn:
        cursor = conn.cursor()

        # If child_id supplied, verify ownership
        if child_id is not None:
            cursor.execute("SELECT id FROM children WHERE id = ? AND parent_id = ?", (child_id, user_id))
            if not cursor.fetchone():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Child profile not found or does not belong to the authenticated user."
                )

        # Retrieve or create conversation
        if conversation_id:
            cursor.execute(
                "SELECT id, user_id, child_id, title FROM chat_conversations WHERE id = ? AND user_id = ?",
                (conversation_id, user_id)
            )
            conv_row = cursor.fetchone()
            if not conv_row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Conversation not found or unauthorized."
                )

            # If user explicitly changed active child, update conversation's child association
            if child_id is not None and conv_row["child_id"] != child_id:
                cursor.execute(
                    "UPDATE chat_conversations SET child_id = ?, updated_at = ? WHERE id = ?",
                    (child_id, now_str, conversation_id)
                )
            elif child_id is None and conv_row["child_id"] is not None:
                child_id = conv_row["child_id"]
        else:
            # Generate short title from first question (max 40 chars)
            title = user_text[:40].strip()
            if len(user_text) > 40:
                title += "..."

            cursor.execute("""
                INSERT INTO chat_conversations (user_id, child_id, title, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?)
            """, (user_id, child_id, title, now_str, now_str))
            conversation_id = cursor.lastrowid

        # Insert user message
        cursor.execute("""
            INSERT INTO chat_messages (conversation_id, sender_role, content, created_at)
            VALUES (?, 'user', ?, ?)
        """, (conversation_id, user_text, now_str))
        user_message_id = cursor.lastrowid

        # Fetch recent messages for prompt history
        cursor.execute("""
            SELECT sender_role, content FROM chat_messages 
            WHERE conversation_id = ? 
            ORDER BY id ASC
        """, (conversation_id,))
        rows = cursor.fetchall()
        history = [{"role": r["sender_role"], "content": r["content"]} for r in rows]

        conn.commit()

    # Generate AI response via OpenRouter asynchronously
    reply_text = await generate_ai_chat_response(
        conversation_history=history,
        user_id=user_id,
        child_id=child_id
    )

    reply_now_str = datetime.now(timezone.utc).isoformat()

    with get_db() as conn:
        cursor = conn.cursor()

        # Insert assistant message
        cursor.execute("""
            INSERT INTO chat_messages (conversation_id, sender_role, content, created_at)
            VALUES (?, 'assistant', ?, ?)
        """, (conversation_id, reply_text, reply_now_str))
        assistant_message_id = cursor.lastrowid

        # Update conversation timestamp
        cursor.execute(
            "UPDATE chat_conversations SET updated_at = ? WHERE id = ?",
            (reply_now_str, conversation_id)
        )

        child_name = None
        if child_id:
            cursor.execute("SELECT name FROM children WHERE id = ?", (child_id,))
            c_row = cursor.fetchone()
            if c_row:
                child_name = c_row["name"]

        conn.commit()

    return ChatSendMessageResponse(
        conversation_id=conversation_id,
        message_id=assistant_message_id,
        reply=reply_text,
        created_at=reply_now_str,
        child_id=child_id,
        child_name=child_name,
    )

@router.post("/new", response_model=ChatConversationSummary)
def create_new_conversation(
    req: ChatNewConversationRequest,
    authorization: Optional[str] = Header(None)
):
    """Creates a new empty chat conversation session for the authenticated parent."""
    user_id = get_authenticated_user_id(authorization)
    now_str = datetime.now(timezone.utc).isoformat()

    child_name = None
    with get_db() as conn:
        cursor = conn.cursor()

        if req.child_id:
            cursor.execute("SELECT name FROM children WHERE id = ? AND parent_id = ?", (req.child_id, user_id))
            c_row = cursor.fetchone()
            if not c_row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Child profile not found or does not belong to user."
                )
            child_name = c_row["name"]

        title = req.title.strip() if req.title else "Nutrition Advice"

        cursor.execute("""
            INSERT INTO chat_conversations (user_id, child_id, title, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?)
        """, (user_id, req.child_id, title, now_str, now_str))
        new_id = cursor.lastrowid
        conn.commit()

        return ChatConversationSummary(
            id=new_id,
            title=title,
            child_id=req.child_id,
            child_name=child_name,
            last_message=None,
            created_at=now_str,
            updated_at=now_str,
        )

@router.get("/history", response_model=List[ChatConversationSummary])
def get_chat_history(
    authorization: Optional[str] = Header(None)
):
    """Lists all saved chat conversations for the authenticated parent, sorted by most recent."""
    user_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT c.id, c.title, c.child_id, c.created_at, c.updated_at, ch.name AS child_name
            FROM chat_conversations c
            LEFT JOIN children ch ON c.child_id = ch.id
            WHERE c.user_id = ?
            ORDER BY c.updated_at DESC
        """, (user_id,))
        conv_rows = cursor.fetchall()

        results: List[ChatConversationSummary] = []
        for r in conv_rows:
            # Fetch last message snippet
            cursor.execute("""
                SELECT content FROM chat_messages 
                WHERE conversation_id = ? 
                ORDER BY id DESC LIMIT 1
            """, (r["id"],))
            last_msg_row = cursor.fetchone()
            snippet = last_msg_row["content"][:80] + ("..." if len(last_msg_row["content"]) > 80 else "") if last_msg_row else None

            results.append(ChatConversationSummary(
                id=r["id"],
                title=r["title"],
                child_id=r["child_id"],
                child_name=r["child_name"],
                last_message=snippet,
                created_at=r["created_at"],
                updated_at=r["updated_at"],
            ))

        return results

@router.get("/history/{conversation_id}", response_model=ChatConversationDetail)
def get_conversation_messages(
    conversation_id: int,
    authorization: Optional[str] = Header(None)
):
    """Retrieves full message history of a specific conversation."""
    user_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT c.id, c.title, c.child_id, c.created_at, c.updated_at, ch.name AS child_name
            FROM chat_conversations c
            LEFT JOIN children ch ON c.child_id = ch.id
            WHERE c.id = ? AND c.user_id = ?
        """, (conversation_id, user_id))
        conv_row = cursor.fetchone()
        if not conv_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found or unauthorized."
            )

        cursor.execute("""
            SELECT id, conversation_id, sender_role, content, created_at 
            FROM chat_messages 
            WHERE conversation_id = ? 
            ORDER BY id ASC
        """, (conversation_id,))
        msg_rows = cursor.fetchall()

        messages = [
            ChatMessageResponse(
                id=m["id"],
                conversation_id=m["conversation_id"],
                sender_role=m["sender_role"],
                content=m["content"],
                created_at=m["created_at"],
            )
            for m in msg_rows
        ]

        return ChatConversationDetail(
            id=conv_row["id"],
            title=conv_row["title"],
            child_id=conv_row["child_id"],
            child_name=conv_row["child_name"],
            created_at=conv_row["created_at"],
            updated_at=conv_row["updated_at"],
            messages=messages,
        )

@router.delete("/history/{conversation_id}", response_model=GenericMessageResponse)
def delete_conversation(
    conversation_id: int,
    authorization: Optional[str] = Header(None)
):
    """Deletes a chat conversation and all associated messages."""
    user_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id FROM chat_conversations WHERE id = ? AND user_id = ?",
            (conversation_id, user_id)
        )
        if not cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found or unauthorized."
            )

        cursor.execute("DELETE FROM chat_conversations WHERE id = ? AND user_id = ?", (conversation_id, user_id))
        conn.commit()

        return GenericMessageResponse(
            success=True,
            message="Conversation deleted successfully."
        )
