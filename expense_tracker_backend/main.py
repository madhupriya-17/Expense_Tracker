
import os
import logging

from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Literal

from dotenv import load_dotenv

from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    Query,
    status,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from jose import jwt, JWTError
from pwdlib import PasswordHash

from pydantic import BaseModel, EmailStr, Field

from sqlalchemy import (
    Column,
    Integer,
    String,
    Numeric,
    DateTime,
    ForeignKey,
    text,
)
from sqlalchemy.orm import Session

from database import Base, engine, get_db
from email_service import send_monthly_report_email


# ============================================================
# CONFIGURATION
# ============================================================

load_dotenv()

logging.basicConfig(level=logging.INFO)

app = FastAPI(
    title="Savingy - Personal Expense Tracker API",
    description="API for user authentication and expense management",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

password_hash = PasswordHash.recommended()
security = HTTPBearer()


# ============================================================
# DATABASE MODELS
# These map to your existing MySQL tables.
# ============================================================

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)

    monthly_budget = Column(
        Numeric(12, 2),
        nullable=False,
        default=Decimal("10000.00"),
    )

    created_at = Column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )


class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    title = Column(String(100), nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    type = Column("type", String(10), nullable=False)
    category = Column(String(50), nullable=False)
    transaction_date = Column(DateTime, nullable=False)

    created_at = Column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )


# ============================================================
# REQUEST SCHEMAS
# ============================================================

class RegisterRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class ExpenseCreate(BaseModel):
    title: str = Field(min_length=1, max_length=100)
    amount: Decimal = Field(
        gt=0,
        max_digits=12,
        decimal_places=2,
    )
    type: Literal["expense", "income"]
    category: str = Field(min_length=1, max_length=50)
    transaction_date: datetime


class BudgetUpdate(BaseModel):
    monthly_budget: Decimal = Field(
        ge=0,
        max_digits=12,
        decimal_places=2,
    )


# ============================================================
# JWT TOKEN CREATION
# ============================================================

def create_access_token(user_id: int) -> str:
    if not JWT_SECRET_KEY:
        raise HTTPException(
            status_code=500,
            detail="JWT_SECRET_KEY is missing from .env",
        )

    expires_at = datetime.utcnow() + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    payload = {
        "sub": str(user_id),
        "exp": expires_at,
    }

    return jwt.encode(
        payload,
        JWT_SECRET_KEY,
        algorithm=JWT_ALGORITHM,
    )


# ============================================================
# AUTHENTICATED USER
# Define this BEFORE protected API endpoints.
# ============================================================

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    if not JWT_SECRET_KEY:
        raise HTTPException(
            status_code=500,
            detail="JWT_SECRET_KEY is not configured",
        )

    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET_KEY,
            algorithms=[JWT_ALGORITHM],
        )

        user_id = int(payload["sub"])

    except (JWTError, ValueError, KeyError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.query(User).filter(User.id == user_id).first()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    return user


# ============================================================
# HOME AND DATABASE CHECK
# ============================================================

@app.get("/")
def home():
    return {
        "message": "Welcome to Savingy Personal Expense Tracker API",
        "status": "running",
    }


@app.get("/db-check")
def database_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))

        return {
            "status": "success",
            "message": "Connected to expense_tracker MySQL database",
        }

    except Exception:
        logging.exception("Database connection failed")

        raise HTTPException(
            status_code=500,
            detail="Database connection failed",
        )


# ============================================================
# REGISTER
# POST /auth/register
# ============================================================

@app.post("/auth/register", status_code=status.HTTP_201_CREATED)
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db),
):
    name = data.name.strip()
    email = str(data.email).lower().strip()

    if not name:
        raise HTTPException(
            status_code=400,
            detail="Name cannot be empty",
        )

    existing_user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if existing_user:
        raise HTTPException(
            status_code=409,
            detail="Email is already registered",
        )

    user = User(
        name=name,
        email=email,
        password_hash=password_hash.hash(data.password),
        monthly_budget=Decimal("10000.00"),
    )

    try:
        db.add(user)
        db.commit()
        db.refresh(user)

    except Exception:
        db.rollback()
        logging.exception("Could not create account")

        raise HTTPException(
            status_code=500,
            detail="Could not create account",
        )

    return {
        "message": "Account created successfully",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
        },
    }


# ============================================================
# LOGIN
# POST /auth/login
# ============================================================

@app.post("/auth/login")
def login(
    data: LoginRequest,
    db: Session = Depends(get_db),
):
    email = str(data.email).lower().strip()

    user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if user is None or not password_hash.verify(
        data.password,
        user.password_hash,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    token = create_access_token(user.id)

    return {
        "message": "Login successful",
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
        },
    }


# ============================================================
# ADD EXPENSE OR INCOME
# POST /expenses
# ============================================================

@app.post("/expenses", status_code=status.HTTP_201_CREATED)
def add_expense(
    data: ExpenseCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    title = data.title.strip()
    category = data.category.strip()

    if not title:
        raise HTTPException(
            status_code=400,
            detail="Transaction title cannot be empty",
        )

    if not category:
        raise HTTPException(
            status_code=400,
            detail="Category cannot be empty",
        )

    transaction = Expense(
        user_id=user.id,
        title=title,
        amount=data.amount,
        type=data.type,
        category=category,
        transaction_date=data.transaction_date,
    )

    try:
        db.add(transaction)
        db.commit()
        db.refresh(transaction)

    except Exception:
        db.rollback()
        logging.exception("Could not save transaction")

        raise HTTPException(
            status_code=500,
            detail="Could not save transaction",
        )

    return {
        "message": "Transaction added successfully",
        "transaction": {
            "id": transaction.id,
            "title": transaction.title,
            "amount": float(transaction.amount),
            "type": transaction.type,
            "category": transaction.category,
            "transaction_date": transaction.transaction_date.isoformat(),
        },
    }


# ============================================================
# VIEW CURRENT USER'S EXPENSES AND INCOME
# GET /expenses
# ============================================================

@app.get("/expenses")
def get_expenses(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    transactions = (
        db.query(Expense)
        .filter(Expense.user_id == user.id)
        .order_by(
            Expense.transaction_date.desc(),
            Expense.id.desc(),
        )
        .all()
    )

    return [
        {
            "id": item.id,
            "title": item.title,
            "amount": float(item.amount),
            "type": item.type,
            "category": item.category,
            "transaction_date": item.transaction_date.isoformat(),
        }
        for item in transactions
    ]


# ============================================================
# DELETE A TRANSACTION
# DELETE /expenses/{expense_id}
# ============================================================

@app.delete("/expenses/{expense_id}")
def delete_expense(
    expense_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    transaction = (
        db.query(Expense)
        .filter(
            Expense.id == expense_id,
            Expense.user_id == user.id,
        )
        .first()
    )

    if transaction is None:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found",
        )

    try:
        db.delete(transaction)
        db.commit()

    except Exception:
        db.rollback()
        logging.exception("Could not delete transaction")

        raise HTTPException(
            status_code=500,
            detail="Could not delete transaction",
        )

    return {
        "message": "Transaction deleted successfully",
        "id": expense_id,
    }


# ============================================================
# VIEW MONTHLY BUDGET
# GET /budget
# ============================================================

@app.get("/budget")
def get_budget(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return {
        "monthly_budget": float(user.monthly_budget),
    }


# ============================================================
# UPDATE MONTHLY BUDGET
# PUT /budget
# ============================================================

@app.put("/budget")
def update_budget(
    data: BudgetUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        user.monthly_budget = data.monthly_budget
        db.commit()
        db.refresh(user)

    except Exception:
        db.rollback()
        logging.exception("Could not update monthly budget")

        raise HTTPException(
            status_code=500,
            detail="Could not update monthly budget",
        )

    return {
        "message": "Monthly budget updated successfully",
        "monthly_budget": float(user.monthly_budget),
    }


# ============================================================
# SEND MONTHLY EXPENSE REPORT BY EMAIL
# POST /reports/monthly-email
# ============================================================

@app.post("/reports/monthly-email")
def send_monthly_expense_report(
    month: int = Query(default=None, ge=1, le=12),
    year: int = Query(default=None, ge=2000, le=2100),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    today = date.today()

    selected_month = month if month is not None else today.month
    selected_year = year if year is not None else today.year

    start_date = datetime(selected_year, selected_month, 1)

    if selected_month == 12:
        end_date = datetime(selected_year + 1, 1, 1)
    else:
        end_date = datetime(
            selected_year,
            selected_month + 1,
            1,
        )

    # Fetch only this user's records for the selected month.
    records = (
        db.query(Expense)
        .filter(
            Expense.user_id == user.id,
            Expense.transaction_date >= start_date,
            Expense.transaction_date < end_date,
        )
        .all()
    )

    total_income = 0.0
    total_expenses = 0.0
    category_totals = {}

    for record in records:
        amount = float(record.amount)

        if record.type == "income":
            total_income += amount

        elif record.type == "expense":
            total_expenses += amount

            category = record.category or "Uncategorized"

            category_totals[category] = (
                category_totals.get(category, 0.0) + amount
            )

    month_name = date(
        selected_year,
        selected_month,
        1,
    ).strftime("%B")

    try:
        send_monthly_report_email(
            recipient_email=user.email,
            user_name=user.name,
            month_name=month_name,
            year=selected_year,
            total_income=total_income,
            total_expenses=total_expenses,
            category_totals=category_totals,
        )

    except Exception as error:
        logging.exception("Failed to send monthly report email")

        raise HTTPException(
            status_code=500,
            detail=(
                "Email could not be sent. "
                "Check the backend terminal for details."
            ),
        ) from error

    return {
        "message": f"Monthly report sent to {user.email}",
        "month": selected_month,
        "year": selected_year,
        "total_income": round(total_income, 2),
        "total_expenses": round(total_expenses, 2),
        "balance": round(total_income - total_expenses, 2),
    }
