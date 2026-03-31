import razorpay
import hmac
import hashlib
from app.config import RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET, USE_MOCK_PAYMENTS


class RazorpayService:

    def __init__(self):
        self.client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))

    def create_subscription(self, plan_id: str, total_count: int = 52) -> dict:
        data = {
            "plan_id": plan_id,
            "total_count": total_count,
            "quantity": 1,
        }
        return self.client.subscription.create(data)

    def fetch_subscription(self, subscription_id: str) -> dict:
        return self.client.subscription.fetch(subscription_id)

    def cancel_subscription(self, subscription_id: str) -> dict:
        return self.client.subscription.cancel(subscription_id)

    def create_payout(self, upi_id: str, amount_paise: int, driver_id: str) -> dict:
        data = {
            "account_number": "YOUR_RAZORPAY_ACCOUNT_NUMBER",
            "amount": amount_paise,
            "currency": "INR",
            "mode": "UPI",
            "purpose": "payout",
            "fund_account": {
                "account_type": "vpa",
                "vpa": {
                    "address": upi_id
                },
            },
            "notes": {
                "driver_id": driver_id
            }
        }
        return self.client.payout.create(data)

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        expected = hmac.new(
            RAZORPAY_WEBHOOK_SECRET.encode(),
            payload,
            hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(expected, signature)


class MockRazorpayService:

    def create_subscription(self, plan_id: str, total_count: int = 52) -> dict:
        return {
            "id": "sub_mock_123",
            "status": "created",
            "plan_id": plan_id,
        }

    def fetch_subscription(self, subscription_id: str) -> dict:
        return {
            "id": subscription_id,
            "status": "active",
        }

    def cancel_subscription(self, subscription_id: str) -> dict:
        return {
            "id": subscription_id,
            "status": "cancelled",
        }

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