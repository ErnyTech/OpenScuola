#pragma once
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    bool result;
    const char* md5;
    size_t downloadSize;
    uint8_t* fileData;
} c_c_BookFile;

c_c_BookFile* c_downloadBook(const char* loginToken, const char* hardwareId, const char* bookUrl);
c_c_BookFile* c_downloadBookFromId(const char* loginToken, const char* hardwareId, const char* bookId);
c_c_BookFile* c_downloadBookFromId(const char* loginToken, const char* hardwareId, const char* bookId);
c_c_BookFile* c_downloadImageFromId(const char* loginToken, const char* hardwareId, const char* bookId, bool is700);

#ifdef __cplusplus
}
#endif

