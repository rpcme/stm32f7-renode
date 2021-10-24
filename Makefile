-include makefile.files

AS = arm-none-eabi-as

CFLAGS = -mcpu=cortex-m7 -std=gnu11 -g3 -DDEBUG -DSTM32 -DSTM32F746NGHx -DSTM32F7 -DSTM32F746xx -c -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb



C_SRCS = \
	$(STM_HAL)/../Src/stm32f7xx_hal.c \
	$(STM_HAL)/../Src/stm32f7xx_hal_cortex.c \
	$(STM_HAL)/../Src/stm32f7xx_hal_adc.c \
	$(STM_HAL)/../Src/stm32f7xx_hal_gpio.c \
	$(STM_HAL)/../Src/stm32f7xx_hal_rcc.c \
	$(STM_HAL)/../Src/stm32f7xx_hal_tim.c \
	$(STM_HAL)/../Src/stm32f7xx_hal_tim_ex.c \
	$(STM_HAL)/../Src/stm32f7xx_hal_dma.c \
	$(FRK)/tasks.c \
	$(FRK)/queue.c \
	$(FRK)/event_groups.c \
	$(FRK)/list.c \
	$(FRK)/timers.c \
	$(FRK_CM7)/port.c \
	$(FRD_MIN)/TimerDemo.c \
	$(FRD_MIN)/QueueOverwrite.c \
	$(FRD_MIN)/EventGroupsDemo.c \
	$(FRD_MIN)/IntSemTest.c \
	$(FRD_MIN)/QueueSet.c \
	$(FRD_MIN)/TaskNotify.c \
	$(SRC)/stm32f7xx_hal_msp.c \
	$(SRC)/system_stm32f7xx.c \
	$(SRC)/main.c

#	$(SRC)/stm32f7xx_it.c \
#	$(OBJ)/stm32f7xx_it.o \

OBJS = \
	$(OBJ)/startup_stm32f746nghx.o \
	$(OBJ)/system_stm32f7xx.o \
	$(OBJ)/stm32f7xx_hal_msp.o \
	$(OBJ)/stm32f7xx_hal.o \
	$(OBJ)/stm32f7xx_hal_cortex.o \
	$(OBJ)/stm32f7xx_hal_rcc.o \
	$(OBJ)/stm32f7xx_hal_adc.o \
	$(OBJ)/stm32f7xx_hal_gpio.o \
	$(OBJ)/stm32f7xx_hal_tim.o \
	$(OBJ)/stm32f7xx_hal_tim_ex.o \
	$(OBJ)/stm32f7xx_hal_dma.o \
	$(OBJ)/tasks.o \
	$(OBJ)/queue.o \
	$(OBJ)/list.o \
	$(OBJ)/event_groups.o \
	$(OBJ)/timers.o \
	$(OBJ)/port.o \
	$(OBJ)/TimerDemo.o \
	$(OBJ)/QueueOverwrite.o \
	$(OBJ)/EventGroupsDemo.o \
	$(OBJ)/IntSemTest.o \
	$(OBJ)/QueueSet.o \
	$(OBJ)/TaskNotify.o \
	$(OBJ)/main.o

C_DEPS = \
	$(OBJ)/system_stm32f7xx.d \
	$(OBJ)/stm32f7xx_hal.d \
	$(OBJ)/stm32f7xx_hal_cortex.d \
	$(OBJ)/stm32f7xx_hal_rcc.d \
	$(OBJ)/stm32f7xx_hal_adc.d \
	$(OBJ)/stm32f7xx_hal_gpio.d \
	$(OBJ)/stm32f7xx_hal_tim.d \
	$(OBJ)/stm32f7xx_hal_tim_ex.d \
	$(OBJ)/stm32f7xx_hal_dma.d \
	$(OBJ)/tasks.d \
	$(OBJ)/queue.d \
	$(OBJ)/list.d \
	$(OBJ)/event_groups.d \
	$(OBJ)/timers.d \
	$(OBJ)/port.d \
	$(OBJ)/TimerDemo.d \
	$(OBJ)/QueueOverwrite.d \
	$(OBJ)/EventGroupsDemo.d \
	$(OBJ)/IntSemTest.d \
	$(OBJ)/QueueSet.d \
	$(OBJ)/TaskNotify.d \
	$(OBJ)/stm32f7xx_it.d \
	$(OBJ)/stm32f7xx_hal_msp.d \
	$(OBJ)/main.d

S_SRCS = $(SRC)/startup_stm32f746nghx.s

S_DEPS = $(SRC)/startup_stm32f746nghx.d

$(OBJ)/%.o: $(SRC)/%.s
	@echo running
	arm-none-eabi-gcc -mcpu=cortex-m7 -g3 -DDEBUG -c -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

$(OBJ)/%.o: $(STM_HAL)/../Src/%.c
	arm-none-eabi-gcc "$<" $(CFLAGS) $(INC) -o "$@"

$(OBJ)/%.o: $(FRK)/%.c
	arm-none-eabi-gcc "$<" $(CFLAGS) $(INC) -o "$@"

$(OBJ)/%.o: $(FRK_CM7)/%.c
	arm-none-eabi-gcc "$<" $(CFLAGS) $(INC) -o "$@"

$(OBJ)/%.o: $(FRD_MIN)/%.c
	arm-none-eabi-gcc "$<" $(CFLAGS) $(INC) -o "$@"

$(OBJ)/%.o: $(SRC)/%.c
	arm-none-eabi-gcc "$<" $(CFLAGS) $(INC) -o "$@"

default: $(OBJS)
	mkdir -p $(OBJ)
	mkdir -p $(BIN)
	arm-none-eabi-gcc -o "$(BIN)/freertos-stm32f7-renode.elf" $(OBJS) -mcpu=cortex-m7 \
		-T"$(APP)/fw/STM32F746NGHX_FLASH.ld" --specs=nosys.specs \
		-Wl,-Map="$(BIN)/freertos-stm32f7-renode.map" \
		-Wl,--gc-sections -static --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -Wl,--start-group -lc -lm -Wl,--end-group
	arm-none-eabi-size   $(BIN)/freertos-stm32f7-renode.elf 
	arm-none-eabi-objdump -h -S  $(BIN)/freertos-stm32f7-renode.elf  > "$(BIN)/freertos-stm32f7-renode.list"
	arm-none-eabi-objcopy  -O binary  $(BIN)/freertos-stm32f7-renode.elf  "$(BIN)/freertos-stm32f7-renode.bin"

