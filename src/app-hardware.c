/*
 * This file has a function for each BSP category that we want to
 * setup except for the ethernet setup which is taken care of by
 * FreeRTOS-Plus-TCP.
 */

#include <string.h>
/* Naming conventions in this file follow those from the ST Micro CUBE
 * SDK so it's easier to follow when you're comparing the settings
 * against the SDK */

#include "app-hardware.h"
//#include "stm32f7xx_hal_conf.h"
#include "FreeRTOSConfig.h"

UART_HandleTypeDef xUARTHandle;

void SystemClock_Config( void );
void prvUART_Init( void );

void vSetupHardware( void )
{
    SCB_EnableICache();
    SCB_EnableDCache();

    HAL_Init();

    SystemClock_Config();

    BSP_LED_Init( LED1 );
    BSP_PB_Init(BUTTON_KEY, BUTTON_MODE_GPIO);    

    //xUARTHandle.Instance        = USARTx;
    xUARTHandle.Init.BaudRate   = 115200;
    xUARTHandle.Init.WordLength = UART_WORDLENGTH_8B;
    xUARTHandle.Init.StopBits   = UART_STOPBITS_1;
    xUARTHandle.Init.Parity     = UART_PARITY_NONE;
    xUARTHandle.Init.HwFlowCtl  = UART_HWCONTROL_NONE;
    xUARTHandle.Init.Mode       = UART_MODE_TX_RX;
    xUARTHandle.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
    BSP_COM_DeInit(COM1, &xUARTHandle);
    BSP_COM_Init(COM1, &xUARTHandle);
}

/**
  * @brief  System Clock Configuration
  *         The system Clock is configured as follow : 
  *            System Clock source            = PLL (HSE)
  *            SYSCLK(Hz)                     = 216000000
  *            HCLK(Hz)                       = 216000000
  *            AHB Prescaler                  = 1
  *            APB1 Prescaler                 = 4
  *            APB2 Prescaler                 = 2
  *            HSE Frequency(Hz)              = 25000000
  *            PLL_M                          = 25
  *            PLL_N                          = 432
  *            PLL_P                          = 2
  *            PLL_Q                          = 9
  *            VDD(V)                         = 3.3
  *            Main regulator output voltage  = Scale1 mode
  *            Flash Latency(WS)              = 7
  * @param  None
  * @retval None
  */
void SystemClock_Config( void )
{
    RCC_ClkInitTypeDef RCC_ClkInitStruct;
    RCC_OscInitTypeDef RCC_OscInitStruct;

    /* Enable Power Control clock */
    __HAL_RCC_PWR_CLK_ENABLE();

    /* The voltage scaling allows optimizing the power consumption when the device is
       clocked below the maximum system frequency, to update the voltage scaling value 
       regarding system frequency refer to product datasheet.  */
    __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);


    /* Enable HSE Oscillator and activate PLL with HSE as source */
    RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
    RCC_OscInitStruct.HSEState = RCC_HSE_ON;
    RCC_OscInitStruct.HSIState = RCC_HSI_OFF;
    RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
    RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
    RCC_OscInitStruct.PLL.PLLM = 25;
    RCC_OscInitStruct.PLL.PLLN = 432;
    RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
    RCC_OscInitStruct.PLL.PLLQ = 9;
    HAL_RCC_OscConfig(&RCC_OscInitStruct);

    /* activate the OverDrive */
    configASSERT( HAL_PWREx_ActivateOverDrive() != HAL_OK);
    
    /* Select PLL as system clock source and configure the HCLK, PCLK1 and PCLK2
       clocks dividers */
    RCC_ClkInitStruct.ClockType = (RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2);
    RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
    RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;
    configASSERT( HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_7) == HAL_OK );
}
