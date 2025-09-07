from spleeter.separator import Separator
import asyncio


async def splitSong(file_ext: str, file_id: str):
    try:
        separator = Separator('spleeter:2stems', multiprocess=False)
        audio_file = f"./input/songfile{file_id}.{file_ext}"
        output_dir = './output/'
        separator.separate_to_file(audio_file, output_dir)
    except Exception as e:
        print("Error splitting song:")
        print(e)


async def run(file_ext: str, file_id: str):
    task = asyncio.create_task(splitSong(file_ext, file_id))
    await task
    return task.done
