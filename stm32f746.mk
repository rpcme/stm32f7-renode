APP?=$(abspath .)
BASEPATH?=$(abspath ..)
MACH := STM32F746xx

OBJ := $(APP)/obj
LIB := $(APP)/lib
BIN := $(APP)/bin

STM := $(BASEPATH)/STM32CubeF7
FRK := $(BASEPATH)/FreeRTOS-Kernel
FRT := $(BASEPATH)/FreeRTOS-Plus-TCP
FRD := $(APP)/demo-common
SRC := $(APP)/src

FRD_MIN := $(FRD)/minimal
FRD_MAX := $(FRD)/full

BIN_BN   := $(BIN)/freertos-$(MACH)

APP_BN   := $(BIN_BN)-app
APP_ELF  := $(APP_BN).elf
APP_MAP  := $(APP_BN).map
APP_LST  := $(APP_BN).list
APP_BIN  := $(APP_BN).bin

UART_BN  := $(BIN_BN)-uart
UART_ELF := $(UART_BN).elf
UART_MAP := $(UART_BN).map
UART_LST := $(UART_BN).list
UART_BIN := $(UART_BN).bin

C_SRCS_HAL = \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_adc.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_adc_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_can.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_cec.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_cortex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_crc.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_crc_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_cryp.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_cryp_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_dac.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_dac_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_dcmi.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_dma.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_dma2d.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_dma_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_exti.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_flash.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_flash_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_gpio.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_hash.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_hash_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_hcd.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_i2c.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_i2c_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_i2s.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_irda.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_iwdg.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_lptim.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_ltdc.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_nand.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_nor.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_pcd.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_pcd_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_pwr.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_pwr_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_qspi.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_rcc.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_rcc_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_rng.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_rtc.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_rtc_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_sai.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_sai_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_sd.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_sdram.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_smartcard.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_smartcard_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_spdifrx.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_spi.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_sram.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_tim.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_tim_ex.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_uart.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_usart.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_wwdg.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_ll_fmc.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_ll_sdmmc.c \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_ll_usb.c

C_SRCS_BOARD = \
	$(STM)/Drivers/BSP/STM32746G-Discovery/stm32746g_discovery.c \
	$(STM)/Drivers/BSP/STM32746G-Discovery/stm32746g_discovery_audio.c \
	$(STM)/Drivers/BSP/STM32746G-Discovery/stm32746g_discovery_camera.c \
	$(STM)/Drivers/BSP/STM32746G-Discovery/stm32746g_discovery_eeprom.c \
	$(STM)/Drivers/BSP/STM32746G-Discovery/stm32746g_discovery_lcd.c \
	$(STM)/Drivers/BSP/STM32746G-Discovery/stm32746g_discovery_qspi.c \
	$(STM)/Drivers/BSP/STM32746G-Discovery/stm32746g_discovery_sd.c \
	$(STM)/Drivers/BSP/STM32746G-Discovery/stm32746g_discovery_sdram.c \
	$(STM)/Drivers/BSP/STM32746G-Discovery/stm32746g_discovery_ts.c

C_SRCS_COMPONENTS = \
	$(STM)/Drivers/BSP/Components/ft5336/ft5336.c \
	$(STM)/Drivers/BSP/Components/ov9655/ov9655.c \
	$(STM)/Drivers/BSP/Components/wm8994/wm8994.c

C_SRCS_FREERTOS_KERNEL = \
	$(FRK)/tasks.c \
	$(FRK)/queue.c \
	$(FRK)/event_groups.c \
	$(FRK)/list.c \
	$(FRK)/timers.c \
	$(FRK)/stream_buffer.c \
	$(FRK)/portable/MemMang/heap_4.c \
	$(FRK)/portable/GCC/ARM_CM7/r0p1/port.c

C_SRCS_FREERTOS_PLUS_TCPIP = \
	$(FRT)/FreeRTOS_IP.c \
	$(FRT)/FreeRTOS_ARP.c \
	$(FRT)/FreeRTOS_DHCP.c \
	$(FRT)/FreeRTOS_DNS.c \
	$(FRT)/FreeRTOS_Sockets.c \
	$(FRT)/FreeRTOS_TCP_IP.c \
	$(FRT)/FreeRTOS_UDP_IP.c \
	$(FRT)/FreeRTOS_TCP_WIN.c \
	$(FRT)/FreeRTOS_Stream_Buffer.c \
	$(FRT)/portable/NetworkInterface/Common/phyHandling.c \
	$(FRT)/portable/NetworkInterface/STM32Fxx/NetworkInterface.c \
	$(FRT)/portable/NetworkInterface/STM32Fxx/stm32fxx_hal_eth.c \
	$(FRT)/portable/BufferManagement/BufferAllocation_1.c


C_SRCS_APP_CORE = \
	$(SRC)/stm32f7xx_hal_msp.c \
	$(SRC)/system_stm32f7xx.c \
	$(SRC)/app-hardware.c \
	$(SRC)/app-network.c \
	$(SRC)/app-kernel-hooks.c \
	$(SRC)/app-network-hooks.c \
	$(SRC)/app-task-logging.c \
	$(SRC)/app-task-blinky.c \
	$(SRC)/app-task-full.c \
	$(SRC)/app-task-mqtt.c

C_SRCS_APP = \
	$(C_SRCS_HAL) \
	$(C_SRCS_BOARD) \
	$(C_SRCS_COMPONENTS) \
	$(C_SRCS_FREERTOS_KERNEL) \
	$(C_SRCS_FREERTOS_PLUS_TCPIP) \
	$(C_SRCS_APP_CORE) \
	$(SRC)/app-main.c

C_SRCS_UART = \
	$(C_SRCS_HAL) \
	$(C_SRCS_BOARD) \
	$(C_SRCS_COMPONENTS) \
	$(C_SRCS_FREERTOS_KERNEL) \
	$(C_SRCS_FREERTOS_PLUS_TCPIP) \
	$(C_SRCS_APP_CORE) \
	$(SRC)/dem-uart.c

S_SRCS = $(SRC)/startup_stm32f746xx.s
S_DEPS = $(SRC)/startup_stm32f746xx.s

APP_OBJS  = $(S_SRCS:.s=.o) $(C_SRCS_APP:.c=.o)
APP_DEPS  = $(S_SRCS:.s=.d) $(C_SRCS_APP:.c=.d)
UART_OBJS  = $(S_SRCS:.s=.o) $(C_SRCS_UART:.c=.o)
UART_DEPS  = $(S_SRCS:.s=.d) $(C_SRCS_UART:.c=.d)
OBJS = $(APP_OBJS) $(UART_OBJS)
SUFILES = $(S_SRCS:.s=.su) $(C_SRCS:.c=.su)

INC_PATH = \
	$(FRT)/portable/NetworkInterface/include \
	$(APP)/inc \
	$(STM)/Drivers/STM32F7xx_HAL_Driver/Inc \
	$(STM)/Drivers/CMSIS/Device/ST/STM32F7xx/Include \
	$(STM)/Drivers/BSP/STM32746G-Discovery \
	$(STM)/Drivers/BSP/Components/Common \
	$(STM)/Drivers/BSP/Components/ft5336 \
	$(STM)/Drivers/BSP/Components/ov9655 \
	$(STM)/Drivers/BSP/Components/rk043fn48h \
	$(STM)/Drivers/BSP/Components/n25q128a \
	$(STM)/Drivers/BSP/Components/wm8994 \
	$(STM)/Utilities/Log \
	$(STM)/Utilities/Fonts \
	$(STM)/Utilities/CPU \
	$(STM)/Drivers/CMSIS/Include \
	$(FRT)/portable/NetworkInterface/STM32Fxx \
	$(FRK)/include \
	$(FRK)/portable/GCC/ARM_CM7/r0p1 \
	$(FRT)/portable/Compiler/GCC \
	$(FRT)/include \
	$(APP)/demo-common/include

INC = $(INC_PATH:%=-I%)
