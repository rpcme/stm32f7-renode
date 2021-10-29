#ifndef APP_HARDWARE_H
#define APP_HARDWARE_H

#include "stm32746g_discovery.h"
#include "stm32f7xx_hal.h"
#include "stm32f7xx_hal_usart.h"

/*-----------------------------------------------------------*/
/*
 * Configure the hardware as necessary to run this demo.
 */
void prvSetupHardware( void );

UART_HandleTypeDef * huart;

#endif
