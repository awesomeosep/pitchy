# pitchy

[![Athena Award Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Faward.athena.hackclub.com%2Fapi%2Fbadge)](https://award.athena.hackclub.com?utm_source=readme)

🎤 A mobile app to remove vocals and adjust your favorite songs to your voice for the perfect karaoke night!

## 🚀 Usage
To download the pitchy app for Android, go to the releases section and download the latest release.

## ✨ Inspiration
I came up with the idea for this app because I have a relatively low voice, and I can't hit the high notes on some of my favorite songs. I needed a solution to adjust the key to songs when I want to sing along to them! So I searched and found the [spleeter API](https://github.com/deezer/spleeter), and decided to make a Flutter mobile app that would allow me to adjust songs to *my* voice and make it possible for me to sing them, without sounding too pitchy!

## 🎶 Features

- Upload a song, and split it into vocals and accompaniment
- Save split songs to the app, and play both vocals and accompaniment tracks
- Create playlists
- Adjust and save features of the song, like volume and pitch
- Play a playlist from start to finish, with a queue feature

## ⚙️ Tech Stack
I made this app using Flutter and Material Design for the frontend, and a Python FastAPI server hosted on HackClub Nest.

When I started working on this project, I had gotten pretty used to Flutter, but creating the backend with FastAPI was very new. There was a lot of trial and error in getting spleeter, a Python package that splits vocals from an audio track, working, as well as sending and receiving files from the API. Also, I had never used a server like Nest, so learning how to host a FastAPI on it was a bit of a struggle, but definitely worthwhile!

## ▶️ Development
To test this project on your own device, run:
```bash
flutter pub get
flutter run
```

## 📃 TODO Features:
- Add [more audio adjustments](https://pub.dev/packages/flutter_soloud), like echo and reverb
- Reorder playlsits & queues
- Swipe to refresh
- Dark mode
- Song "groups" (by artist, genre, etc)
- Lyrics
- Increase song splitting time? 😬