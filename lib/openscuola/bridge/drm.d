module openscuola.bridge.private_header.drm;

void removeDrm(uint magic, ubyte[] pdf) {
    import std.algorithm.searching : findSkip, countUntil;
    
    auto pdfNew = pdf;
    while (true) {  
        if (!pdfNew.findSkip("\x0D\x0Axref\x0D\x0A")) {
            break;
        }

        auto endXref = pdfNew.countUntil("\x0D\x0Atrailer\x0D\x0A");
        auto table = pdfNew[0..endXref];
        fixXrefTable(magic, cast(char[]) table, pdf);
    }
}

private void fixXrefTable(uint magic, char[] table, ubyte[] pdf) {
    import std.format :  formattedRead, formattedWrite;
    import std.algorithm.searching : findSkip, countUntil;

    while (true) {
        uint start;
        uint len;

        if (table[0] < '0' || table[0] > '9') {
            break;
        }

        table.formattedRead!"%u %u"(start, len);
        table.findSkip("\x0D\x0A");
        auto end = start + len;

        foreach (i; start..end) {
            uint offset;
            uint gen;

            auto tableReader = table;
            auto tableWriter = table;
            tableReader.formattedRead!"%u %u"(offset, gen);

            if (offset != 0) {
                offset ^= magic;
                assert(offset <= pdf.length, "The computed magic number is wrong, probably this tool is no longer compatible");
                tableWriter.formattedWrite!"%010u"(offset);
                table[10] = ' ';
                auto object = pdf[offset..$];
                auto endObject = object.countUntil("endobj");
                object = object[0..endObject];
                fixObjectNumber(i, object);
            }

            table.findSkip("\x0D\x0A");
        }
    }
}

private void fixObjectNumber(uint number, ubyte[] object) {
    import std.algorithm.searching : countUntil;
    import std.format : format, formattedWrite;

    auto objectWriter = object;
    auto oldObjectNumberLength = object.countUntil("\x20");
    assert(oldObjectNumberLength != 0, "The PDF file is not valid, probably this tool is no longer compatible");
    auto objectNumberFormat = format!"%%0%uu"(oldObjectNumberLength);
    objectWriter.formattedWrite(objectNumberFormat, number);
    object[oldObjectNumberLength] = ' ';
    assert(oldObjectNumberLength == object.countUntil("\x20"), "There is no more space in the PDF file, currently this tool cannot remove the DRM from this file");
}

uint computePdfMagic(ubyte[] pdf, string username, string deviceId, string activationKey) {
    auto pdfKey = computePdfKey(username, deviceId, activationKey);
    auto bookKey = decodeBookKey(pdf);
    auto magic = cast(uint) (pdfKey % bookKey);
    return magic;
}

private ulong computePdfKey(string username, string deviceId, string activationKey) {
    import std.bitmanip : nativeToBigEndian, bigEndianToNative;
    import std.digest.md : md5Of, digestLength, MD5;
    import std.algorithm.iteration : map;
    import std.range : chunks;
    import std.conv : to;
    import std.array : array;

    auto usernameHash = md5Of(username);
    auto deviceIdHash = md5Of(deviceId);
    auto activationKeyHash = activationKey.chunks(2)
                        .map!(digits => digits.to!ubyte(16))
                        .array;
                        
   ubyte[digestLength!MD5] key1;
   ubyte[8] keyBytes;
        
    foreach (i, ref elem; key1) {
        elem = deviceIdHash[i] ^ usernameHash[i];
    }
        
    foreach(i, ref elem; keyBytes) {
        elem = activationKeyHash[i + 8] ^ key1[i + 8];
    }
        
    auto key = bigEndianToNative!ulong(keyBytes);
    return key;
}

private ulong decodeBookKey(ubyte[] pdf) {
    import std.conv : to;

    ubyte[] header = pdf[11 .. 11 + 42];
    int x = pdf.length & 0x7F;

    foreach(ref ubyte headerElem; header) {
        headerElem ^= x;
        x = (x + 1) & 0x7F;
    }

    char[] bookKeyStr = cast(char[]) header[26 .. $];
    auto bookKey = to!ulong(bookKeyStr, 16);
    header[0..$] = 0;
    return bookKey;
}
