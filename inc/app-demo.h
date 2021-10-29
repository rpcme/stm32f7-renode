#ifndef APP_DEMO
#define APP_DEMO
#include "TimerDemo.h"
#include "QueueOverwrite.h"
#include "EventGroupsDemo.h"
#include "IntSemTest.h"
#include "QueueSet.h"
#include "TaskNotify.h"
#include "stm32f7xx_hal.h"

/* The LED is used to show the demo status. (not connected on Rev A hardware) */
#define mainTOGGLE_LED()	HAL_GPIO_TogglePin( GPIOF, GPIO_PIN_10 )

#endif
