# LensParser

Based on Brandon Williams' talk on lenses in swift: 
https://www.youtube.com/watch?v=ofjehH9f-CU

parse model tuple such as: 
```swift
typealias AppState = (theme: ColorTheme, font: Font, favoriteFilter: Bool)
```
into lenses:
```swift
let themeLens = Lens<AppState, ColorTheme>(
    get: {$0.theme},
    set: {theme, whole in (theme, whole.font, whole.favoriteFilter)}
)

let fontLens = Lens<AppState, Font>(
    get: {$0.font},
    set: {font, whole in (whole.theme, font, whole.favoriteFilter)}
)

let favoriteFilterLens = Lens<AppState, Bool>(
    get: {$0.favoriteFilter},
    set: {favoriteFilter, whole in (whole.theme, whole.font, favoriteFilter)}
)
```

API 
```swift
main("typealias AppState = (theme: ColorTheme, font: Font, favoriteFilter: Bool)")
```


