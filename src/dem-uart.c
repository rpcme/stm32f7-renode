#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <errno.h>
#include <stdlib.h>

#include "app-hardware.h"
#include "app-task-logging.h"

#include "FreeRTOS.h"
#include "task.h"

typedef struct xsLogging
{
    int speed;
} xsLogging_t;

void vLogTestTask( void * pvParameters );

int main(void)
{
    vSetupHardware();
    vSetupLoggingTask();

    xsLogging_t *task1Props, *task2Props, *task3Props;
    task1Props = pvPortMalloc( sizeof( xsLogging_t ) );
    task2Props = pvPortMalloc( sizeof( xsLogging_t ) );
    task3Props = pvPortMalloc( sizeof( xsLogging_t ) );
    task1Props->speed = 100;
    task2Props->speed = 200;
    task3Props->speed = 300;
    
    xTaskCreate( vLogTestTask, "A", configMINIMAL_STACK_SIZE * 3, task1Props, 0, NULL );
    xTaskCreate( vLogTestTask, "B", configMINIMAL_STACK_SIZE * 3, task2Props, 0, NULL );
    xTaskCreate( vLogTestTask, "C", configMINIMAL_STACK_SIZE * 3, task3Props, 0, NULL );

    vLoggingPrintf("Starting the scheduler.");
    vTaskStartScheduler();

    for ( ;; );
}

void vLogTestTask( void * pvParameters )
{
    xsLogging_t * pxParameters;
    uint32_t iteration = 0;
    char * taskname = pvPortMalloc( 12 * sizeof( char ) );
    
    pxParameters = ( xsLogging_t * ) pvParameters;
    taskname = pcTaskGetName( NULL );

    vLoggingPrintf("Starting loop for task %s", taskname);
    for (;;)
    {
        vLoggingPrintf("Task %s Speed %d Iteration %d", taskname, pxParameters->speed, iteration);
        ++iteration;
        vTaskDelay( pdMS_TO_TICKS( pxParameters->speed ) );
    }
}
