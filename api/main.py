from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.routes import websocket , auth , session
from api.routes.lifespan import lifespan

app = FastAPI(lifespan=lifespan)

# Optional CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the WebSocket router
app.include_router(auth.router)
app.include_router(websocket.router)
app.include_router(session.router)

