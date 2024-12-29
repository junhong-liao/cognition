from flask import Flask
from flask_cors import CORS
from .api.routes import api
from .infrastructure.openai_service import OpenAIVisionService
from .usecases.process_image_usecase import ProcessImageUseCase
from config import Config

def create_app(config_class=Config):
    app = Flask(__name__)
    CORS(app)
    
    # Initialize services
    vision_service = OpenAIVisionService(config_class.OPENAI_API_KEY)
    process_image_usecase = ProcessImageUseCase(vision_service)
    
    # Register blueprints
    from .api.routes import init_routes
    init_routes(process_image_usecase)
    app.register_blueprint(api)
    
    return app 