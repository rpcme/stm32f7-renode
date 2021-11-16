/*
 * This file has a function for each BSP category that we want to
 * setup except for the ethernet setup which is taken care of by
 * FreeRTOS-Plus-TCP.
 */

#include <string.h>
/* Naming conventions in this file follow those from the ST Micro CUBE
 * SDK so it's easier to follow when you're comparing the settings
 * against the SDK */

#include "FreeRTOS.h"
#include "app-hardware.h"
#include "FreeRTOSConfig.h"

UART_HandleTypeDef xUARTHandle;
RNG_HandleTypeDef hrng;
static UBaseType_t ulNextRand;
uint32_t ulInitialSeed;
uint32_t ulSeed;

void SystemClock_Config( void );
void prvUART_Init( void );
BaseType_t xRandom32( uint32_t *pulValue );
BaseType_t xApplicationGetRandomNumber( uint32_t *pulValue );
static void prvSRand( UBaseType_t ulSeed );

void vSetupHardware( void )
{
    SCB_EnableICache();

    // Disabling is recommended for FreeRTOS+TCP.
    SCB_DisableDCache();

    HAL_Init();

    SystemClock_Config();

    BSP_LED_Init( LED1 );
    BSP_PB_Init(BUTTON_KEY, BUTTON_MODE_GPIO);    

    xUARTHandle.Init.BaudRate   = 115200;
    xUARTHandle.Init.WordLength = UART_WORDLENGTH_8B;
    xUARTHandle.Init.StopBits   = UART_STOPBITS_1;
    xUARTHandle.Init.Parity     = UART_PARITY_NONE;
    xUARTHandle.Init.HwFlowCtl  = UART_HWCONTROL_NONE;
    xUARTHandle.Init.Mode       = UART_MODE_TX_RX;
    xUARTHandle.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
    BSP_COM_DeInit(COM1, &xUARTHandle);
    BSP_COM_Init(COM1, &xUARTHandle);

    /* Enable the clock for the RNG. */
    __HAL_RCC_RNG_CLK_ENABLE();
    RCC->AHB2ENR |= RCC_AHB2ENR_RNGEN;
    RNG->CR |= RNG_CR_RNGEN;
    
    /* Set the Instance pointer. */
    hrng.Instance = RNG;






/* Initialise it. */
    HAL_RNG_Init( &hrng );
    /* Get a random number. */
    HAL_RNG_GenerateRandomNumber( &hrng, &ulSeed );
    /* And pass it to the rand() function. */
    //		vSRand( ulSeed );
    
    hrng.Instance = RNG;
    HAL_RNG_Init( &hrng );
    xRandom32( &ulSeed );
    prvSRand( ulSeed );
    ulInitialSeed = ulSeed;
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
    //configASSERT( HAL_PWREx_ActivateOverDrive() != HAL_OK);
    HAL_PWREx_ActivateOverDrive();
    
    /* Select PLL as system clock source and configure the HCLK, PCLK1 and PCLK2
       clocks dividers */
    RCC_ClkInitStruct.ClockType = (RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2);
    RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
    RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;
    //configASSERT( HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_7) == HAL_OK );
    HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_7);
}

// thank you hein
BaseType_t xRandom32( uint32_t *pulValue )
{
    return xApplicationGetRandomNumber( pulValue );
}

BaseType_t xApplicationGetRandomNumber( uint32_t *pulValue )
{
HAL_StatusTypeDef xResult;
BaseType_t xReturn;
uint32_t ulValue;

	xResult = HAL_RNG_GenerateRandomNumber( &hrng, &ulValue );
	if( xResult == HAL_OK )
	{
		xReturn = pdPASS;
		*pulValue = ulValue;
	}
	else
	{
		xReturn = pdFAIL;
	}
	return xReturn;
}
static void prvSRand( UBaseType_t ulSeed )
{
	/* Utility function to seed the pseudo random number generator. */
	ulNextRand = ulSeed;
}

void HAL_ETH_MspInit(ETH_HandleTypeDef *heth)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  
  /* Enable GPIOs clocks */
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOG_CLK_ENABLE();

/* Ethernet pins configuration ************************************************/
  /*
        RMII_REF_CLK ----------------------> PA1
        RMII_MDIO -------------------------> PA2
        RMII_MDC --------------------------> PC1
        RMII_MII_CRS_DV -------------------> PA7
        RMII_MII_RXD0 ---------------------> PC4
        RMII_MII_RXD1 ---------------------> PC5
        RMII_MII_RXER ---------------------> PG2
        RMII_MII_TX_EN --------------------> PG11
        RMII_MII_TXD0 ---------------------> PG13
        RMII_MII_TXD1 ---------------------> PG14
  */

  /* Configure PA1, PA2 and PA7 */
  GPIO_InitStructure.Speed = GPIO_SPEED_HIGH;
  GPIO_InitStructure.Mode = GPIO_MODE_AF_PP;
  GPIO_InitStructure.Pull = GPIO_NOPULL; 
  GPIO_InitStructure.Alternate = GPIO_AF11_ETH;
  GPIO_InitStructure.Pin = GPIO_PIN_1 | GPIO_PIN_2 | GPIO_PIN_7;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStructure);
  
  /* Configure PC1, PC4 and PC5 */
  GPIO_InitStructure.Pin = GPIO_PIN_1 | GPIO_PIN_4 | GPIO_PIN_5;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStructure);

  /* Configure PG2, PG11, PG13 and PG14 */
  GPIO_InitStructure.Pin =  GPIO_PIN_2 | GPIO_PIN_11 | GPIO_PIN_13 | GPIO_PIN_14;
  HAL_GPIO_Init(GPIOG, &GPIO_InitStructure);
  
  /* Enable the Ethernet global Interrupt */
  HAL_NVIC_SetPriority(ETH_IRQn, 0x7, 0);
  HAL_NVIC_EnableIRQ(ETH_IRQn);
  
  /* Enable ETHERNET clock  */
  __HAL_RCC_ETH_CLK_ENABLE();
}
