# Freya Player

<p align="center"><img src="assets/screenshots/repo.png" alt="Freya Player screenshot"></p>

Freya Player is a native player for Apple TV, iPhone, iPad, and Mac that streams movies and shows from your own Jellyfin or Plex server. It does not provide any content; you need a server of your own, or access to one.

Learn more at [freyaplayer.com](https://freyaplayer.com).

## Install

<a href="https://apps.apple.com/us/app/freya-player/id6761883699"><img src="https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us?releaseDate=1700000000" alt="Download on the App Store" height="40"></a>

On a Mac, you can also install with Homebrew:

```sh
brew install grahamotte/tap/freya-player
```

Signed, notarized Mac builds are also attached to each [GitHub Release](https://github.com/grahamotte/FreyaPlayer/releases).

## Using Freya Player

### Connecting a server

On first launch, choose **Jellyfin** or **Plex**.

- **Jellyfin:** Choose HTTPS or HTTP, enter your server's address and port (443 for HTTPS and 8096 for HTTP by default), then your username and password, and choose **Connect**.
- **Plex:** Freya Player first explains that Plex sign-in and server discovery go through plex.tv. Choose **I Understand, Continue**, then **Connect With Plex**, and enter the code shown at [plex.tv/link](https://plex.tv/link) in a browser. Freya Player connects to a server on your Plex account, preferring one you own.

Freya Player remembers the connection and reconnects on the next launch. If the saved server can't be reached, you can **Retry** or **Deactivate** it.

### Home

Home shows a row for each of your server's libraries. Choose a library's title, or the first tile in its row, to open the whole library. Search finds titles across all of your shown libraries, even with a typo or a partial title.

Your libraries are kept on the device so Home opens quickly, and they refresh in the background. You can also refresh by hand with **Refresh**, in the **More** menu on iPhone, iPad, and Mac or on Home on Apple TV. On iPhone and iPad you can also pull down to refresh. While you're offline you can still browse, but playing and marking items need a connection.

### Libraries

- **Filter** shows **All** items or only **Unseen** ones. Libraries start on **Unseen**.
- **Sort** orders by **Title**, **Date Added**, or **Duration**, ascending or descending. Libraries start sorted by newest added. Home rows follow each library's filter and sort.
- **Play All** plays everything currently shown, **In Order** or **Shuffle**.

### Movies and shows

An item's page shows its artwork, title, a summary line, its description, and how much is left if you've started it. **Details** shows the full description, artwork, and metadata from your server.

- **Play** starts from the beginning, or shows **Resume at** with the time you left off.
- A series page lists its seasons, and a season page lists its episodes. Both have **Play All** with **In Order** and **Shuffle**.
- The watch status button shows **Seen**, **Unseen**, or how far along you are, and lets you **Mark Seen** or **Mark Unseen**. On a series or season, this marks every episode in it.
- For quick actions on any poster, touch and hold it on iPhone and iPad, right-click it on Mac, or press and hold on Apple TV. You can play, resume, **Mark Seen**, or **Mark Unseen** without opening the item.

Your progress and watched status are saved to your server, so they stay in sync with your other Jellyfin or Plex apps.

### Playback

Video plays in the standard Apple player, including Picture in Picture on iPhone and iPad.

Choose **Play Options** (the slider button next to Play, or press and hold Play) to pick the resolution, audio track, and subtitles before playing. Resolution defaults to the original; choosing 1080p, 720p, 480p, or 240p asks the server for a smaller stream, which helps on slow connections. Play Options also shows the container, video, audio, and subtitles for the selected choices, and whether each plays as-is (**Direct Play**), is repackaged by the server (**Remux**), or is converted by the server (**Transcode**). Freya Player remembers your choices for that item.

### Managing your server

Open **Manage** from the **More** menu on iPhone, iPad, and Mac, or from the buttons on Home on Apple TV.

- **Server** shows the server's name, address, and provider. **Deactivate Server…** removes the server and all Freya Player data from the device.
- **Cache** shows how much space saved library data uses. **Clear Cache** removes it.
- **Libraries** lets you hide libraries from Home and reorder them. Drag to reorder on iPhone, iPad, and Mac, or use the up and down buttons on Apple TV.
- **Playback Capabilities** lists the containers, video formats, dynamic ranges (such as HDR), audio formats, and subtitle formats your device can play without the server converting them.

### Privacy

Freya Player is free, with no subscriptions, ads, analytics, telemetry, or crash reporting. Your data stays on your device and is sent only to your server. With Plex, sign-in and server discovery also go through plex.tv.

## Contributing

Issues welcome.

## License

[MIT](LICENSE)
