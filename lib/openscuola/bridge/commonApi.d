module openscuola.bridge.commonApi;

enum URL {
    ROOT = "https://app.scuolabook.it",
    STORE = ROOT ~ "/store/public",
    CONTENT = ROOT ~ "/content/public",

    LOGIN = STORE ~ "/login",
    HISTORY = STORE ~ "/getHistory",
    SESSION_ACTIVE = STORE ~ "/isSessionActive",
    BOOK_URL = CONTENT ~ "/distributors/scuolabook/drm/drm_pdf/items"
}

enum API {
    HISTORY = URL.HISTORY ~
        "?sessionId=%s" ~
        "&deviceToken=%s" ~
        "&osAPI=" ~
        Device.OSAPI ~
        "&osVersion=" ~
        Device.OSVERSION ~
        "&appVersion=" ~
        Device.APPVERSION ~
        "&model=" ~
        Device.MODEL ~
        "&memClass=" ~
        Device.MEMCLASS ~
        "&memMax=" ~
        Device.MEMMAX ~
        "&sdCard=" ~
        Device.SDCARD ~
        "&screenSize=" ~
        Device.SCREENSIZE ~
        "&screenDPI=" ~
        Device.SCREENDPI ~
        "&plat=" ~
        Device.PLAT,

    SESSION_ACTIVE = URL.SESSION_ACTIVE ~
        "?sessionid=%s" ~
        "&email=%s",

    DOWNLOADBOOK = "%s" ~
        "?user_name=%s" ~
        "&device_token=%s",

    BOOKURL = URL.BOOK_URL ~
        "/%s" ~ "/download"
}

// Default device information
enum Device : string {
    OSAPI = "Linux",
    OSVERSION = "Linux",
    APPVERSION = "3.3.0",
    MODEL = "desktop",
    MEMCLASS = "NA",
    MEMMAX = "NA",
    SDCARD = "false",
    SCREENSIZE = "NA",
    SCREENDPI = "NA",
    PLAT = "desktop"
}
