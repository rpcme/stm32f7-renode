# -*- makefile -*-
include makefile.files

AS = arm-none-eabi-as
CC = arm-none-eabi-gcc

CFLAGS = \
	-DDEBUG \
	-mcpu=cortex-m7 \
	-std=gnu11 \
	-g3 \
	-DSTM32F7xx \
	-DSTM32F746xx \
	-c \
	-O0 \
	-ffunction-sections \
	-fdata-sections \
	-Wall \
	-fstack-usage \
	-MMD \
	-MP \
	--specs=nano.specs \
	-mfpu=fpv5-sp-d16 \
	-mfloat-abi=hard \
	-mthumb \
	-DSDIO_USES_DMA=1 \
	-D ipconfigMULTI_INTERFACE=0

%.o: %.s
	arm-none-eabi-gcc -mcpu=cortex-m7 -g3 -DDEBUG -c -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

%.o: %.c
	arm-none-eabi-gcc "$<" $(CFLAGS) $(INC) -o "$@"

default: $(OBJS)
	mkdir -p $(BIN)
	arm-none-eabi-gcc \
		-o "$(BIN)/freertos-stm32f7-renode.elf" \
		-T"$(APP)/fw/STM32F746NGHX_FLASH.ld" \
		-Wl,-Map="$(BIN)/freertos-stm32f7-renode.map" \
		$(OBJS) \
		$(LDLIBS) \
		-DSTM32F7xx \
		-DSTM32F746xx \
		--specs=nosys.specs \
		-mcpu=cortex-m7 \
		-Wl,--gc-sections \
		-static \
		-mfpu=fpv5-sp-d16 \
		-mfloat-abi=hard \
		-mthumb \
		-Wl,--start-group \
		-lc -lm -Wl,--end-group \
		-Xlinker --gc-sections
	arm-none-eabi-size   $(BIN)/freertos-stm32f7-renode.elf 
	arm-none-eabi-objdump -h -S  $(BIN)/freertos-stm32f7-renode.elf  > "$(BIN)/freertos-stm32f7-renode.list"
	arm-none-eabi-objcopy  -O binary  $(BIN)/freertos-stm32f7-renode.elf  "$(BIN)/freertos-stm32f7-renode.bin"

#		--specs=nano.specs \

.PHONY: clean
clean:
	-$(VERBOSE_CMD)$(RM) $(OBJS)
	-$(VERBOSE_CMD)$(RM) $(DEPS)
