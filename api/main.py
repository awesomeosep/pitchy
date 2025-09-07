from fastapi import FastAPI, File, UploadFile
from fastapi.responses import FileResponse
import os
import shutil
import random

from split_file import run

app = FastAPI()


@app.post("/songs/")
async def root(song_file: UploadFile = File(...)):
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
    run_done = await run(file_ext, file_id)
    print("*** RUN DONE: ", run_done)
    file_path = f"./output/songfile{file_id}/accompaniment.wav"
    return FileResponse(file_path, media_type="audio/wav")
