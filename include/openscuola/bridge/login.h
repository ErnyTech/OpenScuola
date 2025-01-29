#pragma once
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    bool result;
    const char* loginToken;
    const char* sessionId;
    const char* username;
    const char* completeName;
} c_LoginResponse;

c_LoginResponse* c_login(const char* username, const char* password);
bool c_isSessionActive(const char* loginToken);
const char* c_simpleLogin(const char* username, const char* password);

#ifdef __cplusplus
}
#endif

