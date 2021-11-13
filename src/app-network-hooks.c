#include <stdint.h>
#include "FreeRTOS.h"
#include "FreeRTOSIPConfig.h"
#include "FreeRTOS_IP.h"
#include "FreeRTOS_Sockets.h"

/* TODO revisit this, we don't want to keep duplicating this block
 * across source files and Cobus says not to put it into a header
 * file */
#include "logging_levels.h"
#define LIBRARY_LOG_LEVEL LOG_INFO
#define LIBRARY_LOG_NAME  "re:Invent"
#include "logging_stack.h"

/* Called by FreeRTOS+TCP when the network connects or disconnects.  Disconnect
 * events are only received if implemented in the MAC driver. */
void vApplicationIPNetworkEventHook( eIPCallbackEvent_t eNetworkEvent )
{
    uint32_t ulIPAddress, ulNetMask, ulGatewayAddress, ulDNSServerAddress;
    char cBuffer[ 16 ];
    static BaseType_t xTasksAlreadyCreated = pdFALSE;

    /* If the network has just come up...*/
    if( eNetworkEvent == eNetworkUp )
    {
        /* Create the tasks that use the IP stack if they have not already been
         * created. */
        //if( xTasksAlreadyCreated == pdFALSE )
        //{
            /* Demos that use the network are created after the network is
             * up. */
      //    LogInfo( ( "---------STARTING DEMO---------\r\n" ) );
      //    vStartSimpleMQTTDemo();
      //    xTasksAlreadyCreated = pdTRUE;
      //}

        /* Print out the network configuration, which may have come from a DHCP
         * server. */
        FreeRTOS_GetAddressConfiguration( &ulIPAddress, &ulNetMask, &ulGatewayAddress, &ulDNSServerAddress );
        FreeRTOS_inet_ntoa( ulIPAddress, cBuffer );
        LogInfo( ( "\r\n\r\nIP Address: %s\r\n", cBuffer ) );

        FreeRTOS_inet_ntoa( ulNetMask, cBuffer );
        LogInfo( ( "Subnet Mask: %s\r\n", cBuffer ) );

        FreeRTOS_inet_ntoa( ulGatewayAddress, cBuffer );
        LogInfo( ( "Gateway Address: %s\r\n", cBuffer ) );

        FreeRTOS_inet_ntoa( ulDNSServerAddress, cBuffer );
        LogInfo( ( "DNS Server Address: %s\r\n\r\n\r\n", cBuffer ) );
    }
}


void vApplicationPingReplyHook( ePingReplyStatus_t eStatus, uint16_t usIdentifier )
{
static const uint8_t *pcSuccess = ( uint8_t * ) "Ping reply received - ";
static const uint8_t *pcInvalidChecksum = ( uint8_t * ) "Ping reply received with invalid checksum - ";
static const uint8_t *pcInvalidData = ( uint8_t * ) "Ping reply received with invalid data - ";
static uint8_t cMessage[ 50 ];


        switch( eStatus )
        {
                case eSuccess   :
                        FreeRTOS_debug_printf( ( ( char * ) pcSuccess ) );
                        break;

                case eInvalidChecksum :
                        FreeRTOS_debug_printf( ( ( char * ) pcInvalidChecksum ) );
                        break;

                case eInvalidData :
                        FreeRTOS_debug_printf( ( ( char * ) pcInvalidData ) );
                        break;

                default :
                        /* It is not possible to get here as all enums have their own
                        case. */
                        break;
        }

        sprintf( ( char * ) cMessage, "identifier %d\r\n", ( int ) usIdentifier );
        FreeRTOS_debug_printf( ( ( char * ) cMessage ) );
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
