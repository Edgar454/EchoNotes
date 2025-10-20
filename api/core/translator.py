import asyncio
import time
from deep_translator import GoogleTranslator

async def translate_text(
    text: str,
    target_lang: str = "en-GB",
    source_lang: str = "fr-FR",
    log: bool = False
) -> str:
    if not text:
        return ""

    if source_lang == target_lang:
        return text

    start_time = time.time()
    try:
        translated_text = await asyncio.to_thread(
            lambda: GoogleTranslator(source='fr', target='en').translate(text).strip()
        )
    except Exception as e:
        if log:
            print(f"⚠️ Translation failed: {e}")
        return text

    if log:
        elapsed = round(time.time() - start_time, 2)
        print(f"Original text: {text}")
        print(f"Translated text: {translated_text}")
        print(f"Translation time: {elapsed}s")

    return translated_text or text
