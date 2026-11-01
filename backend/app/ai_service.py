import os
import time
import json
import random
import asyncio
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any, AsyncGenerator
import httpx
from .database import get_db

logger = logging.getLogger("poshan_saathi.ai")

# Persistent shared HTTP client for connection pooling & TLS reuse across requests
_shared_client: Optional[httpx.AsyncClient] = None

def get_ai_http_client() -> httpx.AsyncClient:
    """Returns a pooled, persistent httpx.AsyncClient with keepalive connection reuse."""
    global _shared_client
    if _shared_client is None or _shared_client.is_closed:
        _shared_client = httpx.AsyncClient(
            timeout=httpx.Timeout(45.0, connect=10.0),
            limits=httpx.Limits(
                max_keepalive_connections=20,
                max_connections=50,
                keepalive_expiry=60.0,
            ),
        )
    return _shared_client

async def close_ai_http_client():
    """Cleanly closes the pooled HTTP client on application lifespan shutdown."""
    global _shared_client
    if _shared_client is not None and not _shared_client.is_closed:
        await _shared_client.aclose()
        _shared_client = None

def _calculate_age_str(dob_str: str) -> str:
    """Calculates human-readable age string and months from ISO DOB."""
    try:
        birth_date = datetime.strptime(dob_str, "%Y-%m-%d").date()
        today = datetime.now().date()
        years = today.year - birth_date.year
        months = today.month - birth_date.month
        days = today.day - birth_date.day

        if days < 0:
            months -= 1
        if months < 0:
            years -= 1
            months += 12

        if years > 0:
            return f"{years} yr {months} mo ({years * 12 + months} months)"
        elif months > 0:
            return f"{months} month{'s' if months > 1 else ''}"
        else:
            total_days = (today - birth_date).days
            return f"{total_days} days"
    except Exception:
        return "Unknown age"

def get_child_and_parent_context(user_id: int, child_id: Optional[int] = None) -> Dict[str, Any]:
    """
    Safely retrieves the authenticated caregiver and child context from SQLite.
    Never trusts child_id without verifying parent_id == user_id.
    """
    context: Dict[str, Any] = {
        "parent_name": "Caregiver",
        "has_child": False,
        "child_id": None,
        "child_name": None,
        "child_age": None,
        "child_gender": None,
        "weight_display": "Not recorded",
        "height_display": "Not recorded",
        "recent_growth": None,
    }

    with get_db() as conn:
        cursor = conn.cursor()

        # Fetch parent
        cursor.execute("SELECT name FROM users WHERE id = ?", (user_id,))
        user_row = cursor.fetchone()
        if user_row and user_row["name"]:
            context["parent_name"] = user_row["name"].strip()

        # Fetch child if child_id is provided, or default to parent's first child
        child_row = None
        if child_id:
            cursor.execute(
                "SELECT id, name, dob, weight, gender FROM children WHERE id = ? AND parent_id = ?",
                (child_id, user_id)
            )
            child_row = cursor.fetchone()
        else:
            cursor.execute(
                "SELECT id, name, dob, weight, gender FROM children WHERE parent_id = ? ORDER BY id ASC LIMIT 1",
                (user_id,)
            )
            child_row = cursor.fetchone()

        if child_row:
            c_id = child_row["id"]
            context["has_child"] = True
            context["child_id"] = c_id
            context["child_name"] = child_row["name"].strip()
            context["child_gender"] = child_row["gender"] or "Child"
            context["child_age"] = _calculate_age_str(child_row["dob"])

            if child_row["weight"] is not None and child_row["weight"] > 0:
                context["weight_display"] = f"{float(child_row['weight']):.1f} kg"

            # Fetch latest height from child_height_measurements
            cursor.execute("""
                SELECT height_cm, measurement_date 
                FROM child_height_measurements 
                WHERE child_id = ? AND parent_id = ? 
                ORDER BY measurement_date DESC, id DESC 
                LIMIT 2
            """, (c_id, user_id))
            height_rows = cursor.fetchall()
            if height_rows:
                latest_h = height_rows[0]
                context["height_display"] = f"{float(latest_h['height_cm']):.1f} cm (recorded {latest_h['measurement_date']})"
                if len(height_rows) >= 2:
                    prev_h = height_rows[1]
                    diff = round(latest_h["height_cm"] - prev_h["height_cm"], 1)
                    sign = "+" if diff > 0 else ""
                    context["recent_growth"] = f"{sign}{diff} cm since previous record on {prev_h['measurement_date']}"

    return context

def build_system_prompt(context: Dict[str, Any]) -> str:
    """
    Constructs the streamlined system instruction for child nutrition safety,
    personalization, and clean chat formatting (no excessive markdown headers).
    """
    parent_name = context.get("parent_name", "Caregiver")
    child_name = context.get("child_name")
    child_gender = context.get("child_gender", "Child")
    child_age = context.get("child_age", "early childhood")
    weight_disp = context.get("weight_display", "Not recorded")
    height_disp = context.get("height_display", "Not recorded")
    growth_disp = context.get("recent_growth")

    prompt_lines = [
        "You are PoshanSaathi AI, a warm, knowledgeable, and empathetic Child Nutrition Assistant specialized in infant, toddler, and early childhood nutrition (ages 0 to 6 years).",
        "Your mission is to guide Indian parents and caregivers with practical, culturally grounded, affordable, and evidence-based complementary feeding and dietary guidance adhering to ICMR-NIN (National Institute of Nutrition, India) and WHO Child Feeding Standards.",
        "",
        "--- CLINICAL SAFETY & ETHICAL RULES ---",
        "1. NOT A DOCTOR: You provide general nutritional and feeding education only. You do not diagnose pediatric diseases, prescribe medications, or recommend commercial supplements without doctor consultation.",
        "2. INFANT HONEY BAN: Strictly NEVER recommend honey or honey-containing preparations for infants under 12 months of age due to the risk of fatal Infant Botulism.",
        "3. CHOKING HAZARD AWARENESS: Always warn caregivers against choking hazards. Advise that whole nuts, raw carrots, whole grapes, or hard candies should never be given to babies/toddlers under 3 years without finely grinding, steaming soft, or slicing lengthwise into matchsticks.",
        "4. SAFE PREPARATION: Emphasize hygienic food preparation, handwashing, serving freshly cooked warm food, and not keeping toddler foods at room temperature for extended hours.",
        "5. TEXTURE PROGRESSION: Respect developmental chewing readiness (e.g., smooth mash at 6-8m, coarse fork-mashed solids at 8-12m, bite-sized soft finger foods for 12m+). Never force-feed.",
        "6. NO FABRICATED DATA: Never invent fake measurements, allergies, or diagnostic classifications. If certain child information is missing, acknowledge gently that recording it helps provide sharper advice.",
        "7. EMERGENCY ESCALATION: If the parent describes red-flag symptoms (severe dehydration, lethargy, persistent high fever, blood in stool, severe allergic reaction/anaphylaxis, sudden choking), instruct them immediately to seek urgent pediatric medical care.",
        "",
        "--- ACTIVE CONTEXT ---",
        f"Parent / Caregiver Name: {parent_name}",
    ]

    if context.get("has_child") and child_name:
        prompt_lines.extend([
            f"Active Child Name: {child_name}",
            f"Child Gender: {child_gender}",
            f"Child Age: {child_age}",
            f"Latest Weight: {weight_disp}",
            f"Latest Height: {height_disp}",
        ])
        if growth_disp:
            prompt_lines.append(f"Recent Height Growth: {growth_disp}")
        prompt_lines.append(
            f"Personalization Instruction: Address {child_name} by name warmly and tailor all meal suggestions, textures, and nutrient densities specifically for their age ({child_age})."
        )
    else:
        prompt_lines.append("Active Child: No specific child selected yet. Provide general child nutrition guidance.")

    prompt_lines.extend([
        "",
        "--- RESPONSE STYLE & CLEAN FORMATTING RULES ---",
        "- Start directly with the answer. Do not use filler openings like 'Certainly!', 'Sure, here is advice for...', or 'As an AI...'.",
        "- Write in short, conversational paragraphs (1-3 sentences each) that are easy for busy parents to read on a mobile phone.",
        "- Use bullet points ONLY for listing practical food items, ingredients, or actionable steps.",
        "- STRICTLY DO NOT USE MARKDOWN HEADINGS (#, ##, ###). Instead, use bold text like **Breakfast ideas:** or **Key tips:** for visual structure.",
        "- Recommend local, accessible Indian foods (moong dal, ragi, bajra, dalia, rice, curd, desi cow ghee, bottle gourd, spinach, carrots, bananas, papaya).",
        "- Avoid medical jargon. Keep the tone warm, reassuring, and practical.",
        "- Do not end with repetitive sign-off boilerplates (e.g., 'I hope this helps! Let me know if you have more questions.'). Keep endings natural.",
    ])

    return "\n".join(prompt_lines)

def _prepare_request_payload(
    conversation_history: List[Dict[str, str]],
    user_id: int,
    child_id: Optional[int] = None,
    stream: bool = False
) -> tuple[str, str, Dict[str, str], Dict[str, Any]]:
    """Builds the headers and JSON payload for OpenRouter API."""
    api_key = os.getenv("OPENROUTER_API_KEY", "").strip()
    model = os.getenv("OPENROUTER_MODEL", "openrouter/free").strip()
    base_url = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1").rstrip("/")

    context = get_child_and_parent_context(user_id=user_id, child_id=child_id)
    system_prompt = build_system_prompt(context)

    # Limit history to the last 8 messages (4 user-assistant turns) for speed & context efficiency
    trimmed_history = conversation_history[-8:] if len(conversation_history) > 8 else conversation_history

    messages = [{"role": "system", "content": system_prompt}]
    for msg in trimmed_history:
        role = msg.get("role") or msg.get("sender_role")
        content = msg.get("content", "")
        if role in ("user", "assistant") and content.strip():
            messages.append({"role": role, "content": content.strip()})

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://poshansaathi.app",
        "X-Title": "PoshanSaathi Child Nutrition Care",
    }

    payload = {
        "model": model,
        "messages": messages,
        "max_tokens": 700,
        "temperature": 0.65,
        "stream": stream,
    }

    return api_key, f"{base_url}/chat/completions", headers, payload

async def stream_ai_chat_response(
    conversation_history: List[Dict[str, str]],
    user_id: int,
    child_id: Optional[int] = None,
    max_retries: int = 2,
) -> AsyncGenerator[Dict[str, Any], None]:
    """
    Streams AI response tokens as Server-Sent Events from OpenRouter.
    Yields dicts with:
      {"type": "token", "delta": str}
      {"type": "error", "error": str}
      {"type": "done", "reply": str, "ttft_ms": int, "total_ms": int}
    Handles transient network glitches, 429 rate limits, and 5xx errors with exponential backoff.
    """
    api_key, url, headers, payload = _prepare_request_payload(
        conversation_history, user_id, child_id, stream=True
    )

    if not api_key:
        yield {
            "type": "error",
            "error": "The AI service is not configured with an API key. Please check the backend configuration."
        }
        return

    client = get_ai_http_client()
    overall_start = time.time()
    first_token_time: Optional[float] = None
    accumulated_reply: List[str] = []

    last_error_message = ""

    for attempt in range(max_retries + 1):
        try:
            req_start = time.time()
            logger.info(f"[AI Stream] Attempt {attempt + 1}/{max_retries + 1} connecting to OpenRouter ({payload['model']})...")

            async with client.stream("POST", url, headers=headers, json=payload, timeout=httpx.Timeout(35.0, connect=10.0)) as response:
                status_code = response.status_code

                if status_code == 200:
                    async for line in response.aiter_lines():
                        line = line.strip()
                        # Ignore SSE comment lines (e.g. ': OPENROUTER PROCESSING') and empty lines
                        if not line or line.startswith(":"):
                            continue

                        if line.startswith("data: "):
                            data_str = line[6:].strip()
                            if data_str == "[DONE]":
                                break

                            try:
                                chunk = json.loads(data_str)
                                choices = chunk.get("choices", [])
                                if choices:
                                    delta = choices[0].get("delta", {})
                                    content = delta.get("content")
                                    # Filter out chain-of-thought reasoning chunks where content is empty
                                    if content:
                                        if first_token_time is None:
                                            first_token_time = time.time()
                                            ttft_ms = round((first_token_time - overall_start) * 1000)
                                            logger.info(f"[AI Stream] TTFT (Time to First Token): {ttft_ms} ms")

                                        accumulated_reply.append(content)
                                        yield {"type": "token", "delta": content}
                            except json.JSONDecodeError:
                                continue

                    # If we received tokens, stream completed successfully
                    if accumulated_reply:
                        total_ms = round((time.time() - overall_start) * 1000)
                        ttft_ms = round((first_token_time - overall_start) * 1000) if first_token_time else total_ms
                        full_text = "".join(accumulated_reply).strip()
                        logger.info(f"[AI Stream] Stream completed in {total_ms} ms (TTFT: {ttft_ms} ms, Length: {len(full_text)} chars)")
                        yield {
                            "type": "done",
                            "reply": full_text,
                            "ttft_ms": ttft_ms,
                            "total_ms": total_ms
                        }
                        return
                    else:
                        # Empty response from model, attempt retry
                        last_error_message = "The nutrition assistant returned an empty response. Retrying..."
                        logger.warning("[AI Stream] Model returned 200 but zero content tokens.")

                elif status_code == 429:
                    retry_after = response.headers.get("Retry-After")
                    delay = min(int(retry_after), 3) if (retry_after and retry_after.isdigit()) else (1.0 + random.uniform(0.1, 0.4))
                    logger.warning(f"[AI Stream] Rate limited (429). Backing off {delay:.1f}s...")
                    last_error_message = "The nutrition assistant is currently receiving many questions. Please wait a moment and try again."
                    if attempt < max_retries:
                        await asyncio.sleep(delay)
                        continue

                elif status_code in (502, 503, 504):
                    delay = 1.0 * (2 ** attempt) + random.uniform(0.1, 0.3)
                    logger.warning(f"[AI Stream] Server error ({status_code}). Backing off {delay:.1f}s...")
                    last_error_message = "The AI service is temporarily busy. Please tap retry in a moment."
                    if attempt < max_retries:
                        await asyncio.sleep(delay)
                        continue

                elif status_code in (401, 403):
                    logger.error(f"[AI Stream] Auth error HTTP {status_code} from OpenRouter.")
                    yield {
                        "type": "error",
                        "error": "Authentication error with the AI service. Please check your configuration."
                    }
                    return

                else:
                    body = await response.aread()
                    logger.error(f"[AI Stream] OpenRouter HTTP {status_code}: {body.decode('utf-8', errors='ignore')}")
                    last_error_message = f"Unable to generate response (Error {status_code})."

        except (httpx.TimeoutException, httpx.NetworkError) as e:
            delay = 0.8 * (2 ** attempt) + random.uniform(0.1, 0.3)
            logger.warning(f"[AI Stream] Network/Timeout error on attempt {attempt + 1}: {e}")
            last_error_message = "Network timeout reaching nutrition service. Please check your internet connection."
            if attempt < max_retries:
                await asyncio.sleep(delay)
                continue

    # If stream produced some partial tokens before breaking, preserve them
    if accumulated_reply:
        full_text = "".join(accumulated_reply).strip()
        total_ms = round((time.time() - overall_start) * 1000)
        yield {
            "type": "done",
            "reply": full_text,
            "ttft_ms": total_ms,
            "total_ms": total_ms
        }
    else:
        yield {
            "type": "error",
            "error": last_error_message or "The nutrition assistant could not respond right now. Please tap retry."
        }

async def generate_ai_chat_response(
    conversation_history: List[Dict[str, str]],
    user_id: int,
    child_id: Optional[int] = None,
    max_retries: int = 2,
) -> str:
    """
    Standard non-streaming completion using the pooled HTTP client with retry logic.
    Used as a fallback for non-streaming clients and unit test suites.
    """
    api_key, url, headers, payload = _prepare_request_payload(
        conversation_history, user_id, child_id, stream=False
    )

    if not api_key:
        return "I apologize, but the AI service is currently not configured with an API key. Please check the backend configuration."

    client = get_ai_http_client()
    overall_start = time.time()

    for attempt in range(max_retries + 1):
        try:
            req_start = time.time()
            response = await client.post(url, headers=headers, json=payload, timeout=httpx.Timeout(35.0, connect=10.0))
            duration_ms = round((time.time() - req_start) * 1000)

            if response.status_code == 200:
                data = response.json()
                choices = data.get("choices", [])
                if choices and "message" in choices[0]:
                    reply = choices[0]["message"].get("content", "").strip()
                    if reply:
                        logger.info(f"[AI Sync] Completed in {duration_ms} ms (Attempt {attempt + 1})")
                        return reply

                if attempt < max_retries:
                    await asyncio.sleep(0.8)
                    continue
                return "I received your question, but could not produce a response at this moment. Please try asking again."

            elif response.status_code == 429:
                logger.warning(f"[AI Sync] OpenRouter rate limit (429). Attempt {attempt + 1}")
                if attempt < max_retries:
                    await asyncio.sleep(1.2 + random.uniform(0.1, 0.3))
                    continue
                return "The nutrition assistant is currently receiving many questions. Please wait a moment and try again."

            elif response.status_code in (502, 503, 504):
                logger.warning(f"[AI Sync] OpenRouter server error ({response.status_code}). Attempt {attempt + 1}")
                if attempt < max_retries:
                    await asyncio.sleep(1.0 * (2 ** attempt))
                    continue
                return "The AI service is temporarily unavailable. Please tap retry in a moment."

            elif response.status_code in (401, 403):
                return "Authentication error with AI service. Please check backend configuration."

            else:
                logger.error(f"[AI Sync] OpenRouter HTTP {response.status_code}: {response.text}")
                return f"I encountered an issue connecting to the nutrition advisory service (Error {response.status_code}). Please try again."

        except (httpx.TimeoutException, httpx.NetworkError) as e:
            logger.warning(f"[AI Sync] Network exception on attempt {attempt + 1}: {e}")
            if attempt < max_retries:
                await asyncio.sleep(0.8 * (2 ** attempt))
                continue
            return "The response took longer than expected to generate. Please check your internet connection and tap retry."

        except Exception as e:
            logger.error(f"[AI Sync] Unexpected error: {e}")
            return "An unexpected issue occurred while processing your nutrition query. Please try again."

    return "The nutrition assistant could not respond at this time. Please tap retry."
