module openscuola.bridge.downloadbook;
import openscuola.bridge.login : LoginResponse, c_LoginResponse;

extern(C) struct c_BookFile {
    bool result;
    const char* md5;
    size_t downloadSize;
    ubyte* fileData;
}

extern(C) c_BookFile* c_downloadBook(const char* loginToken, const char* hardwareId, const char* bookUrl) {
    import std.string : toStringz, fromStringz;

    auto response = downloadBook(loginToken.fromStringz.idup, hardwareId.fromStringz.idup, bookUrl.fromStringz.idup);
    return new c_BookFile(
        response.result,
        response.md5.toStringz,
        response.downloadSize,
        response.fileData.ptr
    );
}

extern(C) c_BookFile* c_downloadBookFromId(const char* loginToken, const char* hardwareId, const char* bookId) {
    import std.string : toStringz, fromStringz;

    auto response = downloadBookFromId(loginToken.fromStringz.idup, hardwareId.fromStringz.idup, bookId.fromStringz.idup);
    return new c_BookFile(
        response.result,
        response.md5.toStringz,
        response.downloadSize,
        response.fileData.ptr
    );
}

extern(C) c_BookFile* c_downloadImageFromId(const char* loginToken, const char* hardwareId, const char* bookId, bool is700) {
    import std.string : toStringz, fromStringz;

    auto response = downloadImageFromId(loginToken.fromStringz.idup, hardwareId.fromStringz.idup, bookId.fromStringz.idup, is700);
    return new c_BookFile(
        response.result,
        response.md5.toStringz,
        response.downloadSize,
        response.fileData.ptr
    );
}

struct BookFile {
    bool result;
    string md5;
    size_t downloadSize;
    ubyte[] fileData;
}

BookFile downloadBook(string loginToken, string hardwareId, string bookUrl) {
    import openscuola.bridge.commonApi : API;
    import openscuola.bridge.deviceId : getDeviceId;
    import openscuola.bridge.drm : removeDrm, computePdfMagic;
    import std.conv : to;
    import std.format : format;
    import openscuola.bridge.util : httpGet, getUsernameLoginToken, getSessionIdLoginToken;
    import dxml.dom : parseDOM;
    import std.digest.md : md5Of;
    import std.digest : toHexString;
    import std.stdio : writeln;

    BookFile bookFile;
    string activationKey;
    string downloadUrl;
    auto username = getUsernameLoginToken(loginToken);
    auto sessionId = getSessionIdLoginToken(loginToken);
    auto deviceId = getDeviceId(hardwareId);

    if (username.length <=1 && sessionId.length <= 1 && deviceId.length <= 1 && bookUrl.length <= 1) {
        return bookFile;
    }

    auto url = format(
        API.DOWNLOADBOOK,
        bookUrl,
        sessionId,
        deviceId,
    );
    
    int errorCode;
    auto content = httpGet!string(url, errorCode);
    
    if (errorCode == -1) {
        writeln("Error: HTTP Connection failed! Check your Internet access.");
        return bookFile;
    }
    
    if (errorCode != 200) {
        writeln("Error: Failed to get the book download link!");
    	return bookFile;
    }
    
    auto dom = parseDOM(content);

    if (dom.children.length != 1) {
        return bookFile;
    }

    auto result = dom.children[0];

    foreach(child; result.children) {
        if (child.attributes.length != 0) {
            return bookFile;
        }

        switch (child.name) {
            case "downloadURL" : {
                if (child.children.length != 1) {
                    return bookFile;
                }

                downloadUrl = child.children[0].text;
                break;
            }

            case "activationKey" : {
                if (child.children.length != 1) {
                    return bookFile;
                }

                activationKey = child.children[0].text;
                break;
            }

            default:
        }
    }
    
    bookFile.fileData = httpGet(downloadUrl, errorCode);
    
    if (errorCode == -1) {
        writeln("Error: HTTP Connection failed! Check your Internet access.");
        return bookFile;
    }
    
    if (errorCode != 200) {
        writeln("Error: Failed to download the book!");
    	return bookFile;
    }
    
    auto magic = computePdfMagic(bookFile.fileData, username, hardwareId, activationKey);
    removeDrm(magic, bookFile.fileData);
    bookFile.downloadSize = bookFile.fileData.length;
    bookFile.md5 = bookFile.fileData.md5Of().toHexString.dup;
    bookFile.result = true;
    return bookFile;
}

BookFile downloadBookFromId(string loginToken, string hardwareId, string bookId) {
    import openscuola.bridge.commonApi : API;
    import std.format : format;

    BookFile bookFile;

    if (bookId.length <=1) {
        return bookFile;
    }

    auto bookUrl = format(
        API.BOOKURL,
        bookId,
    );

    bookFile = downloadBook(loginToken, hardwareId, bookUrl);
    return bookFile;
}

BookFile downloadImageFromId(string loginToken, string hardwareId, string bookId, bool is700) {
    import openscuola.bridge.history : bookHistory, HISTORY_ERROR;
    import openscuola.bridge.util : httpGet;
    import std.format : format;
    import std.stdio : writeln;
    import std.digest.md : md5Of;
    import std.digest : toHexString;

    BookFile bookImageFile;
    int errorCode;
    int historyErrorCode;
    auto historyResponse = bookHistory(loginToken, hardwareId, historyErrorCode);

    if (historyErrorCode != HISTORY_ERROR.SUCCESS) {
        writeln("Error: Failed to get image url!");
        return bookImageFile;
    }

    foreach (book; historyResponse) {
        if (book.bookId != bookId) {
            continue;
        }

        string imageUrl;

        if (is700) {
            imageUrl = book.image700;
        } else {
            imageUrl = book.image;
        }

        bookImageFile.fileData = httpGet(imageUrl, errorCode);
    
        if (errorCode == -1) {
            writeln("Error: HTTP Connection failed! Check your Internet access.");
            return bookImageFile;
        }
    
        if (errorCode != 200) {
            writeln("Error: Failed to download the book!");
    	    return bookImageFile;
        }

        bookImageFile.downloadSize = bookImageFile.fileData.length;
        bookImageFile.md5 = bookImageFile.fileData.md5Of().toHexString.dup;
        bookImageFile.result = true;
        return bookImageFile;
    }

    writeln("Error: Book ID not found!");
    return bookImageFile;
}
