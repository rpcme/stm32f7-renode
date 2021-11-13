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

/* Dimensions the arrays into which print messages are created. */
#define MAX_PRINT_STRING_LENGTH       255
#define LOGGING_STREAM_BUFFER_SIZE    32768
#define LOGGING_SEGMENT_SIZE          10
#define LOGGING_STREAM_BLOCK_TIME     10
#define LOGGING_UART_HANDLE_TYPE      UART_HandleTypeDef
#define LOGGING_UART_HANDLE_NAME      xUARTHandle

extern LOGGING_UART_HANDLE_TYPE LOGGING_UART_HANDLE_NAME; // define by hardware setup
static StreamBufferHandle_t xStreamBuffer = NULL;

void vWriteUart( const char * data );
void vLoggingTask(void * pvParameters);

void vSetupLoggingTask() {
    xStreamBuffer = xStreamBufferCreate( LOGGING_STREAM_BUFFER_SIZE, LOGGING_SEGMENT_SIZE );
    xTaskCreate( vLoggingTask, "Logger", configMINIMAL_STACK_SIZE * 2, NULL, 0, NULL );
}

void vLoggingTask(void * pvParameters) {
    ( void ) pvParameters;
    char * ucRxData = pvPortMalloc( LOGGING_SEGMENT_SIZE );
    uint8_t xReceivedBytes = 0;
    
    vWriteUart( "Starting logging..." );
    for (;;) {
        /* Block on the number of bytes that triggers the unblocked state */
        xReceivedBytes = xStreamBufferReceive( xStreamBuffer,
                                               ( void * ) ucRxData,
                                               sizeof( ucRxData ),
                                               LOGGING_STREAM_BLOCK_TIME );
        if ( xReceivedBytes > 0 )
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
    char cPrintString[ MAX_PRINT_STRING_LENGTH ];
    size_t xLength, xLength2;
    static BaseType_t xMessageNumber = 0;
    static BaseType_t xAfterLineBreak = pdTRUE;
    va_list args;
    const char * pcTaskName;
    const char * pcNoTask = "None";

    /* There are a variable number of parameters. */
    va_start( args, pcFormat );

    /* Additional info to place at the start of the log. */
    if ( xTaskGetSchedulerState() != taskSCHEDULER_NOT_STARTED )
    {
        pcTaskName = pcTaskGetName( NULL );
    }
    else
    {
        pcTaskName = pcNoTask;
    }

    if( ( xAfterLineBreak == pdTRUE ) && ( strcmp( pcFormat, "\r\n" ) != 0 ) )
    {
        xLength = snprintf( cPrintString, MAX_PRINT_STRING_LENGTH, "%lu %lu [%s] ",
                            xMessageNumber++,
                            ( unsigned long ) xTaskGetTickCount(),
                            pcTaskName );
        xAfterLineBreak = pdFALSE;
    }
    else
    {
        xLength = 0;
        memset( cPrintString, 0x00, MAX_PRINT_STRING_LENGTH );
        xAfterLineBreak = pdTRUE;
    }

    xLength2 = vsnprintf( cPrintString + xLength, MAX_PRINT_STRING_LENGTH - xLength, pcFormat, args );

    if( xLength2 < 0 )
    {
        /* Clean up. */
        xLength2 = MAX_PRINT_STRING_LENGTH - 1 - xLength;
        cPrintString[ MAX_PRINT_STRING_LENGTH - 1 ] = '\0';
    }

    xLength += xLength2;
    va_end( args );

    if ( xTaskGetSchedulerState() != taskSCHEDULER_NOT_STARTED )
    {
        vWriteUart( cPrintString );
    }
    else
    {
        taskENTER_CRITICAL();

        /* Wait until enough bytes are in the stream buffer before writing */
        while ( xStreamBufferSpacesAvailable( xStreamBuffer ) < strlen( cPrintString ) ) {
            vTaskDelay( pdMS_TO_TICKS( 10 ) );
        }

        /* Write to the buffer */
    
        taskEXIT_CRITICAL();
    }
}
