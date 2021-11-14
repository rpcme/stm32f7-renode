/**
 ******************************************************************************
 * @file           : app-main.c
 * @author         : Richard Elberger
 * @brief          : Main program body
 ******************************************************************************
 * @attention
 *
 * <h2><center>&copy; Copyright (c) 2021 Amazon Web Services.
 * All rights reserved.</center></h2>
 *
 * This software component is licensed by AWS under the MIT-0 licence.
 * See LICENSE for more details.
 *
 ******************************************************************************
 */

#include <stdint.h>
#include <stdio.h>

#include "app-main.h"
#include "app-hardware.h"
#include "app-network.h"
#include "app-task-logging.h"
#include "app-task-blinky.h"
#include "app-task-full.h"
#include "app-task-mqtt.h"

#include "FreeRTOS.h"
#include "FreeRTOSConfig.h"
#include "FreeRTOSIPConfig.h"
#include "task.h"
#include "semphr.h"

#if !defined(__SOFT_FP__) && defined(__ARM_FP)
  #warning "FPU is not initialized, but the project is compiling for an FPU. Please initialize the FPU before use."
#endif

int main(void)
{
    /* Always starts, will not initialize UART unless APP_PROGRAM_UART == 1 */
    vSetupHardware();

    /* Starts a task when APP_PROGRAM_UART == 1 (app-main.h)
       Function implemented in app-task-logging.c */
    vSetupLoggingTask();

    /* Initializes when APP_PROGRAM_NETWORK == 1 (app-main.h)
       Function implemented in app-network.c */
    vSetupNetwork();

    /* Starts a task when APP_PROGRAM_BLINKY == 1 (app-main.h)
       Function implemented in app-task-blinky.c */
    vSetupBlinkyTask();

    /* Starts a task when APP_PROGRAM_FULL == 1 (app-main.h)
       Function implemented in app-task-full.c */
    vSetupFullTask();

    /* Starts a task when APP_PROGRAM_NETWORK == 1
       and APP_PROGRAM_FULL == 1 (app-main.h)
       Function implemented in app-task-mqtt */
    vSetupMqttTask();

    /* Always starts */
    vTaskStartScheduler();

    /* Should never reach this */
    for( ;; );
}
