/* app-task-logging.c
 * 
 * Creates a lightweight task that actions writing to UART when data
 * is written to a stream buffer that is modified by vLoggingPrintf.
 *
 * Ensure configSUPPORT_DYNAMIC_ALLOCATION is 1 because the buffer
 * uses dynamic allocation (FreeRTOSConfig.h).
 *
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include "app-main.h"
#include "app-hardware.h"
#include "app-task-logging.h"
#include "FreeRTOS.h"
#include "FreeRTOSConfig.h"
#include "task.h"
#include "stream_buffer.h"
#include "semphr.h"

/* Dimensions the arrays into which print messages are created. */
#define MAX_PRINT_STRING_LENGTH       255
#define LOGGING_STREAM_BUFFER_SIZE    2000
#define LOGGING_SEGMENT_SIZE          10
#define LOGGING_STREAM_BLOCK_TIME     1000
#define LOGGING_UART_HANDLE_TYPE      UART_HandleTypeDef
#define LOGGING_UART_HANDLE_NAME      xUARTHandle
#define LOGGING_UART_FORMAT          "%lu %lu [%s] %s\r\n"

extern LOGGING_UART_HANDLE_TYPE LOGGING_UART_HANDLE_NAME; // define by hardware setup
static StreamBufferHandle_t xStreamBuffer = NULL;
static SemaphoreHandle_t xLoggingSemaphore = NULL;

void vWriteUart( const char * data );
void vLoggingTask(void * pvParameters);

void vSetupLoggingTask() {
    xStreamBuffer = xStreamBufferCreate( LOGGING_STREAM_BUFFER_SIZE, LOGGING_SEGMENT_SIZE );
    xLoggingSemaphore = xSemaphoreCreateMutex();
    xTaskCreate( vLoggingTask, "Logger", configMINIMAL_STACK_SIZE * 10, NULL, 0, NULL );
}

void vLoggingTask(void * pvParameters) {
    ( void ) pvParameters;
    char * ucRxData = pvPortMalloc( LOGGING_SEGMENT_SIZE );
    
    //vWriteUart( "Starting logging...\r\n" );
    for (;;) {
        if ( xStreamBufferReceive( xStreamBuffer,
                                   ( void * ) ucRxData,
                                   sizeof( ucRxData ),
                                   LOGGING_STREAM_BLOCK_TIME ) > 0 )
        {
            vWriteUart( ucRxData );
        }
    }
}

void vWriteUart( const char * data )
{
    HAL_UART_Transmit( &xUARTHandle, (uint8_t *) data, strlen( data ), 10 );
}

void vLoggingPrintf( const char * pcFormat, ... )
{
    char cLogitem[ MAX_PRINT_STRING_LENGTH ];
    char cLogitemBody[ MAX_PRINT_STRING_LENGTH ];
    // Having this storage class is a buggy POS need to change
    // implementaion to "take a number" method which will need a mutex
    // Sometimes, you just can't copy code from other demos and just
    // use it :(
    static BaseType_t xMessageNumber = 0;

    /* Additional info to place at the start of the log. */
    const char * pcTaskName;
    const char * pcNoTask = "None";
    if ( xTaskGetSchedulerState() != taskSCHEDULER_NOT_STARTED )
    {
        pcTaskName = pcTaskGetName( NULL );
    }
    else
    {
        pcTaskName = pcNoTask;
    }

    /* Organize the variant-argument value that we want to log */
    va_list args;
    va_start( args, pcFormat );
    vsnprintf( cLogitemBody,
               MAX_PRINT_STRING_LENGTH,
               pcFormat,
               args );
    va_end( args );


    /* Wrap the variable-argument log value in an envelope */
    snprintf( cLogitem,
              MAX_PRINT_STRING_LENGTH,
              LOGGING_UART_FORMAT,
              xMessageNumber++,
              ( unsigned long ) xTaskGetTickCount(),
              pcTaskName,
              cLogitemBody );

    if ( xTaskGetSchedulerState() == taskSCHEDULER_NOT_STARTED )
    {
        // This should be safe since multiple writers will not exist
        vWriteUart( cLogitem );
    }
    else
    {
        while ( xSemaphoreTake( xLoggingSemaphore, 10 ) != pdPASS )
        {
            vTaskDelay( pdMS_TO_TICKS( 10 ) );
        }

        /* Wait until enough bytes are in the stream buffer before writing */
        while ( xStreamBufferSpacesAvailable( xStreamBuffer ) < strlen( cLogitem ) )
        {
            vTaskDelay( pdMS_TO_TICKS( 10 ) );
        }

        /* Write to the buffer */
        xStreamBufferSend( xStreamBuffer, cLogitem, strlen( cLogitem ), pdMS_TO_TICKS( 10 ));
        xSemaphoreGive( xLoggingSemaphore );
    }
}
