#!/usr/bin/env python3
"""
Multi-modal LLM capability tester.

    Updated: 5/13/2026
    Version: 0.0.2

    wget --no-cache -O 'test_llm.py' 'https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/test_llm.py' && chmod u+x test_llm.py


Tests text, image, audio, and video modalities via an OpenAI-compatible API
(vLLM, Ollama, or any compatible server).

Usage:
    python3 test_llm.py [--host URL] [--model NAME] [options]
    python3 test_llm.py --host http://127.0.0.1:8001 --model Nemotron-3-Nano-Omni-30B-A3B
    python3 test_llm.py --image /path/to/photo.jpg --audio /path/to/clip.wav
    python3 test_llm.py --skip audio video            # text + image only
    python3 test_llm.py --json                        # machine-readable output
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import math
import struct
import sys
import time
import wave
import zlib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import requests

try:
    import yfinance
    _YFINANCE_OK = True
except ImportError:
    _YFINANCE_OK = False

# ── Defaults ──────────────────────────────────────────────────────────────────
DEFAULT_MODEL = "Nemotron-3-Nano-Omni-30B-A3B"
DEFAULT_HOST  = "http://localhost:8001"

# ── ANSI colours ──────────────────────────────────────────────────────────────
GREEN  = "\033[32m"
RED    = "\033[31m"
YELLOW = "\033[33m"
CYAN   = "\033[36m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
RESET  = "\033[0m"

ICON_PASS = f"{GREEN}[PASS]{RESET}"
ICON_FAIL = f"{RED}[FAIL]{RESET}"
ICON_SKIP = f"{YELLOW}[SKIP]{RESET}"
ICON_WARN = f"{YELLOW}[WARN]{RESET}"


# ── Data classes ──────────────────────────────────────────────────────────────
@dataclass
class TestResult:
    name:       str
    passed:     bool
    response:   str  = ""
    error:      str  = ""
    latency_ms: int  = 0
    tokens:     dict = field(default_factory=dict)
    skipped:    bool = False


# ── Synthetic test assets ─────────────────────────────────────────────────────

def _png_1x1(r: int = 100, g: int = 149, b: int = 237) -> bytes:
    """Minimal valid 1×1 RGB PNG."""
    def chunk(tag: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
    idat = chunk(b"IDAT", zlib.compress(b"\x00" + bytes([r, g, b])))
    iend = chunk(b"IEND", b"")
    return b"\x89PNG\r\n\x1a\n" + ihdr + idat + iend


def _wav_beep(freq: int = 440, duration_ms: int = 500, sample_rate: int = 16000) -> bytes:
    """Minimal mono WAV tone — enough for an audio-capable model to process."""
    n = int(sample_rate * duration_ms / 1000)
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        frames = b"".join(
            struct.pack("<h", int(32767 * math.sin(2 * math.pi * freq * i / sample_rate)))
            for i in range(n)
        )
        w.writeframes(frames)
    return buf.getvalue()


def _b64(data: bytes) -> str:
    return base64.b64encode(data).decode()


def _data_url(mime: str, data: bytes) -> str:
    return f"data:{mime};base64,{_b64(data)}"


def _mime_for(path: str, default: str) -> str:
    ext = Path(path).suffix.lower().lstrip(".")
    table = {
        "jpg": "image/jpeg", "jpeg": "image/jpeg",
        "png": "image/png",  "gif": "image/gif", "webp": "image/webp",
        "bmp": "image/bmp",  "tiff": "image/tiff",
        "wav": "audio/wav",  "mp3": "audio/mpeg", "flac": "audio/flac",
        "ogg": "audio/ogg",  "m4a": "audio/mp4", "aac": "audio/aac",
        "mp4": "video/mp4",  "webm": "video/webm",
        "avi": "video/x-msvideo", "mov": "video/quicktime", "mkv": "video/x-matroska",
    }
    return table.get(ext, default)


# ── API client ────────────────────────────────────────────────────────────────

class Client:
    def __init__(self, base_url: str, model: str, api_key: str = "none", timeout: int = 180):
        self.base_url = base_url.rstrip("/")
        self.model    = model
        self.timeout  = timeout
        self._s       = requests.Session()
        self._s.headers.update({
            "Authorization": f"Bearer {api_key}",
            "Content-Type":  "application/json",
        })

    def chat(self, messages: list, max_tokens: int = 512, temperature: float = 0.1) -> dict:
        r = self._s.post(
            f"{self.base_url}/v1/chat/completions",
            json={"model": self.model, "messages": messages,
                  "max_tokens": max_tokens, "temperature": temperature},
            timeout=self.timeout,
        )
        r.raise_for_status()
        return r.json()

    def list_models(self) -> list[str]:
        r = self._s.get(f"{self.base_url}/v1/models", timeout=10)
        r.raise_for_status()
        return [m["id"] for m in r.json().get("data", [])]

    def text_from(self, resp: dict) -> str:
        return resp["choices"][0]["message"]["content"]


# ── Individual tests ──────────────────────────────────────────────────────────

def _run(client: Client, messages: list, name: str,
         max_tokens: int = 400, validate=None) -> TestResult:
    t0 = time.monotonic()
    try:
        resp   = client.chat(messages, max_tokens=max_tokens)
        text   = client.text_from(resp)
        tokens = resp.get("usage", {})
        passed = bool(text and text.strip())
        if passed and validate:
            passed = validate(text)
        return TestResult(name=name, passed=passed, response=text.strip(),
                          tokens=tokens, latency_ms=int((time.monotonic() - t0) * 1000))
    except Exception as exc:
        return TestResult(name=name, passed=False, error=str(exc),
                          latency_ms=int((time.monotonic() - t0) * 1000))


def test_text(client: Client) -> TestResult:
    return _run(client, [
        {"role": "system", "content": "You are a concise assistant."},
        {"role": "user",   "content":
            "Explain what a transformer neural network is in exactly 2 sentences."},
    ], name="text")


def test_reasoning(client: Client) -> TestResult:
    return _run(client, [{
        "role": "user",
        "content": ("If all bloops are razzies and all razzies are lazzies, "
                    "are all bloops definitely lazzies? "
                    "Answer Yes or No first, then explain in one sentence."),
    }], name="reasoning", max_tokens=80,
        validate=lambda t: t.strip().lower().startswith("yes"))


def test_code(client: Client) -> TestResult:
    return _run(client, [{
        "role": "user",
        "content": ("Write a Python function that returns the nth Fibonacci number "
                    "using memoization. Return only the code, no explanation."),
    }], name="code_generation", max_tokens=300,
        validate=lambda t: "def " in t and "fibonacci" in t.lower())


def test_multilingual(client: Client) -> TestResult:
    return _run(client, [{
        "role": "user",
        "content": "Translate 'Hello, how are you?' into French, Spanish, and Japanese. One per line.",
    }], name="multilingual", max_tokens=120,
        validate=lambda t: len(t) > 25)


def test_math(client: Client) -> TestResult:
    return _run(client, [{
        "role": "user",
        "content": "What is 17 × 23? Show your working briefly, then give the final answer.",
    }], name="math", max_tokens=100,
        validate=lambda t: "391" in t)


def test_image(client: Client, image_path: Optional[str] = None) -> TestResult:
    if image_path:
        raw  = Path(image_path).read_bytes()
        mime = _mime_for(image_path, "image/jpeg")
        url  = _data_url(mime, raw)
        prompt = "Describe what you see in this image in 1–2 sentences."
    else:
        # 1×1 red pixel — model should report red/solid colour
        raw  = _png_1x1(r=220, g=30, b=30)
        url  = _data_url("image/png", raw)
        prompt = "What is the dominant colour of this image? Reply with just the colour name."

    messages = [{
        "role": "user",
        "content": [
            {"type": "image_url", "image_url": {"url": url}},
            {"type": "text", "text": prompt},
        ],
    }]
    result = _run(client, messages, name="image", max_tokens=150)
    if not image_path and result.passed:
        result.passed = "red" in result.response.lower()
    return result


def test_multi_image(client: Client) -> TestResult:
    """Send two different-coloured pixels and ask the model to compare them."""
    red   = _data_url("image/png", _png_1x1(220,  30,  30))
    blue  = _data_url("image/png", _png_1x1( 30,  80, 220))
    messages = [{
        "role": "user",
        "content": [
            {"type": "image_url", "image_url": {"url": red}},
            {"type": "image_url", "image_url": {"url": blue}},
            {"type": "text", "text":
                "I sent you two tiny images. What colour is image 1? What colour is image 2? "
                "Answer in the format: Image 1: <colour>, Image 2: <colour>"},
        ],
    }]
    return _run(client, messages, name="multi_image", max_tokens=60,
                validate=lambda t: "image 1" in t.lower() or "1:" in t)


def test_audio(client: Client, audio_path: Optional[str] = None,
               audio_format: str = "audio_url") -> TestResult:
    """
    Test audio understanding.

    audio_format options:
      "audio_url"   — Nemotron-Omni / Qwen-Omni style  {"type":"audio_url","audio_url":{"url":...}}
      "input_audio" — OpenAI Realtime style              {"type":"input_audio","input_audio":{"data":...,"format":"wav"}}
    """
    if audio_path:
        raw   = Path(audio_path).read_bytes()
        mime  = _mime_for(audio_path, "audio/wav")
        fmt   = Path(audio_path).suffix.lower().lstrip(".")
    else:
        raw  = _wav_beep(freq=440, duration_ms=500)
        mime = "audio/wav"
        fmt  = "wav"

    if audio_format == "input_audio":
        content_block = {
            "type":        "input_audio",
            "input_audio": {"data": _b64(raw), "format": fmt},
        }
    else:
        content_block = {
            "type":      "audio_url",
            "audio_url": {"url": _data_url(mime, raw)},
        }

    messages = [{
        "role": "user",
        "content": [
            content_block,
            {"type": "text", "text": "Describe what you hear in this audio. Be brief."},
        ],
    }]
    result = _run(client, messages, name=f"audio ({audio_format})", max_tokens=200)
    return result


def test_audio_with_fallback(client: Client, audio_path: Optional[str] = None) -> list[TestResult]:
    """Try audio_url first, fall back to input_audio if the first fails."""
    r1 = test_audio(client, audio_path, audio_format="audio_url")
    results = [r1]
    if not r1.passed and ("422" in r1.error or "400" in r1.error or "not supported" in r1.error.lower()):
        r2 = test_audio(client, audio_path, audio_format="input_audio")
        results.append(r2)
    return results


def test_video(client: Client, video_path: Optional[str] = None) -> TestResult:
    """
    Test video understanding via video_url content block.
    Requires a real video file — synthetic video generation is out of scope.
    """
    if not video_path:
        return TestResult(
            name="video", passed=False, skipped=True,
            error="No video file — pass --video <path.mp4> to enable this test.",
        )

    raw   = Path(video_path).read_bytes()
    mime  = _mime_for(video_path, "video/mp4")
    url   = _data_url(mime, raw)
    messages = [{
        "role": "user",
        "content": [
            {"type": "video_url", "video_url": {"url": url}},
            {"type": "text", "text": "Briefly describe what happens in this video in 1–2 sentences."},
        ],
    }]
    return _run(client, messages, name="video", max_tokens=250)


def test_image_ocr(client: Client, image_path: Optional[str] = None) -> TestResult:
    """Test reading text embedded in an image (OCR capability)."""
    if not image_path:
        return TestResult(
            name="image_ocr", passed=False, skipped=True,
            error="No image provided — pass --image <path> to enable OCR test.",
        )
    raw  = Path(image_path).read_bytes()
    mime = _mime_for(image_path, "image/jpeg")
    url  = _data_url(mime, raw)
    messages = [{
        "role": "user",
        "content": [
            {"type": "image_url", "image_url": {"url": url}},
            {"type": "text", "text": "Read and transcribe any text visible in this image. If there is none, say 'No text found'."},
        ],
    }]
    return _run(client, messages, name="image_ocr", max_tokens=300)


def _rsi(closes: list[float], period: int = 14) -> float:
    """Calculate RSI from a list of closing prices."""
    if len(closes) < period + 1:
        return float("nan")
    gains, losses = [], []
    for i in range(1, len(closes)):
        d = closes[i] - closes[i - 1]
        gains.append(max(d, 0))
        losses.append(max(-d, 0))
    avg_gain = sum(gains[-period:]) / period
    avg_loss = sum(losses[-period:]) / period
    if avg_loss == 0:
        return 100.0
    rs = avg_gain / avg_loss
    return 100 - (100 / (1 + rs))


def _fetch_stock_data(ticker: str) -> dict:
    """Fetch price history and fundamentals via yfinance."""
    t    = yfinance.Ticker(ticker)
    info = t.info
    hist = t.history(period="60d")

    closes  = hist["Close"].tolist()
    volumes = hist["Volume"].tolist()
    dates   = [str(d.date()) for d in hist.index]

    # Build recent history rows (last 10 trading days)
    recent = []
    for i in range(max(0, len(dates) - 10), len(dates)):
        row = hist.iloc[i]
        recent.append({
            "date":   dates[i],
            "open":   round(float(row["Open"]),   2),
            "high":   round(float(row["High"]),   2),
            "low":    round(float(row["Low"]),     2),
            "close":  round(float(row["Close"]),   2),
            "volume": int(row["Volume"]),
        })

    sma20  = round(sum(closes[-20:]) / min(20, len(closes)), 2) if closes else None
    sma50  = round(sum(closes[-50:]) / min(50, len(closes)), 2) if closes else None
    rsi14  = round(_rsi(closes), 1) if closes else None
    vol_avg = int(sum(volumes[-10:]) / min(10, len(volumes))) if volumes else None

    def _get(*keys):
        for k in keys:
            v = info.get(k)
            if v is not None:
                return v
        return None

    return {
        "ticker":         ticker.upper(),
        "name":           _get("shortName", "longName"),
        "sector":         _get("sector"),
        "current_price":  _get("currentPrice", "regularMarketPrice"),
        "prev_close":     _get("previousClose"),
        "day_open":       _get("open"),
        "day_high":       _get("dayHigh"),
        "day_low":        _get("dayLow"),
        "volume":         _get("volume"),
        "avg_volume_10d": vol_avg,
        "avg_volume_3m":  _get("averageVolume"),
        "week52_high":    _get("fiftyTwoWeekHigh"),
        "week52_low":     _get("fiftyTwoWeekLow"),
        "sma_20d":        sma20,
        "sma_50d":        sma50,
        "sma_150d":       _get("fiftyDayAverage"),   # closest yfinance has
        "sma_200d":       _get("twoHundredDayAverage"),
        "rsi_14d":        rsi14,
        "pe_trailing":    _get("trailingPE"),
        "pe_forward":     _get("forwardPE"),
        "market_cap":     _get("marketCap"),
        "beta":           _get("beta"),
        "dividend_yield": _get("dividendYield"),
        "revenue_growth_yoy": _get("revenueGrowth"),
        "earnings_growth_yoy": _get("earningsGrowth"),
        "analyst_recommendation_mean": _get("recommendationMean"),
        "analyst_count":  _get("numberOfAnalystOpinions"),
        "recent_10d_ohlcv": recent,
    }


def _build_stock_prompt(data: dict) -> str:
    price  = data.get("current_price") or data.get("prev_close", "N/A")
    s52h   = data.get("week52_high")
    s52l   = data.get("week52_low")
    pct_from_high = (
        f"{((price - s52h) / s52h * 100):+.1f}% from 52w high"
        if price and s52h else ""
    )
    pct_from_low = (
        f"{((price - s52l) / s52l * 100):+.1f}% from 52w low"
        if price and s52l else ""
    )

    rows = "\n".join(
        f"  {r['date']}  O={r['open']}  H={r['high']}  L={r['low']}  "
        f"C={r['close']}  Vol={r['volume']:,}"
        for r in data.get("recent_10d_ohlcv", [])
    )

    return f"""You are a financial analyst. Analyse the following real-time market data for {data['ticker']} ({data.get('name', '')}) and give a trading recommendation.

=== MARKET DATA ({data['ticker']}) ===
Current price : ${price}
Day range     : ${data.get('day_low')} – ${data.get('day_high')}
Prev close    : ${data.get('prev_close')}
52-week range : ${s52l} – ${s52h}  ({pct_from_high}, {pct_from_low})

--- Technical Indicators ---
SMA 20d  : ${data.get('sma_20d')}
SMA 50d  : ${data.get('sma_50d')}
SMA 200d : ${data.get('sma_200d')}
RSI 14d  : {data.get('rsi_14d')} (>70 overbought, <30 oversold)
Volume today : {(data.get('volume') or 0):,}  (10d avg: {(data.get('avg_volume_10d') or 0):,}, 3m avg: {(data.get('avg_volume_3m') or 0):,})
Beta     : {data.get('beta')}

--- Fundamentals ---
P/E trailing : {data.get('pe_trailing')}
P/E forward  : {data.get('pe_forward')}
Market cap   : ${data.get('market_cap'):,}
Revenue growth YoY : {data.get('revenue_growth_yoy')}
Earnings growth YoY: {data.get('earnings_growth_yoy')}
Dividend yield     : {data.get('dividend_yield')}
Sector             : {data.get('sector')}

--- Analyst Consensus ---
Mean recommendation: {data.get('analyst_recommendation_mean')} (1=Strong Buy, 5=Strong Sell)
Number of analysts : {data.get('analyst_count')}

--- Last 10 Trading Days (OHLCV) ---
{rows}

=== INSTRUCTIONS ===
Based ONLY on the data above, provide your recommendation in EXACTLY this format (no other text before it):

RECOMMENDATION: <BUY|SELL|HOLD>
CONFIDENCE: <integer 0–100>
REASONING: <2–4 sentences covering technicals, fundamentals, and risk>
"""


def _parse_stock_response(text: str) -> tuple[str, int, str]:
    """Extract (recommendation, confidence, reasoning) from model output."""
    import re
    rec   = re.search(r"RECOMMENDATION\s*:\s*(BUY|SELL|HOLD)", text, re.IGNORECASE)
    conf  = re.search(r"CONFIDENCE\s*:\s*(\d+)",               text, re.IGNORECASE)
    rsn   = re.search(r"REASONING\s*:\s*(.+)",                 text, re.IGNORECASE | re.DOTALL)

    recommendation = rec.group(1).upper()  if rec  else "UNKNOWN"
    confidence     = int(conf.group(1))    if conf else -1
    reasoning      = rsn.group(1).strip()  if rsn  else text.strip()
    return recommendation, confidence, reasoning


def test_stock(client: Client, ticker: str = "MU") -> TestResult:
    """Fetch live stock data and ask the model for a BUY/SELL/HOLD with confidence score."""
    if not _YFINANCE_OK:
        return TestResult(
            name=f"stock ({ticker})", passed=False, skipped=True,
            error="yfinance not installed — run: pip install yfinance",
        )

    t0 = time.monotonic()
    try:
        data = _fetch_stock_data(ticker)
    except Exception as exc:
        return TestResult(name=f"stock ({ticker})", passed=False,
                          error=f"Failed to fetch stock data: {exc}",
                          latency_ms=int((time.monotonic() - t0) * 1000))

    prompt = _build_stock_prompt(data)
    messages = [
        {"role": "system", "content": "You are a concise financial analyst. Follow the output format exactly."},
        {"role": "user",   "content": prompt},
    ]

    fetch_ms = int((time.monotonic() - t0) * 1000)
    t1 = time.monotonic()
    try:
        resp   = client.chat(messages, max_tokens=400, temperature=0.2)
        text   = client.text_from(resp)
        tokens = resp.get("usage", {})
    except Exception as exc:
        return TestResult(name=f"stock ({ticker})", passed=False,
                          error=str(exc),
                          latency_ms=fetch_ms + int((time.monotonic() - t1) * 1000))

    llm_ms = int((time.monotonic() - t1) * 1000)
    recommendation, confidence, reasoning = _parse_stock_response(text)

    passed = recommendation in ("BUY", "SELL", "HOLD") and 0 <= confidence <= 100

    # Format the result summary for display
    price = data.get("current_price") or data.get("prev_close", "?")
    rsi   = data.get("rsi_14d", "?")
    sma20 = data.get("sma_20d", "?")
    rec_colour = {"BUY": GREEN, "SELL": RED, "HOLD": YELLOW}.get(recommendation, "")
    summary = (
        f"{rec_colour}{BOLD}{recommendation}{RESET} | confidence: {confidence}% | "
        f"${price} | RSI={rsi} | SMA20=${sma20} | "
        f"fetch={fetch_ms}ms llm={llm_ms}ms\n"
        f"     {reasoning}"
    )

    return TestResult(
        name=f"stock ({ticker})", passed=passed,
        response=summary, tokens=tokens,
        latency_ms=fetch_ms + llm_ms,
    )


def test_streaming(client: Client) -> TestResult:
    """Verify streaming SSE works."""
    t0 = time.monotonic()
    try:
        payload = {
            "model":       client.model,
            "messages":    [{"role": "user", "content": "Count from 1 to 5, one number per line."}],
            "max_tokens":  40,
            "temperature": 0,
            "stream":      True,
        }
        resp = client._s.post(
            f"{client.base_url}/v1/chat/completions",
            json=payload, stream=True, timeout=30,
        )
        resp.raise_for_status()
        chunks = []
        for line in resp.iter_lines():
            if line and line.startswith(b"data:"):
                body = line[5:].strip()
                if body == b"[DONE]":
                    break
                chunks.append(body)
                if len(chunks) >= 3:
                    break
        passed = len(chunks) > 0
        return TestResult(name="streaming", passed=passed,
                          response=f"Received {len(chunks)} SSE chunk(s)",
                          latency_ms=int((time.monotonic() - t0) * 1000))
    except Exception as exc:
        return TestResult(name="streaming", passed=False, error=str(exc),
                          latency_ms=int((time.monotonic() - t0) * 1000))


# ── Reporting ─────────────────────────────────────────────────────────────────

def _icon(r: TestResult) -> str:
    if r.skipped:
        return ICON_SKIP
    return ICON_PASS if r.passed else ICON_FAIL


def print_result(r: TestResult, verbose: bool = False):
    tok_str = ""
    if r.tokens:
        tok_str = f"  {DIM}tokens={r.tokens.get('total_tokens', '?')}{RESET}"

    print(f"{_icon(r)} {BOLD}{r.name}{RESET}  ({r.latency_ms} ms){tok_str}")

    if r.response and not r.skipped:
        preview = r.response.replace("\n", " ")
        if not verbose and len(preview) > 220:
            preview = preview[:220] + "…"
        print(f"     {CYAN}{preview}{RESET}")

    if r.error:
        colour = DIM if r.skipped else RED
        print(f"     {colour}{r.error}{RESET}")


# ── Main ──────────────────────────────────────────────────────────────────────

SKIP_CHOICES = [
    "text", "reasoning", "code", "math", "multilingual",
    "image", "multi_image", "image_ocr",
    "audio", "video", "streaming", "stock",
]


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Multi-modal LLM capability tester (OpenAI-compatible API)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    ap.add_argument("--host",    default=DEFAULT_HOST,  help="API base URL")
    ap.add_argument("--model",   default=DEFAULT_MODEL, help="Model name to test")
    ap.add_argument("--key",     default="none",        help="API key")
    ap.add_argument("--timeout", default=180, type=int, help="Request timeout (s)")
    ap.add_argument("--image",   default=None,          help="Image file path for vision tests")
    ap.add_argument("--audio",   default=None,          help="Audio file path for audio tests")
    ap.add_argument("--video",   default=None,          help="Video file path for video tests")
    ap.add_argument("--audio-format", default="auto",
                    choices=["auto", "audio_url", "input_audio"],
                    help="Audio content-block format (auto tries audio_url then input_audio)")
    ap.add_argument("--stock",   default="MU",
                    help="Ticker symbol for the stock prediction test")
    ap.add_argument("--skip",    nargs="*", default=[], choices=SKIP_CHOICES,
                    metavar="TEST",  help=f"Tests to skip: {SKIP_CHOICES}")
    ap.add_argument("--only",    nargs="*", default=[], choices=SKIP_CHOICES,
                    metavar="TEST",  help="Run only these tests")
    ap.add_argument("--verbose", "-v", action="store_true", help="Show full model responses")
    ap.add_argument("--json",    action="store_true",       help="Output JSON")
    args = ap.parse_args()

    client = Client(args.host, args.model, args.key, args.timeout)

    if not args.json:
        print(f"\n{BOLD}{CYAN}{'=' * 44}{RESET}")
        print(f"{BOLD}{CYAN}  Multi-Modal LLM Capability Test{RESET}")
        print(f"{BOLD}{CYAN}{'=' * 44}{RESET}")
        print(f"  Host  : {args.host}")
        print(f"  Model : {args.model}")

    # Preflight — check reachability and model availability
    try:
        available = client.list_models()
        if not args.json:
            print(f"  Models: {', '.join(available) or '(none listed)'}")
            if args.model not in available:
                print(f"  {YELLOW}Warning: '{args.model}' not in model list — proceeding anyway{RESET}")
    except Exception as exc:
        msg = f"Cannot reach {args.host}: {exc}"
        if args.json:
            print(json.dumps({"error": msg}))
        else:
            print(f"\n{RED}  {msg}{RESET}\n")
        return 1

    if not args.json:
        print()

    skip = set(args.skip)
    only = set(args.only)

    def should_run(name: str) -> bool:
        if only:
            return name in only
        return name not in skip

    # Build test list
    all_results: list[TestResult] = []

    def maybe_run(name: str, fn):
        if not should_run(name):
            return
        if not args.json:
            print(f"  {DIM}running {name}…{RESET}", end="\r", flush=True)
        result = fn()
        all_results.append(result)
        if not args.json:
            print_result(result, args.verbose)

    maybe_run("text",         lambda: test_text(client))
    maybe_run("reasoning",    lambda: test_reasoning(client))
    maybe_run("math",         lambda: test_math(client))
    maybe_run("code",         lambda: test_code(client))
    maybe_run("multilingual", lambda: test_multilingual(client))
    maybe_run("streaming",    lambda: test_streaming(client))

    # Vision tests
    maybe_run("image",        lambda: test_image(client, args.image))
    maybe_run("multi_image",  lambda: test_multi_image(client))
    maybe_run("image_ocr",    lambda: test_image_ocr(client, args.image))

    # Audio — with optional fallback
    if should_run("audio"):
        if not args.json:
            print(f"  {DIM}running audio…{RESET}", end="\r", flush=True)
        if args.audio_format == "auto":
            results = test_audio_with_fallback(client, args.audio)
        else:
            results = [test_audio(client, args.audio, args.audio_format)]
        for r in results:
            all_results.append(r)
            if not args.json:
                print_result(r, args.verbose)

    # Video
    maybe_run("video", lambda: test_video(client, args.video))

    # Stock prediction
    maybe_run("stock", lambda: test_stock(client, args.stock.upper()))

    # Summary
    passed  = sum(1 for r in all_results if r.passed)
    failed  = sum(1 for r in all_results if not r.passed and not r.skipped)
    skipped = sum(1 for r in all_results if r.skipped)
    total_ms = sum(r.latency_ms for r in all_results)

    if args.json:
        print(json.dumps({
            "model":   args.model,
            "host":    args.host,
            "summary": {"passed": passed, "failed": failed,
                        "skipped": skipped, "total_ms": total_ms},
            "results": [
                {"name": r.name, "passed": r.passed, "skipped": r.skipped,
                 "latency_ms": r.latency_ms, "response": r.response,
                 "error": r.error, "tokens": r.tokens}
                for r in all_results
            ],
        }, indent=2))
    else:
        colour = GREEN if failed == 0 else RED
        print(f"\n{BOLD}Result:{RESET} "
              f"{colour}{passed} passed{RESET}  "
              f"{RED if failed else DIM}{failed} failed{RESET}  "
              f"{DIM}{skipped} skipped{RESET}  "
              f"({total_ms} ms total)\n")

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
