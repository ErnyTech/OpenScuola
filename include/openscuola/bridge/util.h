#pragma once

#ifdef __cplusplus
extern "C" {
#endif

const char* c_genLoginToken(const char* username, const char* sessionId);
const char* c_getUsernameLoginToken(const char* loginToken);
const char* c_getSessionIdLoginToken(const char* loginToken);

#ifdef __cplusplus
}
#endif
