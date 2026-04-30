import io
import os
import subprocess
import tempfile
from pathlib import Path
from flask import Flask, request, jsonify, Response
from PIL import Image, ImageFilter, ImageOps

try:
    from pillow_heif import register_heif_opener
    register_heif_opener()
except ImportError:
    pass

app = Flask(__name__)
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/convert")
def convert():
    if "file" not in request.files:
        return jsonify({"error": "missing 'file' field in form data"}), 400

    pdf_bytes = request.files["file"].read()
    if len(pdf_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "file too large (max 10 MB)"}), 400

    page = request.args.get("page", "1")
    try:
        page_num = int(page)
        if page_num < 1:
            raise ValueError
    except ValueError:
        return jsonify({"error": "invalid 'page' parameter, must be a positive integer"}), 400

    with tempfile.TemporaryDirectory() as tmp:
        pdf_path = Path(tmp) / "input.pdf"
        pdf_path.write_bytes(pdf_bytes)
        out_prefix = str(Path(tmp) / "out")

        result = subprocess.run(
            [
                "pdftoppm", "-jpeg", "-r", "200",
                "-f", str(page_num), "-l", str(page_num),
                str(pdf_path), out_prefix,
            ],
            capture_output=True,
            timeout=30,
        )

        if result.returncode != 0:
            stderr = result.stderr.decode(errors="replace").strip()
            return jsonify({"error": f"conversion failed: {stderr}"}), 400

        output_files = sorted(Path(tmp).glob("out-*.jpg"))
        if not output_files:
            return jsonify({"error": "no output produced — PDF may be empty or encrypted"}), 400

        jpg_bytes = output_files[0].read_bytes()

    return Response(jpg_bytes, mimetype="image/jpeg")


MAX_RESIZE_WIDTH = 1200


@app.post("/resize")
def resize():
    if "file" not in request.files:
        return jsonify({"error": "missing 'file' field in form data"}), 400

    img_bytes = request.files["file"].read()
    if len(img_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "file too large (max 10 MB)"}), 400

    try:
        img = Image.open(io.BytesIO(img_bytes))
        # Hint to JPEG decoder: decode at most 2x the target width to save RAM
        img.draft(None, (MAX_RESIZE_WIDTH * 2, MAX_RESIZE_WIDTH * 2))
        img.load()
    except Exception as e:
        return jsonify({"error": f"could not decode image: {e}"}), 415

    if img.width > MAX_RESIZE_WIDTH:
        new_height = int(img.height * MAX_RESIZE_WIDTH / img.width)
        img = img.resize((MAX_RESIZE_WIDTH, new_height), Image.LANCZOS)

    img = img.convert("RGB").convert("L")
    img = ImageOps.autocontrast(img)
    img = img.filter(ImageFilter.SHARPEN)

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=85, optimize=True)
    return Response(buf.getvalue(), mimetype="image/jpeg")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8000)))
