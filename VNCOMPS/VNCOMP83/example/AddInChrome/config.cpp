#include "config.h"

AddInComponentType typeComponent = eAddInNative;
#if _WIN64
const char *nameFilePrj = ADDNCHROME "Win64.exe";
const char *nameFileComponent = ADDNNATIVE "Win64_" ADDNVER ".dll";
#elif WIN32
const char *nameFilePrj = ADDNCHROME "Win32.exe";
const char *nameFileComponent = ADDNNATIVE "Win32_" ADDNVER ".dll";
#elif __APPLE__
const char *nameFilePrj = ADDNCHROME "Mac64";
const char *nameFileComponent = "lib" ADDNNATIVE "Mac64_" ADDNVER ".dylib";
#elif __LP64__
const char *nameFilePrj = ADDNCHROME "Lin64";
const char *nameFileComponent = "lib" ADDNNATIVE "Lin64_" ADDNVER ".so";
#elif __linux__
const char *nameFilePrj = ADDNCHROME "Lin32";
const char *nameFileComponent = "lib" ADDNNATIVE "Lin32_" ADDNVER ".so";
#endif
