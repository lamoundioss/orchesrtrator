from typing import Any, Dict, List, Optional

from sqlalchemy import Column, Integer, String

from .extensions import db

TITLE_MAX_LENGTH = 100
DESCRIPTION_MAX_LENGTH = 500


class Movie(db.Model):
    __tablename__ = "movies"

    id = Column(Integer, primary_key=True)
    title = Column(String(TITLE_MAX_LENGTH), nullable=False)
    description = Column(String(DESCRIPTION_MAX_LENGTH), nullable=False)

    def __str__(self):
        return f"{self.title}"

    def __repr__(self):
        return f"<Movie {self.title}>"

    def to_dict(self) -> Dict[str, Any]:
        """Convert movie to dictionary."""
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
        }

    def insert(self) -> "Movie":
        """Insert movie into the database."""
        try:
            self.validate_input(self.title, self.description)
            db.session.add(self)
            db.session.commit()
            return self
        except Exception as e:
            db.session.rollback()
            raise e

    def delete(self) -> None:
        """Delete movie from the database."""
        try:
            db.session.delete(self)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e

    def update_movie(self, title: str, description: str) -> "Movie":
        """Update movie details."""
        try:
            self.validate_input(title, description)
            self.title = title
            self.description = description
            db.session.commit()
            return self
        except Exception as e:
            db.session.rollback()
            raise e

    @classmethod
    def get_all(cls) -> List["Movie"]:
        """Get all movies from the database."""
        return cls.query.all()

    @classmethod
    def get_by_id(cls, id: int) -> Optional["Movie"]:
        """Get a movie by its ID."""
        return cls.query.get(id)

    @classmethod
    def get_by_title(cls, name: str) -> List["Movie"]:
        """Get movies by partial title match."""
        return cls.query.filter(cls.title.ilike(f"%{name}%")).all()

    @staticmethod
    def validate_input(
        title: Optional[str] = None, description: Optional[str] = None
    ) -> None:
        """Validate input parameters."""
        if title is None:
            raise ValueError("Title is required")
        if description is None:
            raise ValueError("Description is required")

        if not title.strip():
            raise ValueError("Title cannot be empty")
        if len(title) > TITLE_MAX_LENGTH:
            raise ValueError(f"Title too long (max {TITLE_MAX_LENGTH} characters)")

        if not description.strip():
            raise ValueError("Description cannot be empty")
        if len(description) > DESCRIPTION_MAX_LENGTH:
            raise ValueError(f"Description too long (max {DESCRIPTION_MAX_LENGTH} characters)")
