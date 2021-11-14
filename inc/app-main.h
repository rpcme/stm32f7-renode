#ifndef APP_MAIN_H
#define APP_MAIN_H

#define APP_PROGRAM_UART 1
#define APP_PROGRAM_NETWORK 1
#define APP_PROGRAM_BLINKY 0
#define APP_PROGRAM_FULL 0
#define APP_PROGRAM_CLOUD 0

void vLoggingPrintf(const char *pcFormatString, ... );

#endif
