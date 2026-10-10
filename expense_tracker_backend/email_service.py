
import os
import smtplib
from dotenv import load_dotenv
from email.message import EmailMessage

# Load environment variables from .env
load_dotenv()


def send_monthly_report_email(
    recipient_email,
    user_name,
    month_name,
    year,
    total_income,
    total_expenses,
    category_totals,
):
    sender_email = os.getenv("SMTP_EMAIL")
    app_password = os.getenv("SMTP_APP_PASSWORD")

    if not sender_email or not app_password:
        raise RuntimeError(
            "SMTP_EMAIL or SMTP_APP_PASSWORD is missing in .env"
        )

    # Calculate remaining balance
    balance = total_income - total_expenses

    # Prepare category-wise expense details
    if category_totals:
        category_text = "\n".join(
            f"{category}: Rs. {float(amount):,.2f}"
            for category, amount in category_totals.items()
        )
    else:
        category_text = "No expenses recorded."

    # Create email
    message = EmailMessage()
    message["Subject"] = (
        f"Savingy Monthly Report - {month_name} {year}"
    )
    message["From"] = sender_email
    message["To"] = recipient_email

    message.set_content(
        f"""Hello {user_name},

Here is your Savingy monthly expense report
for {month_name} {year}.

Total income: Rs. {total_income:,.2f}
Total expenses: Rs. {total_expenses:,.2f}
Remaining balance: Rs. {balance:,.2f}

Expenses by category:
{category_text}

Thank you for using Savingy!

Regards,
Savingy Expense Tracker
"""
    )

    # Send email using Gmail SMTP
    try:
        with smtplib.SMTP(
            "smtp.gmail.com", 587, timeout=30
        ) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(sender_email, app_password)
            server.send_message(message)

    except (smtplib.SMTPException, OSError) as error:
        print("SMTP ERROR:", repr(error))
        raise RuntimeError(
            "Email could not be sent. Check SMTP credentials "
            "and Gmail SMTP connectivity."
        ) from error
