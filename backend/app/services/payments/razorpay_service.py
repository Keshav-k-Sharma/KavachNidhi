import razorpay
import hmac
import hashlib
from app.config import settings

RAZORPAY_KEY_ID = settings.RAZORPAY_KEY_ID
RAZORPAY_KEY_SECRET = settings.RAZORPAY_KEY_SECRET
RAZORPAY_WEBHOOK_SECRET = settings.RAZORPAY_WEBHOOK_SECRET
USE_MOCK_PAYMENTS = settings.USE_MOCK_PAYMENTS


class RazorpayService:

    def __init__(self):
        self.client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))

    def create_order(self, amount_paise: int, receipt: str, notes: dict = None) -> dict:
        return self.client.order.create({
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,
            "notes": notes or {},
        })

    def capture_payment(self, payment_id: str, amount_paise: int) -> dict:
        return self.client.payment.capture(payment_id, amount_paise, {"currency": "INR"})

    def create_recurring_payment(
        self,
        amount_paise: int,
        order_id: str,
        token_id: str,
        phone: str,
        description: str,
    ) -> dict:
        return self.client.payment.create_recurring({
            "email": "noreply@kavachnidhi.com",
            "contact": phone,
            "amount": amount_paise,
            "currency": "INR",
            "order_id": order_id,
            "token": token_id,
            "recurring": 1,
            "description": description,
            "notify": {"sms": True, "email": False},
            "reminder_enable": False,
        })

    def fetch_payment(self, payment_id: str) -> dict:
        return self.client.payment.fetch(payment_id)

    def create_payout(self, upi_id: str, amount_paise: int, driver_id: str) -> dict:
        return self.client.payout.create({
            "account_number": "YOUR_RAZORPAY_ACCOUNT_NUMBER",
            "amount": amount_paise,
            "currency": "INR",
            "mode": "UPI",
            "purpose": "payout",
            "fund_account": {
                "account_type": "vpa",
                "vpa": {"address": upi_id},
            },
            "notes": {"driver_id": driver_id},
        })

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        expected = hmac.new(
            RAZORPAY_WEBHOOK_SECRET.encode(),
            payload,
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(expected, signature)


class MockRazorpayService:

    def create_order(self, amount_paise: int, receipt: str, notes: dict = None) -> dict:
        return {
            "id": "order_mock_001",
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,
            "status": "created",
        }

    def capture_payment(self, payment_id: str, amount_paise: int) -> dict:
        return {"id": payment_id, "status": "captured"}

    def create_recurring_payment(
        self,
        amount_paise: int,
        order_id: str,
        token_id: str,
        phone: str,
        description: str,
    ) -> dict:
        return {
            "razorpay_payment_id": "pay_mock_001",
            "razorpay_order_id": order_id,
            "razorpay_token_id": token_id,
        }

    def fetch_payment(self, payment_id: str) -> dict:
        return {"id": payment_id, "status": "captured", "amount": 5000}

    def create_payout(self, upi_id: str, amount_paise: int, driver_id: str) -> dict:
        return {
            "id": "pout_mock_123",
            "status": "processed",
            "upi_id": upi_id,
            "amount": amount_paise,
        }

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        return True


def get_razorpay_service():
    if USE_MOCK_PAYMENTS:
        return MockRazorpayService()
    return RazorpayService()
