module openscuola.bridge.util;

alias defaultHttpType = ubyte[];
__gshared string tempDir;
__gshared string caCertPath;

extern(C) const(char)* c_genLoginToken(const char* username, const char* sessionId) {
    import std.string : toStringz, fromStringz;
    return genLoginToken(username.fromStringz.idup, sessionId.fromStringz.idup).toStringz;
}

extern(C) const(char)* c_getUsernameLoginToken(const char* loginToken) {
    import std.string : toStringz, fromStringz;
    return getUsernameLoginToken(loginToken.fromStringz.idup).toStringz;
}

extern(C) const(char)* c_getSessionIdLoginToken(const char* loginToken) {
    import std.string : toStringz, fromStringz;
    return getSessionIdLoginToken(loginToken.fromStringz.idup).toStringz;
}

public string genLoginToken(string username, string sessionId) {
    return username ~ "|" ~ sessionId;
}

public string getUsernameLoginToken(string loginToken) {
    import std.array : split;

    auto loginTokenArr = loginToken.split("|");

    if (loginTokenArr.length != 2) {
        return "";
    }

    return loginTokenArr[0];
}

public string getSessionIdLoginToken(string loginToken) {
    import std.array : split;
    
    auto loginTokenArr = loginToken.split("|");

    if (loginTokenArr.length != 2) {
        return "";
    }

    return loginTokenArr[1];
}

T httpGet(T = defaultHttpType)(string url, ref int errorCode) {
    import requests : Request, Response;
    import std.stdio : writeln;
    
    Response httpResponse;
    auto httpRequest = Request();
    
    version(Windows) {
    	httpRequest.sslSetCaCert(getCaCert());
    }
    
    try {
        httpResponse = httpRequest.get(url);
    } catch (Exception e) {
        writeln("Error: HTTP Connection failed! Check your Internet access.");
        errorCode = -1;
        return T.init;
    }
    
    errorCode = httpResponse.code;
    
    static if (is(T == defaultHttpType)) {
    	return httpResponse.responseBody.data;
    } else {
    	return httpResponse.responseBody.data!T;
    }
}

T httpPost(T = defaultHttpType)(string url, string[string] query, ref int errorCode) {
    import requests : Request, Response;
    import std.stdio : writeln;
    
    Response httpResponse;
    auto httpRequest = Request();
    
    version(Windows) {
    	httpRequest.sslSetCaCert(getCaCert());
    }
    
    try {
        httpResponse = httpRequest.post(url, query);
    } catch (Exception e) {
        writeln("Error: HTTP Connection failed! Check your Internet access.");
        errorCode = -1;
        return T.init;
    }
    
    errorCode = httpResponse.code;
    
    static if (is(T == defaultHttpType)) {
    	return httpResponse.responseBody.data;
    } else {
    	return httpResponse.responseBody.data!T;
    }
}

version(Windows) {
    string getCaCert() {
        import std.stdio : writeln;
        import std.path : buildPath;
        import std.file : write;
	
        if (caCertPath !is null && caCertPath != "") {
            return caCertPath;
        }
	
        try {
    	    tempDir = getTempDir();
        } catch(Exception e) {
    	    writeln("Error: Failed to create temporary directory!");
    	    caCertPath = null;
            return null;
        }
    
        caCertPath = tempDir.buildPath("cacert.pem");
    
        try {
    	    write(caCertPath, import("cacert.pem"));
        } catch(Exception e) {
    	    writeln("Error: Failed to extract cacert.pem!");
    	    caCertPath = null;
	    removeDir(tempDir);   
            return null;
        }
    
        return caCertPath;
    }
}

string getTempDir() {
    import std.datetime : Clock;
    import std.file : tempDir, exists, mkdir;
    import std.path : buildPath;
    import std.uuid : randomUUID;

    auto id = randomUUID.toString() ~ "-" ~ Clock.currTime().toISOString();
    auto dirTemp = tempDir.buildPath(id ~ "-OpenScuola");

    dirTemp.mkdir();
    return dirTemp;
}

void removeDir(string dir) {
    import std.file : exists, rmdirRecurse;

    if (dir is null || dir.length == 0 || !dir.exists) {
        return;
    }

    dir.rmdirRecurse();
}

static ~this() {
    removeDir(tempDir);
}
