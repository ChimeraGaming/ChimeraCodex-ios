<p align="center">
  <img src="Images/Logo.png" alt="ChimeraCodex logo" width="720">
</p>
<h1 align="center">ChimeraCodex</h1>
<p align="center">Small UIKit manga reader starter project for older iPad hardware, especially iPad mini 2 class devices.</p>

ChimeraCodex uses Objective C, UIKit, `NSUserDefaults`, and a very small app structure so the project stays easy to copy, open, build, and extend.

The current repo is self contained. A fresh clone includes:

- a shared Xcode scheme
- a standard `.xcodeproj` layout
- a library tab
- a catalog tab
- a sources tab
- a manga detail screen
- a configurable reader
- a source adapter behind `IRSourceProtocol`
- external JSON source pack support
- remote image loading with request headers and cookies
- memory and disk image cache with cleanup rules
- saved reading progress and resume state
- search, sort, and filters in the main lists
- retry states for catalog, library, chapters, and pages

## Quick start

1. Copy or clone this repo to a Mac.
2. Open [ChimeraCodex.xcodeproj](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex.xcodeproj) in Xcode.
3. Wait for Xcode to finish indexing.
4. In the scheme picker, make sure `ChimeraCodex` is selected.
5. Choose an iPad simulator.
6. Press `Cmd + R`.

If everything is set up correctly, the app should open with three tabs named `Library`, `Catalog`, and `Sources`.

If the Mac or device is offline, the reader can still open and will fall back to locally rendered sample pages when a remote placeholder image cannot be fetched.

## Requirements

1. A Mac with Xcode installed.
2. An Xcode version that still allows the deployment target you want to use.
3. For real device builds, an Apple ID added to Xcode.

This repo is configured with `IPHONEOS_DEPLOYMENT_TARGET = 9.0` in the project file. Some newer Xcode versions may refuse to keep that target. If that happens, open the project on a Mac and test the deployment target immediately before doing other work.

## Source Flow

The app now uses a small reader adapter flow that is closer to extension based readers:

1. `fetchCatalogWithCompletion` returns title metadata.
2. `fetchChaptersForManga` resolves the chapter list when a title is opened.
3. `fetchPagesForManga` resolves the page list when a chapter is opened.
4. The source can provide request headers and cookies for covers and pages.
5. `IRRemoteImageLoader` fetches images through `NSURLSession`, supports cancelation, and prefetches upcoming pages.
6. `IRRemoteImageCache` stores scaled images in memory and on disk, expires old files, and trims disk usage.
7. `IRSourceRegistry` loads a built in source plus external source packs from the app Documents `SourcePacks` folder.
8. `IRJSONSource` resolves source packs that point at local JSON files or remote JSON endpoints.

The bundled demo adapter still uses sample content, but it now exercises the same boundaries you would use for a real site source.

## Current Features

1. Catalog covers loaded through the same remote image path as reader pages.
2. Library covers and saved title management.
3. Title search in Catalog and Library.
4. Catalog filters for active and complete series.
5. Catalog sorting by title, chapter count, and latest chapter label.
6. Library filters for reading and finished titles.
7. Library sorting by recent activity, title, and progress ratio.
8. Reading progress saved per manga and chapter.
9. Resume reading from the manga detail screen.
10. Reader options for fit width, fit height, page gap, reading order, and brightness lock.
11. Page request cancelation, two page prefetching, and a low concurrency network cap for older hardware.
12. Offline fallback page rendering when a remote page image fails.
13. Runtime source selection from the `Sources` tab.
14. File Sharing based source pack import for external extensions.

## Build on Simulator

1. Open the project.
2. Select the `ChimeraCodex` scheme.
3. Pick any iPad simulator that your Xcode install provides.
4. Press `Cmd + B` to build.
5. Press `Cmd + R` to run.

You do not need signing changes for the simulator.

## Build on a Real iPad

1. Connect the iPad to the Mac.
2. Open the project in Xcode.
3. Click the blue project icon named `ChimeraCodex`.
4. Select the `ChimeraCodex` target.
5. Open the `Signing & Capabilities` tab.
6. Set `Team` to your personal or paid Apple developer team.
7. Change the bundle identifier from `com.example.ChimeraCodex` to something unique, such as `com.yourname.ChimeraCodex`.
8. Confirm the deployment target is still `9.0`.
9. Select the connected iPad as the run destination.
10. Press `Cmd + R`.

If Xcode says the device is not ready:

1. Unlock the iPad.
2. Tap `Trust` if prompted.
3. In Xcode, open `Window`, `Devices and Simulators`, and confirm the iPad is listed.
4. Try the run again.

## Command Line Build

You can also build from Terminal on a Mac after opening the project once in Xcode.

Simulator build:

```sh
xcodebuild \
  -project ChimeraCodex.xcodeproj \
  -scheme ChimeraCodex \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Device build:

```sh
xcodebuild \
  -project ChimeraCodex.xcodeproj \
  -scheme ChimeraCodex \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  build
```

If the device build fails for signing, fix `Team` and `PRODUCT_BUNDLE_IDENTIFIER` in Xcode first.

## Repo Layout

- [AppDelegate.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/AppDelegate.m) boots the app and creates the dependency container.
- [Assets.xcassets](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Assets.xcassets) contains the app icon set and launch branding assets.
- [IRAppContainer.h](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/IRAppContainer.h) wires shared services together.
- [IRSourceProtocol.h](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Services/IRSourceProtocol.h) defines the source interface.
- [IRStaticSource.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Services/IRStaticSource.m) provides sample catalog data.
- [IRSourceRegistry.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Services/IRSourceRegistry.m) discovers source packs and seeds the first sample pack.
- [IRJSONSource.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Services/IRJSONSource.m) resolves extension style JSON source packs.
- [IRRemoteImageLoader.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Services/IRRemoteImageLoader.m) downloads and scales page images.
- [IRRemoteImageCache.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Services/IRRemoteImageCache.m) keeps scaled page images in memory and on disk.
- [IRLibraryStore.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Services/IRLibraryStore.m) saves the library list in `NSUserDefaults`.
- [IRReadingProgress.h](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Models/IRReadingProgress.h) defines persisted progress state.
- [IRReaderSettings.h](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Models/IRReaderSettings.h) defines persisted reader options.
- [IRMangaTableViewCell.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Controllers/IRMangaTableViewCell.m) renders cover based list rows for Catalog and Library.
- [IRCatalogViewController.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Controllers/IRCatalogViewController.m) renders the catalog list.
- [IRLibraryViewController.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Controllers/IRLibraryViewController.m) renders saved titles.
- [IRSourcesViewController.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Controllers/IRSourcesViewController.m) lets the user reload and switch source packs.
- [IRMangaDetailViewController.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Controllers/IRMangaDetailViewController.m) shows the manga summary and chapters.
- [IRReaderViewController.m](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/ChimeraCodex/Controllers/IRReaderViewController.m) renders the chapter pages.
- [EXTENSIONS.md](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/EXTENSIONS.md) explains how to create and import external source packs.

## First Things To Change

1. Read [EXTENSIONS.md](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/EXTENSIONS.md) and copy `SourcePacks/TemplatePack` to start a new pack.
2. Point the manifest at the JSON endpoints used by the site you want.
3. Add source specific parsing, login, and cookie refresh rules if those endpoints need them.
4. Add per chapter page limits and stronger request throttling for older devices.
5. Add narrow App Transport Security exceptions only if a target source truly needs them.
6. Replace the sample bundle identifier with your own permanent identifier.

## Troubleshooting

### The project opens but will not run

Check the scheme first. This repo includes a shared scheme at `ChimeraCodex.xcodeproj/xcshareddata/xcschemes/ChimeraCodex.xcscheme`, so `ChimeraCodex` should already appear in Xcode.

### Xcode changes the deployment target

Open the project target settings and verify `iOS Deployment Target`. If Xcode will not allow `9.0`, you will need a Mac and Xcode combination that still supports building for that target.

### The app builds on simulator but not on device

That is usually a signing issue. Set a valid `Team`, choose a unique bundle identifier, then build again.

### The app runs but only shows sample content

That is expected. The repo ships with a built in sample source and seeds a sample external source pack. Read [EXTENSIONS.md](/C:/Users/97Tur/OneDrive/Documents/GitHub/iOS%20Reader%20App/EXTENSIONS.md) to point a new pack at your own JSON endpoints.
