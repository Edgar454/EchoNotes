import io
import os
import time
from dotenv import load_dotenv
from groq import AsyncGroq

load_dotenv()
api_key = os.getenv("GROQ_API_KEY")

client = AsyncGroq(api_key=api_key)

async def transcript(
    audio_bytes: bytes,
    source_language: str = "fr",
    log: bool = False,
    log_file: str = "transcription.log"
) -> str:
    """
    Transcribes an in-memory audio chunk (bytes) using Groq Whisper API.
    """
    start_time = time.time()

    if not audio_bytes:
        raise ValueError("Audio bytes input is empty.")

    try:
        # Convert bytes into file-like object
        flac_bytes = ("chunk.flac", io.BytesIO(audio_bytes))

        transcription = await client.audio.transcriptions.create(
            file=flac_bytes,
            model="whisper-large-v3-turbo",
            language=source_language,
        )

        elapsed = round(time.time() - start_time, 2)
        message = f"✅ Transcription completed in {elapsed}s"

        if log:
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(message + "\n")
        else:
            print(message)

        return transcription.text.strip()

    except Exception as e:
        message = f"❌ Transcription failed: {e}"
        if log:
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(message + "\n")
        else:
            print(message)
        return ""
