# Source Packs

ChimeraCodex now supports external source packs.

This is not a downloaded native code plugin system. A source pack is a folder with:

1. `manifest.json`
2. one or more JSON response files or remote JSON endpoints
3. optional local image files if you want covers or pages to resolve from disk

The engine is built for:

1. JSON APIs
2. local JSON test data
3. simple relative file based packs
4. static request headers and cookies

It is not yet built for:

1. arbitrary HTML scraping
2. JavaScript parser execution
3. remote code loading
4. packaged update feeds

## Where source packs go

After you build and run the app once, ChimeraCodex creates a `SourcePacks` folder inside the app Documents directory.

On a Mac, copy packs in with Finder or iTunes File Sharing:

1. Connect the iPad or iPhone.
2. Open Finder or iTunes.
3. Open the device.
4. Open `Files` or `File Sharing`.
5. Select `ChimeraCodex`.
6. Open the `SourcePacks` area.
7. Copy a full pack folder into it.
8. Return to the app and open the `Sources` tab.
9. Tap `Reload source packs`.
10. Select the new source.

The first launch also seeds a working `SamplePack` folder so you can inspect a real pack immediately.

## Folder layout

Recommended layout:

```text
MySourcePack/
  manifest.json
  catalog.json
  series-a-chapters.json
  series-a-1-pages.json
  covers/
  pages/
```

Each pack should live in its own folder. The loader looks for `manifest.json` inside each source pack folder.

## Manifest format

Top level keys:

1. `formatVersion`
2. `id`
3. `name`
4. `baseURL` optional
5. `defaultHeaders` optional
6. `cookies` optional
7. `catalog`
8. `chapters`
9. `pages`

Each request section supports:

1. `url` or `urlTemplate`
2. `method` optional, default `GET`
3. `headers` optional
4. `itemsKeyPath`
5. `fields`

Supported template tokens:

1. `{baseURL}`
2. `{sourceId}`
3. `{mangaId}`
4. `{mangaName}`
5. `{chapterId}`
6. `{chapterTitle}`
7. `{pageNumber}`

## Minimal example

```json
{
  "formatVersion": 1,
  "id": "pack.template.demo",
  "name": "Template Demo Source",
  "catalog": {
    "url": "./catalog.json",
    "itemsKeyPath": "titles",
    "fields": {
      "id": "id",
      "name": "name",
      "summary": "summary",
      "latestChapterTitle": "latestChapterTitle",
      "chapterCount": "estimatedChapterCount",
      "genres": "genres",
      "status": "status",
      "cover": "cover"
    }
  },
  "chapters": {
    "urlTemplate": "./{mangaId}-chapters.json",
    "itemsKeyPath": "chapters",
    "fields": {
      "id": "id",
      "number": "number",
      "title": "title",
      "pageCount": "pageCountHint",
      "releaseText": "releaseText"
    }
  },
  "pages": {
    "urlTemplate": "./{chapterId}-pages.json",
    "itemsKeyPath": "pages",
    "fields": {
      "number": "pageNumber",
      "imageURL": "imageURL",
      "headline": "headline",
      "bodyText": "bodyText"
    }
  }
}
```

## Field mapping

Catalog fields:

1. `id`
2. `name`
3. `summary`
4. `latestChapterTitle`
5. `chapterCount`
6. `genres`
7. `status`
8. `cover`

Chapter fields:

1. `id`
2. `number`
3. `title`
4. `pageCount`
5. `releaseText`

Page fields:

1. `number`
2. `imageURL`
3. `headline`
4. `bodyText`

`genres` can be a string or an array of strings.

`status` can be:

1. `ongoing`
2. `complete`
3. `finished`
4. `hiatus`
5. a matching numeric enum value

## Relative paths

If `baseURL` is not set, relative paths resolve from the source pack folder.

Examples:

1. `./catalog.json`
2. `./covers/series-a.png`
3. `./pages/series-a-1-01.jpg`

If `baseURL` is set, relative values resolve against that URL instead.

Examples:

1. `"/api/catalog"`
2. `"images/cover.jpg"`
3. `"/api/chapters/{chapterId}/pages"`

## Headers and cookies

`defaultHeaders` are applied to JSON requests. Section `headers` merge on top of them.

Example:

```json
{
  "defaultHeaders": {
    "User-Agent": "ChimeraCodex/1.0",
    "Referer": "{baseURL}"
  },
  "cookies": [
    {
      "name": "session",
      "value": "example",
      "domain": "example.com",
      "path": "/",
      "expiresInSeconds": 86400
    }
  ]
}
```

## Building a new pack

1. Copy the `SourcePacks/TemplatePack` folder from this repo.
2. Rename the folder.
3. Change `id` so it is unique.
4. Change `name`.
5. Point `catalog.url` or `catalog.urlTemplate` at your source.
6. Map the catalog fields to the JSON keys that source returns.
7. Do the same for `chapters`.
8. Do the same for `pages`.
9. Add any required headers or cookies.
10. Copy the pack folder into ChimeraCodex `SourcePacks`.
11. Open `Sources` in the app.
12. Tap `Reload source packs`.
13. Select the source.
14. Test Catalog, detail, and reader.

## Testing locally before using a real site

Start with local JSON files in the pack folder.

This lets you confirm:

1. the manifest is valid
2. field mapping is correct
3. chapter resolution works
4. page resolution works
5. covers and page fallbacks behave correctly

After that, switch the manifest URLs over to the real JSON endpoints.

## Current limits

Current source packs are intentionally simple.

They do not yet provide:

1. HTML selector parsing
2. regex transforms
3. multi page catalog crawling
4. authenticated login flows beyond static cookies
5. source specific settings screens

If you want the next step after this, the best expansion is an HTML parser layer with selector based extraction in the source pack format.
