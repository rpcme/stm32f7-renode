# -*- makefile -*-
#.DEFAULT_GOAL: default

include stm32f746.mk
include arm-none-eabi.mk

C_EXTRA_FLAGS =\
	-DDEBUG \
	-g2 \
	-ggdb \
	-mcpu=cortex-m7 \
	-mfpu=fpv5-sp-d16 \
	-std=gnu11 \
	-mfloat-abi=hard \
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

DEFS = \
	-DSTM32F7xx=1 \
	-DSTM32F746xx=1
#\
#	-DUSE_HAL_DRIVER

CFLAGS = $(C_EXTRA_FLAGS) $(DEFS)

LDFLAGS = \
	-T"$(APP)/fw/STM32F746NGHX_FLASH.ld" \
	--specs=nosys.specs \
	-mcpu=cortex-m7 \
	-mfpu=fpv5-sp-d16 \
	-mfloat-abi=hard \
	-mthumb \
	-Wl,--start-group \
	-Wl,--end-group \
	-Xlinker --gc-sections \
	-Xlinker --relax
#\	-Xlinker -s

LDLIBS = \
	-lc \
	-lm

%.o: %.s
	$(CC) -mcpu=cortex-m7 -g3 -DDEBUG -c -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

%.o: %.c
	$(CC) "$<" $(CFLAGS) $(INC) -o "$@"

.PHONY: default
default: $(OBJS) setup app uart

.PHONY: app
app: $(APP_ELF) $(APP_LST) $(APP_BIN)

.PHONY: uart
uart: $(UART_ELF) $(UART_LST) $(UART_BIN)

$(APP_ELF): $(APP_OBJS) $(APP)/fw/STM32F746NGHX_FLASH.ld $(APP)/fw/STM32F746NGHX_RAM.ld
	$(CC) $(APP_OBJS) $(LDLIBS) -o $@ -Wl,-Map=$(APP_MAP) $(LDFLAGS)
	$(SIZE) $(APP_ELF)

$(APP_LST): $(APP_ELF)
	$(OBJDUMP) $(OBJDUMP_FLAGS) $(APP_ELF) > $(APP_LST)

$(APP_BIN): $(APP_ELF)
	$(OBJCOPY) $(OBJCOPY_FLAGS) $(APP_ELF) $(APP_BIN)

$(UART_ELF): $(UART_OBJS) $(APP)/fw/STM32F746NGHX_FLASH.ld $(APP)/fw/STM32F746NGHX_RAM.ld
	$(CC) $(UART_OBJS) $(LDLIBS) -o $@ -Wl,-Map=$(UART_MAP) $(LDFLAGS)
	$(SIZE) $(UART_ELF)

$(UART_LST): $(UART_ELF)
	$(OBJDUMP) $(OBJDUMP_FLAGS) $(UART_ELF) > $(UART_LST)

$(UART_BIN): $(UART_ELF)
	$(OBJCOPY) $(OBJCOPY_FLAGS) $(UART_ELF) $(UART_BIN)

$(BIN):
	-mkdir -p $(BIN)

setup: $(BIN)


.PHONY: clean
clean:
	-$(VERBOSE_CMD)$(RM) $(OBJS)
	-$(VERBOSE_CMD)$(RM) $(DEPS)
	-$(VERBOSE_CMD)$(RM) $(SUFILES)

