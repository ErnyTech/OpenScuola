module openscuola.bridge.history;
import openscuola.bridge.login : LoginResponse, c_LoginResponse;

enum HISTORY_ERROR {
    SUCCESS = 0,
    MAX_DEVICE = 412
}

extern(C) struct c_Book {
    int versionBook;
    const(char)* lastModificationDate;
    const(char)* bookId;
    const(char)* title;
    const(char)* subTitle;
    const(char)* author;
    const(char)* publisher;
    const(char)* image;
    const(char)* image700;
    const(char)* isbn;
    double price;
    const(char)* fileFormat;
    int numPages;
    const(char)* bookFileURL;
    long bookFileSize;
    const(char)* bookMd5;
}

extern(C) size_t c_bookHistory(const char* loginToken, const char* hardwareId, ref c_Book* booksOut, ref int errorCode) {
    import std.string : toStringz, fromStringz;

    c_Book[] books;
    auto response = bookHistory(loginToken.fromStringz.idup, hardwareId.fromStringz.idup, errorCode);

    foreach (i, elem; response) {
        books ~= c_Book(
            elem.versionBook,
            elem.lastModificationDate.toStringz,
            elem.bookId.toStringz,
            elem.title.toStringz,
            elem.subTitle.toStringz,
            elem.author.toStringz,
            elem.publisher.toStringz,
            elem.image.toStringz,
            elem.image700.toStringz,
            elem.isbn.toStringz,
            elem.price,
            elem.fileFormat.toStringz,
            elem.numPages,
            elem.bookFileURL.toStringz,
            elem.bookFileSize,
            elem.bookMd5.toStringz
        );
    }

    booksOut = new c_Book[books.length].ptr;

    foreach (i, elem; books) {
        booksOut[i] = elem;
    }

    return books.length;
}

struct Book {
    int versionBook;
    string lastModificationDate;
    string bookId;
    string title;
    string subTitle;
    string author;
    string publisher;
    string image;
    string image700;
    string isbn;
    double price;
    string fileFormat;
    int numPages;
    string bookFileURL;
    long bookFileSize;
    string bookMd5;
}

Book[] bookHistory(string loginToken, string hardwareId, ref int errorCode) {
    import openscuola.bridge.commonApi : API;
    import openscuola.bridge.deviceId : getDeviceId;
    import std.conv : to;
    import std.format : format;
    import openscuola.bridge.util : httpGet, getSessionIdLoginToken;
    import dxml.dom : parseDOM;
    import std.stdio;
        
    Book[] books;
    auto sessionId = getSessionIdLoginToken(loginToken);
    auto deviceId = getDeviceId(hardwareId);
        
    if (sessionId.length <= 1 || deviceId.length <= 1) {
        return books;
    }
        
    auto url = format(
        API.HISTORY,
        sessionId,
        deviceId
    );
    
    auto content = httpGet!string(url, errorCode);
    
    if (errorCode == -1) {
    	writeln("Error: HTTP Connection failed! Check your Internet access.");
        return books;
    }
    
    if (errorCode != 200) {
    	return books;
    }
    
    auto dom = parseDOM(content);
        
    if (dom.children.length != 1) {
        return books;
    }
        
    auto result = dom.children[0];
        
    foreach(child; result.children) {
        if (child.attributes.length == 1 && child.attributes[0].value == "errorCode") {
            if (child.children.length != 1) {
                return books;
            }
                    
            errorCode = to!int(child.children[0].text);
                    
            if (errorCode != 0) {
                return books;
            }
        }
            
        if (child.attributes.length == 0 && child.name == "book") {
            auto bookXml = child.children;
                
            Book book;
                
            foreach(bookData; bookXml) {
                if (bookData.attributes.length > 3) {
                    continue;
                }
                    
                switch (bookData.attributes[0].value) {
                    case "version" : {
                        if (bookData.children.length != 1) {
                            continue;
                        }
                    
                        book.versionBook = to!int(bookData.children[0].text);
                        break;
                    }
                        
                    case "lastModificationDate" : {
                        if (bookData.children.length != 1) {
                            break;
                        }
                    
                        book.lastModificationDate = bookData.children[0].text;
                        break;
                    }
                        
                    case "bookId" : {
                        if (bookData.children.length != 1) {
                            continue;
                        }
                    
                        book.bookId = bookData.children[0].text;
                        break;
                    }
                        
                    case "title" : {
                        if (bookData.children.length != 1) {
                            continue;
                        }
                    
                        book.title = bookData.children[0].text;
                        break;
                    }
                        
                    case "subtitle" : {
                        if (bookData.children.length != 1) {
                            break;
                        }
                    
                        book.subTitle = bookData.children[0].text;
                        break;
                    }
                        
                    case "author" : {
                        if (bookData.children.length != 1) {
                            break;
                        }
                    
                        book.author = bookData.children[0].text;
                        break;
                    }
                        
                    case "publisher" : {
                        if (bookData.children.length != 1) {
                            break;
                        }
                    
                        book.publisher = bookData.children[0].text;
                        break;
                    }
                        
                    case "image" : {
                        if (bookData.children.length != 1) {
                            continue;
                        }
                    
                        book.image = bookData.children[0].text;
                        break;
                    }
                        
                    case "image700" : {
                        if (bookData.children.length != 1) {
                            continue;
                        }
                    
                        book.image700 = bookData.children[0].text;
                        break;
                    }
                        
                    case "isbn" : {
                        if (bookData.children.length != 1) {
                            break;
                        }
                    
                        book.isbn = bookData.children[0].text;
                        break;
                    }
                        
                    case "price" : {
                        if (bookData.children.length != 1) {
                            break;
                        }
                    
                        book.price = to!double(bookData.children[0].text);
                        break;
                    }
                        
                    case "fileFormat" : {
                        if (bookData.children.length != 1) {
                            continue;
                        }
                    
                        book.fileFormat = bookData.children[0].text;
                        break;
                    }
                        
                    case "numPages" : {
                        if (bookData.children.length != 1) {
                            break;
                        }
                    
                        book.numPages = to!int(bookData.children[0].text);
                        break;
                    }
                        
                    case "bookFileURL" : {
                        if (bookData.children.length != 1) {
                            continue;
                        }
                    
                        book.bookFileURL = bookData.children[0].text;
                        book.bookFileSize = to!long(bookData.attributes[1].value);
                        book.bookMd5 = bookData.attributes[2].value;
                        break;
                    }
                        
                    default:
                }
            }
                
            books ~= book;
        }
    }
        
    return books;
}

