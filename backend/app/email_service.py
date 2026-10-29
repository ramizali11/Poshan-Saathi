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

    plain_text = f"""
Hello {recipient_name},

Your PoshanSaathi verification code is: {otp}

This code will expire in 5 minutes (300 seconds).

Never share this code with anyone. If you did not make this request, please ignore this email.

PoshanSaathi - Maternal & Child Nutrition Care
    """

    try:
        import resend
        resend.api_key = api_key
        params = {
            "from": from_email,
            "to": [to_email],
            "subject": subject,
            "html": html_content,
            "text": plain_text,
        }
        res = resend.Emails.send(params)
        logger.info(f"✅ [EMAIL SUCCESS]: Resend sent verification email to {to_email}.")
        return True, None
    except Exception as e:
        logger.warning(f"⚠️ [EMAIL FALLBACK]: Resend SDK failed: {e}. Attempting direct HTTP fallback...")

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
                        "text": plain_text,
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


def send_password_reset_email(to_email: str, recipient_name: str, reset_url: str) -> Tuple[bool, str | None]:
    """
    Sends a secure password reset link email via the Resend API.
    
    Args:
        to_email: Destination email address
        recipient_name: Name of the caregiver
        reset_url: Secure URL containing single-use token (expires in 15 minutes)
        
    Returns:
        (success: bool, error_message: str | None)
    """
    api_key = os.getenv("RESEND_API_KEY", "").strip()
    from_email = os.getenv("RESEND_FROM_EMAIL", "PoshanSaathi <onboarding@resend.dev>").strip()

    if not api_key:
        err_msg = "RESEND_API_KEY environment variable is not configured."
        logger.warning(f"⚠️ [EMAIL ERROR]: {err_msg} - Password reset requested for {to_email}")
        return False, err_msg

    subject = "Reset Your PoshanSaathi Password"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reset Your Password</title>
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
        .btn-container {{
          text-align: center;
          margin: 32px 0;
        }}
        .btn {{
          display: inline-block;
          background-color: #2b6cb0;
          color: #ffffff !important;
          font-weight: 700;
          font-size: 16px;
          padding: 14px 32px;
          text-decoration: none;
          border-radius: 10px;
          letter-spacing: 0.5px;
        }}
        .btn:hover {{
          background-color: #2c5282;
        }}
        .timer-warning {{
          font-size: 13px;
          color: #c53030;
          text-align: center;
          margin-top: 10px;
          font-weight: 600;
        }}
        .fallback-box {{
          background-color: #f7fafc;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 12px;
          margin-top: 24px;
          word-break: break-all;
          font-size: 12px;
          color: #4a5568;
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

        <p style="font-size: 14px; line-height: 1.6; color: #4a5568;">
          We received a request to reset the password for your PoshanSaathi caregiver account. Click the button below to choose a new password:
        </p>

        <div class="btn-container">
          <a href="{reset_url}" class="btn" target="_blank">Reset Password</a>
          <div class="timer-warning">⏱️ This link is single-use and expires in 15 minutes</div>
        </div>

        <div class="fallback-box">
          <strong>Button not working?</strong> Copy and paste this link into your web browser:<br>
          <a href="{reset_url}" style="color: #2b6cb0;">{reset_url}</a>
        </div>

        <div class="security-notice">
          <strong>🔒 Security Notice:</strong> If you did not request a password reset, you can safely ignore this email. Your existing password will remain unchanged and your account is secure.
        </div>

        <div class="footer">
          &copy; 2026 PoshanSaathi • Empowering Healthy Futures for Every Child
        </div>
      </div>
    </body>
    </html>
    """

    plain_text = f"""
Hello {recipient_name},

We received a request to reset your PoshanSaathi password.
Please use the following single-use link to reset your password (valid for 15 minutes):

{reset_url}

If you did not request a password reset, you can safely ignore this email. Your account remains secure.

PoshanSaathi - Maternal & Child Nutrition Care
    """

    try:
        import resend
        resend.api_key = api_key
        params = {
            "from": from_email,
            "to": [to_email],
            "subject": subject,
            "html": html_content,
            "text": plain_text,
        }
        res = resend.Emails.send(params)
        logger.info(f"✅ [RESET EMAIL SUCCESS]: Password reset email dispatched to {to_email}.")
        return True, None
    except Exception as e:
        logger.warning(f"⚠️ [EMAIL FALLBACK]: Resend SDK failed: {e}. Attempting direct HTTP fallback...")

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
                        "text": plain_text,
                    },
                )
                if response.status_code in (200, 201):
                    logger.info(f"✅ [RESET EMAIL SUCCESS]: Direct HTTP Resend sent password reset email to {to_email}.")
                    return True, None
                else:
                    err = f"Resend API returned {response.status_code}: {response.text}"
                    logger.error(f"❌ [EMAIL FAILURE]: {err}")
                    return False, err
        except Exception as http_err:
            logger.error(f"❌ [EMAIL EXCEPTION]: Direct HTTP call also failed: {http_err}")
            return False, str(http_err)
