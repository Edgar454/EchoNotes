
import asyncio
import websockets
import requests
from pydub import AudioSegment
import io
import time
import json

# === 1. Sign in ===
signin_url = "https://chootes-edgar4545777-aqiisd24.leapcell.dev/auth/signin"
signin_payload = {
    "username": "mevaed4@gmail.com",
    "password": "string"
}

resp = requests.post(signin_url, data=signin_payload)
if resp.status_code != 200:
    print("❌ Sign-in failed:", resp.text)
    exit()

access_token = resp.json().get("access_token")
print("✅ Signed in successfully")

# === 2. Prepare WebSocket connection ===
session_id = "123"
ws_uri = f"wss://chootes-edgar4545777-aqiisd24.leapcell.dev/ws/{session_id}"
headers = {"Authorization": f"Bearer {access_token}"}

# === 3. Load and chunk audio ===
audio = AudioSegment.from_file("./api/sample.flac", format="flac")
chunk_duration_ms = 10000  # 2 seconds per chunk
total_duration = len(audio)
print(f"🎧 Loaded audio ({total_duration/1000:.2f}s total)")

# === 4. Stream chunks + measure latency ===
async def stream_audio():
    async with websockets.connect(ws_uri, additional_headers=headers, max_size=None) as websocket:
        print("🔌 Connected to WebSocket")

        async def listen_responses():
            """Continuously listen for responses from server."""
            while True:
                try:
                    msg = await websocket.recv()
                    now = time.time()
                    try:
                        data = json.loads(msg)
                        if "text" in data:
                            print(f"🗣️  Translated: {data['text']}")
                        elif "latency" in data:
                            print(f"⏱️  Reported latency: {data['latency']:.3f}s")
                        else:
                            print(f"📩 Server: {data}")
                    except json.JSONDecodeError:
                        print(f"📩 Raw: {msg}")
                except websockets.ConnectionClosed:
                    print("🔌 Server closed connection")
                    break

        listener_task = asyncio.create_task(listen_responses())

        for i, start in enumerate(range(0, total_duration, chunk_duration_ms)):
            end = min(start + chunk_duration_ms, total_duration)
            chunk = audio[start:end]

            # Export to bytes
            buffer = io.BytesIO()
            chunk.export(buffer, format="flac")
            chunk_bytes = buffer.getvalue()

            send_time = time.time()
            await websocket.send(chunk_bytes)
            print(f"📤 Sent chunk {i+1} ({start/1000:.1f}–{end/1000:.1f}s, {len(chunk_bytes)} bytes)")

            # Measure latency for this chunk
            try:
                ack = await asyncio.wait_for(websocket.recv(), timeout=10)
                latency = time.time() - send_time
                print(f"✅ Chunk {i+1} acked in {latency:.3f}s — server: {ack[:60]}...")
            except asyncio.TimeoutError:
                print(f"⚠️  No ack for chunk {i+1} after 10s")

            # Simulate real-time delay
            await asyncio.sleep(5)

        print("✅ All chunks sent — waiting for any final messages...")
        await asyncio.sleep(3)

        listener_task.cancel()
        await websocket.close()

asyncio.run(stream_audio())
