# tvOS AAC Audio Fallback

On tvOS 27 and later, Freya Player converts every audio track to AAC on the server. This is a workaround for a platform bug, not a capability limit. Remove or narrow it only with evidence that native audio is stable.

## The Problem

On Apple TV with HomePods as the audio output, native audio drops out or mutes during playback. The original tvOS 27 report was a full dropout. Later reports describe audio muting after about 30 seconds, which is less severe but still present.

## The Workaround

`PlaybackCompatibility.requiresTranscodedAudio(majorVersion:)` returns true for tvOS major version 27 or higher, and false on every other platform. `PlatformMetadata.requiresTranscodedPlaybackAudio` exposes it to the connectors. When it is true:

- Plex and Jellyfin disable direct play and audio stream copying.
- The server converts audio to AAC.
- Compatible video stays native. Subtitles are never burned in.

The fallback applies to the whole platform, not only HomePod routes.

## History

- August 11, 2026: the fallback was added for the tvOS 27 HomePod dropout.
- September 9, 2026: it was kept active across every tvOS 27 release, matching only `majorVersion == 27`.
- October 2, 2026 (UTC): FP-6 removed the fallback, expecting the platform bug to be fixed.
- October 5, 2026: FP-26 restored it for tvOS 27 and later after users reported muting on HomePods.
- October 5, 2026: an investigation found no verified app-side fix.
  - Apple's tvOS 27 and HomePod update notes do not identify this dropout as fixed.
  - The tvOS 27.2 release-note page had no substantive notes, so beta status was unverified.
  - Rogue Amoeba's Airfoil 5.13 workaround addresses failed AirPlay 1 connections, not AVPlayer playback.
  - `AVPlayer.audioOutputSuppressedDueToNonMixableAudioRoute` documents routing arbitration, but no captured suppression observation ties it to this incident.
- FP-27 deferred the recheck indefinitely and recorded this document.

## Rechecking

The fallback costs audio quality and server conversion work, so recheck it when a new tvOS or HomePod release looks relevant.

1. Read Apple's tvOS and HomePod release notes and developer guidance for a fix.
2. Record the Apple TV and HomePod models, OS versions and builds, provider, source audio codec and channels, and playback path.
3. On a physical Apple TV with HomePods, test Plex and Jellyfin with AAC, AC-3, and E-AC-3, through direct play and HLS. Play at least 10 minutes, and cover pause and resume, seeking, and next episode. Compare against HDMI output, and against the fallback enabled and disabled.
4. If needed, capture AVPlayer route and suppression diagnostics to tell a platform output failure apart from routing arbitration.
5. Retire or narrow the fallback only with evidence of stable native audio. Do not remove it just because devices are up to date. Keep supported video native and never burn in subtitles.

## References

- [HomePod software updates](https://support.apple.com/en-us/106336)
- [Apple TV software updates](https://support.apple.com/en-mn/108045)
- [tvOS 27 release notes](https://developer.apple.com/documentation/tvos-release-notes/tvos-27-release-notes)
- [tvOS 27.2 release notes](https://developer.apple.com/documentation/tvos-release-notes/tvos-27_2-release-notes)
- [Rogue Amoeba: Airfoil and OS 27 issues](https://rogueamoeba.com/support/knowledgebase/?showArticle=Airfoil-OS27-Issues)
- [`audioOutputSuppressedDueToNonMixableAudioRoute`](https://developer.apple.com/documentation/avfoundation/avplayer/audiooutputsuppressedduetononmixableaudioroute)
