/*
 * This file has a function for each BSP category that we want to
 * setup except for the ethernet setup which is taken care of by
 * FreeRTOS-Plus-TCP.
 */

#include <string.h>
#include "app-hardware.h"

#include "FreeRTOSConfig.h"


void prvSystemClockConfig( void );
void prvUART_Init( void );

void prvSetupHardware( void )
{
    GPIO_InitTypeDef  GPIO_InitStruct;

    SCB_EnableICache();
    SCB_EnableDCache();
    
    HAL_Init();
    
    /* Configure the System clock to have a frequency of 200 MHz */
    prvSystemClockConfig();

    BSP_LED_Init( LED1 );
    BSP_COM_Init( COM1, huart );

        /* Configure Flash prefetch and Instruction cache through ART accelerator. */
#if( ART_ACCLERATOR_ENABLE != 0 )
    {
      __HAL_FLASH_ART_ENABLE();
    }
#endif /* ART_ACCLERATOR_ENABLE */

    /* Set Interrupt Group Priority */
    HAL_NVIC_SetPriorityGrouping( NVIC_PRIORITYGROUP_4 );

    /* Init the low level hardware. */
    HAL_MspInit();


    /* Enable GPIOB  Clock (to be able to program the configuration
       registers) and configure for LED output. */
    __GPIOG_CLK_ENABLE();
    __HAL_RCC_GPIOF_CLK_ENABLE();
    
    GPIO_InitStruct.Pin = GPIO_PIN_10;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_PULLUP;
    GPIO_InitStruct.Speed = GPIO_SPEED_HIGH;
    HAL_GPIO_Init( GPIOF, &GPIO_InitStruct );
    
    /* MCO2 : Pin PC9 */
    HAL_RCC_MCOConfig( RCC_MCO2, RCC_MCO2SOURCE_SYSCLK, RCC_MCODIV_1 );    
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
void prvSystemClockConfig( void )
{
	RCC_ClkInitTypeDef RCC_ClkInitStruct;
	RCC_OscInitTypeDef RCC_OscInitStruct;

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

	/* Select PLL as system clock source and configure the HCLK, PCLK1 and PCLK2
       clocks dividers */
	RCC_ClkInitStruct.ClockType = (RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2);
	RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
	RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
	RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
	RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;
	configASSERT( HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_7) == HAL_OK );
}
