import os
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any
import httpx
from .database import get_db

logger = logging.getLogger("poshan_saathi.ai")

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
    """Constructs the comprehensive system instruction for child nutrition safety and personalization."""
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
        f"Parent / Caregiver Name: {context.get('parent_name', 'Caregiver')}",
    ]

    if context.get("has_child"):
        prompt_lines.extend([
            f"Active Child Name: {context.get('child_name')}",
            f"Child Gender: {context.get('child_gender')}",
            f"Child Age: {context.get('child_age')}",
            f"Latest Weight: {context.get('weight_display')}",
            f"Latest Height: {context.get('height_display')}",
        ])
        if context.get("recent_growth"):
            prompt_lines.append(f"Recent Height Growth: {context.get('recent_growth')}")
        prompt_lines.append(
            f"Personalization Instruction: Address {context.get('child_name')} by name warmly and tailor all meal suggestions, textures, and nutrient densities specifically for their age ({context.get('child_age')})."
        )
    else:
        prompt_lines.append("Active Child: No specific child selected yet. Provide general child nutrition guidance.")

    prompt_lines.extend([
        "",
        "--- TONE & FORMATTING ---",
        "- Keep answers conversational, positive, and concise (typically 2-4 easy paragraphs or structured bullet points).",
        "- Suggest accessible local ingredients such as moong dal, ragi, bajra, broken wheat (dalia), rice, curd, desi cow ghee, carrots, bottle gourd (doodhi), spinach, bananas, and papaya.",
        "- Avoid intimidating medical jargon. Make mothers and fathers feel supported, confident, and calm.",
    ])

    return "\n".join(prompt_lines)

async def generate_ai_chat_response(
    conversation_history: List[Dict[str, str]],
    user_id: int,
    child_id: Optional[int] = None
) -> str:
    """
    Calls OpenRouter Chat Completions API with the full system prompt and recent conversation history.
    Handles rate limits, network timeouts, and model errors gracefully.
    """
    api_key = os.getenv("OPENROUTER_API_KEY", "").strip()
    model = os.getenv("OPENROUTER_MODEL", "openrouter/free").strip()
    base_url = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1").rstrip("/")

    if not api_key:
        logger.error("[AI Service] OPENROUTER_API_KEY is missing from environment configuration.")
        return "I apologize, but the AI service is currently not configured with an API key. Please check the backend configuration."

    context = get_child_and_parent_context(user_id=user_id, child_id=child_id)
    system_prompt = build_system_prompt(context)

    # Keep conversation history concise: limit to last 10 messages (5 user-assistant turns)
    trimmed_history = conversation_history[-10:] if len(conversation_history) > 10 else conversation_history

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
        "max_tokens": 800,
        "temperature": 0.7,
    }

    try:
        async with httpx.AsyncClient(timeout=45.0) as client:
            logger.info(f"[AI Service] Sending request to OpenRouter ({model}) with {len(messages)} messages...")
            response = await client.post(
                f"{base_url}/chat/completions",
                headers=headers,
                json=payload
            )

            if response.status_code == 200:
                data = response.json()
                choices = data.get("choices", [])
                if choices and "message" in choices[0]:
                    reply = choices[0]["message"].get("content", "").strip()
                    if reply:
                        return reply

                return "I received your question, but could not produce a response at this moment. Please try asking again."

            elif response.status_code == 429:
                logger.warning(f"[AI Service] OpenRouter rate limit (429): {response.text}")
                return "The nutrition assistant is currently receiving many questions. Please wait a moment and try again."

            elif response.status_code in (502, 503, 504):
                logger.warning(f"[AI Service] OpenRouter server error ({response.status_code}): {response.text}")
                return "The AI service is temporarily unavailable. Please tap retry in a moment."

            else:
                logger.error(f"[AI Service] OpenRouter error HTTP {response.status_code}: {response.text}")
                return f"I encountered an issue connecting to the nutrition advisory service (Error {response.status_code}). Please try again."

    except httpx.TimeoutException:
        logger.warning("[AI Service] OpenRouter request timed out.")
        return "The response took longer than expected to generate. Please check your internet connection and tap retry."

    except httpx.RequestError as e:
        logger.error(f"[AI Service] Network error calling OpenRouter: {e}")
        return "Could not reach the nutrition advisory server. Please check your internet connection and try again."

    except Exception as e:
        logger.error(f"[AI Service] Unexpected error: {e}")
        return "An unexpected issue occurred while processing your nutrition query. Please try again."
