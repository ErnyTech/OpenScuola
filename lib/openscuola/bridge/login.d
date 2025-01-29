module openscuola.bridge.login;

extern(C) struct c_LoginResponse {
    bool result;
    const char* loginToken;
    const char* sessionId;
    const char* username;
    const char* completeName;
}

struct LoginResponse {
    bool result;
    string loginToken;
    string sessionId;
    string username;
    string completeName;
}

extern(C) c_LoginResponse* c_login(const char* username, const char* password) {
    import std.string : toStringz, fromStringz;

    auto response = login(username.fromStringz.idup, password.fromStringz.idup);
    return new c_LoginResponse(response.result, response.loginToken.toStringz, 
                                response.sessionId.toStringz, 
                                response.username.toStringz,
                                response.completeName.toStringz
    );
}

extern(C) bool c_isSessionActive(const char* loginToken) {
    import std.string : fromStringz;
    return isSessionActive(loginToken.fromStringz.idup);
}

extern(C) const(char)* c_simpleLogin(const char* username, const char* password) {
    import std.string : toStringz, fromStringz;
    return simpleLogin(username.fromStringz.idup, password.fromStringz.idup).toStringz;
}

LoginResponse login(string username, string password) {
    import std.stdio : writeln;
    import openscuola.bridge.util : httpPost, genLoginToken;
    import openscuola.bridge.commonApi : URL;
    import dxml.dom : parseDOM;
    import std.conv : to;

    LoginResponse response;

    if (username.length <= 1 || password.length <= 1) {
        return response;
    }

    response.username = username;
    
    int httpErrorCode;
    auto content = httpPost!string(URL.LOGIN, ["username" : username, "password" : password], httpErrorCode);
    
    if (httpErrorCode == -1) {
        writeln("Error: HTTP Connection failed! Check your Internet access.");
        return response;
    }
    
    if (httpErrorCode != 200) {
        writeln("Error: Login failed");
    	return response;
    }

    auto dom = parseDOM(content);

    if (dom.children.length != 1) {
            return response;
        }

        auto result = dom.children[0];

        foreach(field; result.children) {

            if (field.attributes.length != 1) {
                return response;
            }

            switch (field.attributes[0].value) {
                case "errorCode" : {
                    if (field.children.length != 1) {
                        return response;
                    }

                    auto errorCode = to!int(field.children[0].text);

                    if (errorCode != 0) {
                        return response;
                    }

                    break;
                }

                case "sessionId" : {
                    if (field.children.length != 1) {
                        return response;
                    }

                    response.sessionId = field.children[0].text;
                    break;
                }

                case "completeName" : {
                    if (field.children.length != 1) {
                        return response;
                    }

                    response.completeName = field.children[0].text;
                    break;
                }

                default:
            }
        }

    response.loginToken = genLoginToken(response.username, response.sessionId);
    response.result = true;
    return response;
}

bool isSessionActive(string loginToken) {
    import std.stdio : writeln;
    import openscuola.bridge.util : httpGet, getUsernameLoginToken, getSessionIdLoginToken;
    import openscuola.bridge.commonApi : API;
    import dxml.dom : parseDOM;
    import std.conv : to;
    import std.format : format;

    auto username = getUsernameLoginToken(loginToken);
    auto sessionId = getSessionIdLoginToken(loginToken);

    if (sessionId.length <= 1 || username.length <= 1) {
        return false;
    }

    auto url = format(
        API.SESSION_ACTIVE,
        sessionId,
        username
    );
    
    int errorCode;
    auto content = httpGet!string(url, errorCode);
    
    if (errorCode == -1) {
        writeln("Error: HTTP Connection failed! Check your Internet access.");
        return false;
    }
    
    if (errorCode != 200) {
        return false;
    }

    auto dom = parseDOM(content);

    if (dom.children.length != 1) {
        return false;
    }

    auto result = dom.children[0];

    if (result.children.length != 1) {
        return false;
    }

    auto child = result.children[0];

    if (child.attributes.length == 1 && child.attributes[0].value) {
        return to!bool(child.children[0].text);
    } else {
        return false;
    }
}

string simpleLogin(string username, string password) {
    import openscuola.bridge.util : getUsernameLoginToken, getSessionIdLoginToken;

    auto loginResponse = login(username, password);

    if (!loginResponse.result || !isSessionActive(loginResponse.loginToken)) {
        return "";
    }

    return loginResponse.loginToken;
}


