import os
import logging
from pathlib import Path
from typing import Tuple
import dotenv

# Load environment variables if not already loaded
app_dir = Path(__file__).resolve().parent
dotenv.load_dotenv(app_dir / ".env")
dotenv.load_dotenv(app_dir.parent / ".env")
dotenv.load_dotenv(app_dir.parent.parent / ".env")

logger = logging.getLogger("poshan_saathi.email")

def send_otp_email(to_email: str, recipient_name: str, otp: str) -> Tuple[bool, str | None]:
    """
    Sends a 6-digit OTP verification email via the Resend API.
    
    Args:
        to_email: Destination email address
        recipient_name: Name of the registered caregiver
        otp: 6-digit cryptographically secure OTP string
        
    Returns:
        (success: bool, error_message: str | None)
    """
    api_key = os.getenv("RESEND_API_KEY", "").strip()
    from_email = os.getenv("RESEND_FROM_EMAIL", "PoshanSaathi <onboarding@resend.dev>").strip()

    if not api_key:
        err_msg = "RESEND_API_KEY environment variable is not configured."
        logger.warning(f"⚠️ [EMAIL ERROR]: {err_msg} - OTP for {to_email} was: {otp}")
        return False, err_msg

    subject = f"Your PoshanSaathi Verification Code: {otp}"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>PoshanSaathi Email Verification</title>
      <style>
        body {{
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          background-color: #f7fafc;
          margin: 0;
          padding: 20px;
          color: #2d3748;
        }}
        .container {{
          max-width: 560px;
          margin: 0 auto;
          background-color: #ffffff;
          border-radius: 16px;
          padding: 32px;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
          border: 1px solid #e2e8f0;
        }}
        .header {{
          text-align: center;
          border-bottom: 1px solid #edf2f7;
          padding-bottom: 20px;
          margin-bottom: 24px;
        }}
        .app-name {{
          font-size: 24px;
          font-weight: 800;
          color: #2b6cb0;
          margin: 0;
        }}
        .tagline {{
          font-size: 13px;
          color: #718096;
          margin-top: 4px;
        }}
        .greeting {{
          font-size: 16px;
          margin-bottom: 12px;
          color: #1a202c;
        }}
        .otp-box {{
          background: #ebf8ff;
          border: 2px dashed #3182ce;
          border-radius: 12px;
          padding: 20px;
          text-align: center;
          margin: 28px 0;
        }}
        .otp-code {{
          font-size: 36px;
          font-weight: 900;
          letter-spacing: 8px;
          color: #2b6cb0;
          font-family: 'Courier New', Courier, monospace;
        }}
        .timer-warning {{
          font-size: 13px;
          color: #c53030;
          margin-top: 8px;
          font-weight: 600;
        }}
        .security-notice {{
          font-size: 12px;
          color: #718096;
          line-height: 1.6;
          margin-top: 24px;
          padding-top: 16px;
          border-top: 1px solid #edf2f7;
        }}
        .footer {{
          text-align: center;
          margin-top: 24px;
          font-size: 12px;
          color: #a0aec0;
        }}
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1 class="app-name">🌱 PoshanSaathi (પોષણ સાથી)</h1>
          <div class="tagline">Maternal & Child Nutrition Platform • Complementary Feeding Guidance</div>
        </div>

        <div class="greeting">
          <strong>Hello {recipient_name},</strong>
        </div>

        <p style="font-size: 14px; line-height: 1.5; color: #4a5568;">
          Welcome to PoshanSaathi! Please use the 6-digit verification code below to verify your email address and activate your caregiver account:
        </p>

        <div class="otp-box">
          <div class="otp-code">{otp}</div>
          <div class="timer-warning">⏱️ Expires in 5 minutes (300 seconds)</div>
        </div>

        <p style="font-size: 13px; color: #4a5568;">
          If you did not attempt to register or sign in on PoshanSaathi, you can safely ignore this email.
        </p>

        <div class="security-notice">
          <strong>🔒 Security Reminder:</strong> Never share this verification OTP with anyone, including healthcare volunteers or Anganwadi workers. PoshanSaathi staff will never ask for your code.
        </div>

        <div class="footer">
          &copy; 2026 PoshanSaathi • Empowering Healthy Futures for Every Child
        </div>
      </div>
    </body>
    </html>
    """

    try:
        # First attempt using the official resend package
        import resend
        resend.api_key = api_key
        params = {
            "from": from_email,
            "to": [to_email],
            "subject": subject,
            "html": html_content,
        }
        res = resend.Emails.send(params)
        logger.info(f"✅ [EMAIL SUCCESS]: Resend sent verification email to {to_email}. Response: {res}")
        return True, None
    except Exception as e:
        logger.warning(f"⚠️ [EMAIL FALLBACK]: Resend SDK failed: {e}. Attempting direct HTTP fallback...")

        # Fallback to direct HTTP request with httpx
        try:
            import httpx
            with httpx.Client(timeout=10.0) as client:
                response = client.post(
                    "https://api.resend.com/emails",
                    headers={
                        "Authorization": f"Bearer {api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "from": from_email,
                        "to": [to_email],
                        "subject": subject,
                        "html": html_content,
                    },
                )
                if response.status_code in (200, 201):
                    logger.info(f"✅ [EMAIL SUCCESS]: Direct HTTP Resend sent verification email to {to_email}.")
                    return True, None
                else:
                    err = f"Resend API returned {response.status_code}: {response.text}"
                    logger.error(f"❌ [EMAIL FAILURE]: {err}")
                    return False, err
        except Exception as http_err:
            logger.error(f"❌ [EMAIL EXCEPTION]: Direct HTTP call also failed: {http_err}")
            return False, str(http_err)
