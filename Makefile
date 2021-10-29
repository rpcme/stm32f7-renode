# -*- makefile -*-
include makefile.files

AS = arm-none-eabi-as
CC = arm-none-eabi-gcc

C_EXTRA_FLAGS =\
	-mcpu=cortex-m7 \
	-std=gnu11 \
	-mfloat-abi=hard \
	-mfpu=fpv5-sp-d16 \
	-mthumb \
	-c \
	-Os \
	-Wall \
	-MMD \
	-MP \
	-fmessage-length=0 \
	-ffunction-sections \
	-fdata-sections \
	-fno-builtin \
	-fno-builtin-memcpy \
	-fno-builtin-memset

DEFS =
DEFS += \
	-DipconfigMULTI_INTERFACE=0 \
	-DipconfigUSE_IPv6=0 \
	-DSTM32F7xx \
	-DSTM32F746xx \
	-DipconfigUSE_HTTP=0 \
	-DipconfigUSE_FTP=0 \
	-DHAL_ETH_MODULE_ENABLED=1 \
	-DHAL_USART_MODULE_ENABLED=1

CFLAGS = $(C_EXTRA_FLAGS) $(DEFS)

LDFLAGS = \
	-o "$(BIN)/freertos-stm32f7-renode.elf" \
	-T"$(APP)/fw/STM32F746NGHX_FLASH.ld" \
	-Wl,-Map="$(BIN)/freertos-stm32f7-renode.map" \
	--specs=nosys.specs \
	-mcpu=cortex-m7 \
	-mfpu=fpv5-sp-d16 \
	-mfloat-abi=hard \
	-mthumb \
	-Wl,--start-group \
	-Wl,--end-group \
	-Xlinker --gc-sections \
	-Xlinker --relax \
	-Xlinker -s

LDLIBS = \
	-lc \
	-lm

%.o: %.s
	arm-none-eabi-gcc -mcpu=cortex-m7 -g3 -DDEBUG -c -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

%.o: %.c
	arm-none-eabi-gcc "$<" $(CFLAGS) $(INC) -o "$@"

default: $(OBJS)
	mkdir -p $(BIN)
	arm-none-eabi-gcc $(OBJS) $(LDLIBS) $(LDFLAGS)
	arm-none-eabi-size   $(BIN)/freertos-stm32f7-renode.elf 
	arm-none-eabi-objdump -h -S  $(BIN)/freertos-stm32f7-renode.elf  > "$(BIN)/freertos-stm32f7-renode.list"
	arm-none-eabi-objcopy  -O binary  $(BIN)/freertos-stm32f7-renode.elf  "$(BIN)/freertos-stm32f7-renode.bin"

.PHONY: clean
clean:
	-$(VERBOSE_CMD)$(RM) $(OBJS)
	-$(VERBOSE_CMD)$(RM) $(DEPS)
	-$(VERBOSE_CMD)$(RM) $(SUFILES)
