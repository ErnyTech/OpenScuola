#pragma once
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define HISTORY_ERROR_SUCCESS = 0
#define HISTORY_ERROR_MAX_DEVICE = 412

typedef struct {
    int versionBook;
    const char* lastModificationDate;
    const char* bookId;
    const char* title;
    const char* subTitle;
    const char* author;
    const char* publisher;
    const char* image;
    const char* image700;
    const char* isbn;
    double price;
    const char* fileFormat;
    int numPages;
    const char* bookFileURL;
    long bookFileSize;
    const char* bookMd5;
} c_Book;

size_t c_bookHistory(const char* loginToken, const char* hardwareId, c_Book** booksOut);

#ifdef __cplusplus
}
#endif

