# Spotlight Wallpapers

DankMaterialShell widget that yoinks Windows Spotlight wallpapers for your desktop.

<img width="521" height="602" alt="1788580228805241104" src="https://github.com/user-attachments/assets/89cf69df-f2b2-424a-be87-745989312302" />

Microsoft has a lovely collection of wallpapers they politely reserve for Windows lock screens. I think they look great on an actual Linux desktop, so this widget politely asks their Spotlight API for the goods and, well... borrows them. (Sorry not sorry, Redmond.)

Click the widget → **Fetch New Wallpaper** → done. Metadata fetched via Qt's built-in `XMLHttpRequest`, image downloaded with `curl`, applied through `SessionData.setWallpaper()`.

Only external dependency: `curl`.
