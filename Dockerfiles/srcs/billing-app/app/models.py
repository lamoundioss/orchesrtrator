from typing import List, Optional

from sqlalchemy import Column, Float, Integer
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from .extensions import db

# TITLE_MAX_LENGTH = 100
# DESCRIPTION_MAX_LENGTH = 500
FIRSTNAME_MAX_LENGTH = 50
LASTNAME_MAX_LENGTH = 50
EMAIL_MAX_LENGTH = 20
PASSWORD_MAX_LENGTH = 30


class Order(db.Model):
    __tablename__ = "orders"
    __table_args__ = {"extend_existing": True}

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, nullable=False)
    number_of_items = Column(Integer, nullable=False)
    total_amount = Column(Float, nullable=False)

    def __str__(self):
        return f"Order {self.id} - User {self.user_id} - {self.number_of_items} items - {self.total_amount}$"

    def __repr__(self):
        return f"<Order {self.id} - User {self.user_id}>"

    @classmethod
    def create(cls, user_id: int, number_of_items: int, total_amount: int) -> "Order":
        """Create and return a new Order."""
        try:
            order = cls(
                user_id=user_id,
                number_of_items=number_of_items,
                total_amount=total_amount,
            )
            db.session.add(order)
            db.session.commit()
            return order
        except IntegrityError as e:
            db.session.rollback()
            raise Exception(f"Integrity error occured: {str(e)}")
        except SQLAlchemyError as e:
            db.session.rollback()
            raise Exception(f"Database error occured while creating user: {str(e)}")

    @classmethod
    def get_by_id(cls, order_id: int) -> Optional["Order"]:
        """Retrieve an order by its ID."""
        try:
            return cls.query.get(order_id)
        except SQLAlchemyError as e:
            db.session.rollback()
            raise Exception(f"Database error occured: {str(e)}")

    @classmethod
    def get_all(cls) -> List["Order"]:
        """Retrieve all orders."""
        try:
            return cls.query.all()
        except SQLAlchemyError as e:
            db.session.rollback()
            raise Exception(f"Database error occurred: {str(e)}")

    @classmethod
    def delete(cls, order_id: int) -> None:
        """Delete an order by ID."""
        order = cls.get_by_id(order_id)
        try:
            if order:
                db.session.delete(order)
                db.session.commit()
            else:
                raise ValueError("Order not found.")
        except SQLAlchemyError:
            db.session.rollback()
            raise Exception("Database error occurred")

    @staticmethod
    def validate_input(user_id: int, number_of_items: int, total_amount: int) -> None:
        """Validate the order input data."""
        if user_id <= 0 or number_of_items <= 0 or total_amount <= 0:
            raise ValueError("All fields must be positive integers.")
        if number_of_items > 1000:
            raise ValueError("Number of items exceeds the limit.")

    def to_dict(self) -> dict:
        """Convert Order object to dictionary."""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "number_of_items": self.number_of_items,
            "total_amount": self.total_amount,
        }
