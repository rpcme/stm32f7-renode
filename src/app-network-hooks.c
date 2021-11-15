#include <stdint.h>
#include "FreeRTOS.h"
#include "FreeRTOS_IP.h"
#include "FreeRTOS_Sockets.h"
#include "FreeRTOS_DHCP.h"

#include "app-task-logging.h"

#define MESSAGE_IP_NETWORK_UP    "IP Network event: UP"
#define MESSAGE_IP_NETWORK_DOWN  "IP Network event: DOWN"
#define MESSAGE_IP_ADDRESS       "IP Address: %s"
#define MESSAGE_SUBNET_MASK      "Subnet Mask: %s"
#define MESSAGE_GW_ADDRESS       "Gateway Address: %s"
#define MESSAGE_DNS_ADDRESS      "DNS Server Address: %s"

#define MESSAGE_PING_SUCCESS     "Ping reply received - identifier %d"
#define MESSAGE_INVALID_CHECKSUM "Ping reply received with invalid checksum - identifier %d"
#define MESSAGE_INVALID_DATA     "Ping reply received with invalid data - identifier %d"

#define MESSAGE_DHCP_PREDISCOVER "DHCP event: Pre-Discover Event"
#define MESSAGE_DHCP_PREREQUEST  "DHCP event: Pre-Request Event"

void vApplicationIPNetworkEventHook( eIPCallbackEvent_t eNetworkEvent )
{
    char cBuffer[ 16 ];

    /* There are only two events: eNetworkUp and eNetworkDown */

    switch ( eNetworkEvent )
    {
    case eNetworkUp:
        vLoggingPrintf( MESSAGE_IP_NETWORK_UP );
        
        uint32_t ulIPAddress, ulNetMask, ulGatewayAddress, ulDNSServerAddress;

        FreeRTOS_GetAddressConfiguration( &ulIPAddress, &ulNetMask, &ulGatewayAddress, &ulDNSServerAddress );

        FreeRTOS_inet_ntoa( ulIPAddress, cBuffer );
        vLoggingPrintf( MESSAGE_IP_ADDRESS, cBuffer );

        FreeRTOS_inet_ntoa( ulNetMask, cBuffer );
        vLoggingPrintf( MESSAGE_SUBNET_MASK, cBuffer );

        FreeRTOS_inet_ntoa( ulGatewayAddress, cBuffer );
        vLoggingPrintf( MESSAGE_GW_ADDRESS, cBuffer );

        FreeRTOS_inet_ntoa( ulDNSServerAddress, cBuffer );
        vLoggingPrintf( MESSAGE_DNS_ADDRESS, cBuffer );

        break;
    case eNetworkDown:
        vLoggingPrintf( MESSAGE_IP_NETWORK_DOWN );
        break;
    }
}


void vApplicationPingReplyHook( ePingReplyStatus_t eStatus, uint16_t usIdentifier )
{
    switch( eStatus )
    {
    case eSuccess:
        vLoggingPrintf( MESSAGE_PING_SUCCESS, usIdentifier );
        break;
    case eInvalidChecksum:
        vLoggingPrintf( MESSAGE_INVALID_CHECKSUM, usIdentifier );
        break;
    case eInvalidData:
        vLoggingPrintf( MESSAGE_INVALID_DATA, usIdentifier );
        break;
    }
}

/* If you get an error compiling here for unknown types remember to:

   #define ipconfigUSE_DHCP_HOOK				( 1 )

   in FreeRTOSIPConfig.h
*/

eDHCPCallbackAnswer_t xApplicationDHCPHook( eDHCPCallbackPhase_t eDHCPPhase, uint32_t ulIPAddress )
{
    switch (eDHCPPhase)
    {
    case eDHCPPhasePreDiscover:
        vLoggingPrintf( MESSAGE_DHCP_PREDISCOVER );
        break;
    case eDHCPPhasePreRequest:
        vLoggingPrintf( MESSAGE_DHCP_PREREQUEST );
        break;
    }
    return eDHCPContinue;
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
