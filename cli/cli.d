import openscuola.bridge.deviceId : generateRandomHardwareId, getHardwareIdInterface, getHardwareId;
import openscuola.bridge.login : login, isSessionActive, LoginResponse;
import openscuola.bridge.history : bookHistory, Book, HISTORY_ERROR;
import openscuola.bridge.downloadbook : downloadBook;
import std.stdio : write, writeln, stdin;
import std.string : strip, isNumeric;
import std.conv : to;

version (linux)
    version = Support_Interface_Mac;
else version (OSX)
    version = Support_Interface_Mac;

void main() {
    writeln();
    writeln("Welcome to OpenScuola CLI!");
    writeln("Copyright (C) Erny");
    writeln("Copyright (C) Davide");
    writeln("License: All rights reserved. No warranty, explicit or implicit, provided.");
    writeln();

    LoginResponse loginSession;

    while (true) {
        write("Insert your username/email: ");
        auto username = stdin.readln().strip;
        write("Insert your password: ");
        auto password = stdin.readln().strip;

        loginSession = login(username, password);

        if (loginSession.result && isSessionActive(loginSession.loginToken)) {
            writeln("Successful login, welcome ", loginSession.completeName);
            writeln();
            break;
        } else {
            writeln("Login failed!");
            writeln();
        }
    }

    auto hardwareId = getHardwareId();

    while (true) {
        if (hardwareId != null) {
            writeln("We have detected the following MAC Address associated with your network card: ", hardwareId);
            write("Press enter to confirm or c to specify a custom mac address: ");

            auto macCustom = stdin.readln().strip;

            if (macCustom.length == 0) {
                break;
            }

            if (macCustom != "c") {
                continue;   // Invalid option
            }
        } else {
            writeln("We have not detected a valid MAC Address!");
        }

        version(Support_Interface_Mac) {
            auto macCustomText = "Press m to specify a mac address, i to specify a different network interface or r to generate a random mac address: ";
        } else {
            auto macCustomText = "Press m to specify a mac address or r to generate a random mac address: ";
        }

        write(macCustomText);

        switch(stdin.readln().strip) {
            version(Support_Interface_Mac) {
                case "i" : {
                    write("Specify a network interface: ");
                    auto hardwareIdCustom = getHardwareIdInterface(stdin.readln().strip);

                    if (hardwareIdCustom != null) {
                        hardwareId = hardwareIdCustom;
                    } else {
                        writeln("The network interface is not valid!");
                    }

                    break;
                }
            }

            case "m" : {
                write("Specify a MAC address: ");
                hardwareId = stdin.readln().strip;
                break;
            }

            case "r" : {
                hardwareId = generateRandomHardwareId;
                break;
            }

            default:
        }
    }

    writeln();
    int errorCode;
    auto books = bookHistory(loginSession.loginToken, hardwareId, errorCode);

    if (errorCode != HISTORY_ERROR.SUCCESS) {
        if (errorCode == HISTORY_ERROR.MAX_DEVICE) {
            writeln("Max number of registered devices reached");
        } else {
            writeln("Unknown error: ", errorCode);
        }

        return;
    }

    viewBookLibrary(books);

    while(true) {
        writeln();
        write("Enter the book number to download, p to view the library again or e to exit: ");
        auto libraryOption = stdin.readln().strip;

        if (libraryOption == "p") {
            viewBookLibrary(books);
            continue;
        }

        if (libraryOption == "e") {
            break;
        }

        if (!libraryOption.isNumeric) {
            continue;
        }

        auto bookIndexDownload = to!size_t(libraryOption);

        if (bookIndexDownload > books.length || bookIndexDownload < 1) {
            continue;
        }

        bookIndexDownload--;    // Back to array index

        writeln("Downloading and removing the DRM in progress...");
        auto bookFile = downloadBook(loginSession.loginToken, hardwareId, books[bookIndexDownload].bookFileURL);

        if (!bookFile.result) {
            writeln("Download failed!");
            continue;
        }

        writeln("Download successful!");
        writeln("The book will be saved as \"", books[bookIndexDownload].title, ".pdf\"");
        writePdf(bookFile.fileData, books[bookIndexDownload].title ~ ".pdf");
    }

}

private void viewBookLibrary(Book[] books) {
    writeln("Your library:");

    foreach (i, book; books) {
        writeln(i+1, ") ", book.title);
    }
}

private void writePdf(ubyte[] bookFile, string path) {
    import std.file : write;

    write(path, bookFile);
}
