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

#include "FreeRTOS.h"
#include "FreeRTOSConfig.h"
#include "FreeRTOSIPConfig.h"
#include "task.h"
#include "semphr.h"
#include "FreeRTOS_IP.h"
#include "FreeRTOS_Sockets.h"

#include "app-hardware.h"
#include "app-main.h"

#define mainDEVICE_NICK_NAME "re:Invent"
#include "logging_levels.h"
#define LIBRARY_LOG_LEVEL LOG_INFO
#define LIBRARY_LOG_NAME  "re:Invent"
#include "logging_stack.h"

#if !defined(__SOFT_FP__) && defined(__ARM_FP)
  #warning "FPU is not initialized, but the project is compiling for an FPU. Please initialize the FPU before use."
#endif

void vLoggingPrintfRaw(const char *pcFormatString, ... );


/*-----------------------------------------------------------*/

#if ( APP_PROGRAM_NETWORK == 1 )
static const uint8_t ucIPAddress[ 4 ] = { configIP_ADDR0, configIP_ADDR1, configIP_ADDR2, configIP_ADDR3 };
static const uint8_t ucNetMask[ 4 ] = { configNET_MASK0, configNET_MASK1, configNET_MASK2, configNET_MASK3 };
static const uint8_t ucGatewayAddress[ 4 ] = { configGATEWAY_ADDR0, configGATEWAY_ADDR1, configGATEWAY_ADDR2, configGATEWAY_ADDR3 };
static const uint8_t ucDNSServerAddress[ 4 ] = { configDNS_SERVER_ADDR0, configDNS_SERVER_ADDR1, configDNS_SERVER_ADDR2, configDNS_SERVER_ADDR3 };
const uint8_t ucMACAddress[ 6 ] = { configMAC_ADDR0, configMAC_ADDR1, configMAC_ADDR2, configMAC_ADDR3, configMAC_ADDR4, configMAC_ADDR5 };
#endif

static SemaphoreHandle_t xUartMutex = NULL;

int main(void)
{

    prvSetupHardware();

#if ( APP_PROGRAM_UART == 1 )
    xUartMutex = xSemaphoreCreateMutex();
    const char * start = "Starting up.";
    vLoggingPrintfRaw(start);
#endif

#if ( APP_PROGRAM_BLINKY == 1 )
    vInitializeTaskBlinky();    
#endif

#if ( APP_PROGRAM_NETWORK == 1 )
    FreeRTOS_IPInit( ucIPAddress, ucNetMask, ucGatewayAddress, ucDNSServerAddress, ucMACAddress );
#endif

    vTaskStartScheduler();
    for( ;; );
}


extern uint32_t ulApplicationGetNextSequenceNumber( uint32_t ulSourceAddress,
                                                    uint16_t usSourcePort,
                                                    uint32_t ulDestinationAddress,
                                                    uint16_t usDestinationPort )
{
    ( void ) ulSourceAddress;
    ( void ) usSourcePort;
    ( void ) ulDestinationAddress;
    ( void ) usDestinationPort;

    return uxRand();
}

BaseType_t xApplicationGetRandomNumber( uint32_t * pulNumber )
{
    *pulNumber = uxRand();
    return pdTRUE;
}

static UBaseType_t ulNextRand;
UBaseType_t uxRand( void )
{
    const uint32_t ulMultiplier = 0x015a4e35UL, ulIncrement = 1UL;

    /*
     * Utility function to generate a pseudo random number.
     *
     * !!!NOTE!!!
     * This is not a secure method of generating a random number.  Production
     * devices should use a True Random Number Generator (TRNG).
     */
    ulNextRand = ( ulMultiplier * ulNextRand ) + ulIncrement;
    return( ( int ) ( ulNextRand >> 16UL ) & 0x7fffUL );
}


    BaseType_t xApplicationDNSQueryHook( const char * pcName )
    {
        BaseType_t xReturn;
        xReturn = pdPASS;

        /* Determine if a name lookup is for this node.  Two names are given
         * to this node: that returned by pcApplicationHostnameHook() and that set
         * by mainDEVICE_NICK_NAME. */

        /*
        if( _stricmp( pcName, pcApplicationHostnameHook() ) == 0 )
        {
            xReturn = pdPASS;
        }
        else if( _stricmp( pcName, mainDEVICE_NICK_NAME ) == 0 )
        {
            xReturn = pdPASS;
        }
        else
        {
            xReturn = pdFAIL;
        }
        */
        return xReturn;
    }


void vLoggingPrintf(const char *pcFormatString, ... )
{
    va_list arg;

    xSemaphoreTake( xUartMutex, portMAX_DELAY );
    {
        vLoggingPrintfRaw(pcFormatString);
    }
    xSemaphoreGive( xUartMutex );
}

void vLoggingPrintfRaw(const char *pcFormatString, ... )
{
    extern UART_HandleTypeDef * huart;
    HAL_UART_Transmit( huart, (uint8_t *) pcFormatString, strlen(pcFormatString), 10);
}
