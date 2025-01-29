#pragma once

#ifdef __cplusplus
extern "C" {
#endif

const char* c_getDeviceId(const char* hardwareId);
const char* c_generateRandomHardwareId();
const char* c_getHardwareIdInterface(const char* netInterface);
const char* c_getHardwareId();

#ifdef __cplusplus
}
#endif
