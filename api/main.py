from fastapi import FastAPI, File, UploadFile
from fastapi.responses import FileResponse
import os
import shutil
import random
import zipfile

from split_file import run

app = FastAPI()


def zip_folder(folder_path, output_zip_path):
    with zipfile.ZipFile(output_zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(folder_path):
            for file in files:
                file_path = os.path.join(root, file)
                # Calculate the relative path within the zip archive
                arcname = os.path.relpath(file_path, folder_path)
                zipf.write(file_path, arcname=arcname)
    print(f"Folder '{folder_path}' successfully zipped to '{output_zip_path}'")


@app.post("/songs/")
async def root(song_file: UploadFile = File(...), split_type: str = "2stems"):
    # Clean up past files
    # if os.path.exists("./input"):
    #     shutil.rmtree("./input")

    # if not os.path.exists("./input"):
    #     os.makedirs("./input")

    # if os.path.exists("./output"):
    #     shutil.rmtree("./output")

    # if not os.path.exists("./output"):
    #     os.makedirs("./output")

    # Process request file
    print("got request")

    file_ext = song_file.filename.split(".")[-1]
    file_id = random.randint(1, 10000)
    file_location = os.path.join(
        "./input", f"songfile{file_id}.{file_ext}")

    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(song_file.file, buffer)

    # Send file to split & return
    run_done = await run(file_ext, file_id, split_type)
    print("*** RUN DONE: ", run_done)
    file_path = f"./output/songfile{file_id}_zip.zip"
    zip_folder(f"./output/songfile{file_id}/", file_path)
    print("*** ZIPPED FILE")
    return FileResponse(file_path, media_type="application/zip")
