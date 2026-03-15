"""
Locust load test for Retail Store Sample App.
Flow: home -> catalog -> product pages -> add to cart -> cart -> checkout (address, delivery, payment).
"""
import random
from locust import HttpUser, task, between

PRODUCT_IDS = [
    "cc789f85-1476-452a-8100-9e74502198e0",
    "87e89b11-d319-446d-b9be-50adcca5224a",
    "4f18544b-70a5-4352-8e19-0d070f46745d",
    "79bce3f3-935f-4912-8c62-0d2f3e059405",
    "d27cf49f-b689-4a75-a249-d373e0330bb5",
    "1ca35e86-4b4c-4124-b6b5-076ba4134d0d",
    "631a3db5-ac07-492c-a994-8cd56923c112",
    "8757729a-c518-4356-8694-9e795a9b3237",
    "d4edfedb-dbe9-4dd9-aae8-009489394955",
]


class RetailStoreUser(HttpUser):
    """Simulates a user browsing catalog, adding to cart, and completing checkout."""

    wait_time = between(0.5, 2.0)

    @task(10)
    def browse_and_checkout(self):
        """Full flow: home -> catalog -> products -> cart -> checkout."""
        self.client.get("/home", name="/home")
        self.client.get("/catalog", name="/catalog")
        for product_id in random.sample(PRODUCT_IDS, min(3, len(PRODUCT_IDS))):
            self.client.get(f"/catalog/{product_id}", name="/catalog/[id]")
        self.client.post(
            "/cart",
            data={"productId": random.choice(PRODUCT_IDS)},
            name="/cart (add)",
        )
        self.client.get("/cart", name="/cart")
        self.client.get("/checkout", name="/checkout")
        self.client.post(
            "/checkout",
            data={
                "firstName": "John",
                "lastName": "Doe",
                "email": "john_doe@example.com",
                "streetAddress": "100 Main Street",
                "city": "Anytown",
                "state": "CA",
                "zipCode": "11111",
            },
            name="/checkout (address)",
        )
        self.client.post(
            "/checkout/delivery",
            data={"token": "priority-mail"},
            name="/checkout/delivery",
        )
        self.client.post(
            "/checkout/payment",
            data={
                "cardHolder": "John Doe",
                "cardNumber": "1234567890123456",
                "expiryDate": "01/35",
                "cvc": "123",
            },
            name="/checkout/payment",
        )

    @task(5)
    def browse_catalog_only(self):
        """Lighter: home and catalog only."""
        self.client.get("/home", name="/home")
        self.client.get("/catalog", name="/catalog")
        for product_id in random.sample(PRODUCT_IDS, min(2, len(PRODUCT_IDS))):
            self.client.get(f"/catalog/{product_id}", name="/catalog/[id]")

    @task(2)
    def view_cart(self):
        """Open home and cart."""
        self.client.get("/home", name="/home")
        self.client.get("/cart", name="/cart")
