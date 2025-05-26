from flask import abort, jsonify, request

from .models import Movie


def register_routes(app):
    @app.route("/movies", methods=["POST"])
    def add_movie():
        """
        Add a new movie.

        Request Body:
            - title (str): The title of the movie (required).
            - description (str): The description of the movie (optional).

        Returns:
            - 201: Movie created successfully.
            - 400: Invalid input data.
        """

        data = request.get_json()
        if not data:
            abort(400, description="Request must be JSON")

        movie = Movie(title=data.get("title"), description=data.get("description"))

        try:
            movie = movie.insert()
            return jsonify({"success": True, "movie": movie.to_dict()}), 200
        except ValueError as e:
            abort(400, description=str(e))
        except Exception as e:
            app.logger.error(f"Error adding movie: {e}")
            abort(500)

    @app.route("/movies", methods=["GET"])
    def get_movies():
        """
        Get all movies or filter by title.

        Query Parameters:
            - title (str): Filter movies by title (optional).

        Returns:
            - 200: List of movies.
        """

        title = request.args.get("title")
        if title:
            movies = Movie.get_by_title(title)
        else:
            movies = Movie.get_all()
        return jsonify({"movies": [movie.to_dict() for movie in movies]}), 200

    @app.route("/movies", methods=["DELETE"])
    def delete_movies():
        """
        Delete all movies.

        Returns:
            - 200: All movies deleted successfully.
        """

        for movie in Movie.get_all():
            movie.delete()
        return jsonify({"message": "All movies deleted successfully"}), 200

    @app.route("/movies/<int:id>", methods=["GET"])
    def get_movie_by_id(id):
        """
        Get a movie by ID.

        Parameters:
            - id (int): The ID of the movie.

        Returns:
            - 200: Movie details.
            - 404: Movie not found.
        """

        movie = Movie.get_by_id(id)
        if not movie:
            abort(404)

        return jsonify({"movie": movie.to_dict()}), 200

    @app.route("/movies/<int:id>", methods=["PUT"])
    def update_movie_by_id(id):
        """
        Update a movie by ID.

        Request Body:
            - title (str): The new title of the movie (required).
            - description (str): The new description of the movie (required).

        Returns:
            - 200: Movie updated successfully.
            - 400: Invalid input data.
            - 404: Movie not found.
        """

        data = request.get_json()
        if not data:
            abort(400, description="Request must be JSON")
        movie = Movie.get_by_id(id)
        if not movie:
            abort(404)

        try:
            movie = movie.update_movie(
                request.json.get("title"), request.json.get("description")
            )
            return jsonify({"success": True, "movie": movie.to_dict()}), 200
        except ValueError as e:
            abort(400, description=str(e))
        except Exception as e:
            app.logger.error(f"Error updating movie: {e}")
            abort(500)

    @app.route("/movies/<int:id>", methods=["DELETE"])
    def delete_movie_by_id(id):
        """
        Delete a movie by ID.

        Parameters:
            - id (int): The ID of the movie.

        Returns:
            - 200: Movie deleted successfully.
            - 404: Movie not found.
        """

        movie = Movie.get_by_id(id)
        if not movie:
            abort(404)

        movie.delete()

        return jsonify({"message": "Movie deleted successfully"}), 200

    @app.errorhandler(404)
    def not_found(error):
        """
        Handle 404 errors.

        Returns:
            - 404: Resource not found.
        """
        return (
            jsonify(
                {
                    "success": False,
                    "error": 404,
                    "message": "The requested resource was not found.",
                }
            ),
            404,
        )

    @app.errorhandler(400)
    def bad_request(error):
        """
        Handle 400 errors.

        Returns:
            - 400: Bad request with custom message.
        """
        return (
            jsonify(
                {
                    "success": False,
                    "error": 400,
                    "message": f"Bad request: {error.description}",
                }
            ),
            400,
        )

    @app.errorhandler(500)
    def internal_server_error(error):
        """
        Handle 500 errors.

        Returns:
            - 500: Internal server error.
        """
        return (
            jsonify(
                {
                    "success": False,
                    "error": 500,
                    "message": "Internal server error. Please try again later.",
                }
            ),
            500,
        )
