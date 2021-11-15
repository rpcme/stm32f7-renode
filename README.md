## About this project

This projects contains a set of artifacts to demonstrate
microcontroller based IoT project CI/CD pipelines on AWS using AWS
CodePipeline, AWS CodeCommit and GitHub, AWS CodeBuild, and AWS IoT
Device Advisor. The focus of the project is to show how to use AWS IoT
Device Advisor for Integration test as the Continuous Delivery gate.

## Building and flashing the firmware

The firmware uses STM32Cube SDK, STLINK tools (for verifying on
hardware target), Renode (for emulation), Arm GCC cross toolchain,
make, and (of course) FreeRTOS and related libraries for RTOS,
application logic, and AWS IoT connectivity.  Although it is better to
run the CI process in the cloud, the physical steps are here to help
you first see how to build and flash the physical target so you can
envisage how the firmware would run in an emulated environment.

**Note** the steps expect a Linux environment. The development was
done on Ubuntu 20.04.

1. Clone the application repository.
2. Use `repo` to clone dependent repositories.

  ```bash
   repo init -u https://github.com/rpcme/stm32f7-renode
   ```
3. Download and unpack the Arm GCC toolchain.

   ```bash
   curl -v https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 | tar xjf -
   ```

4. Install STLINK tools. Although the flash step below shows you how
   to flash, you might want to be familiar with all the available
   tools in the package.  Visit https://github.com/stlink-org/stlink
   for more information.
   
   ```bash
   sudo apt-get install stlink-tools
   ```
4. Remove the driver header file from the STMicro Cube
   SDK. FreeRTOS+TCP provides the same. Not removing the file will
   cause a stellar failure.
   
   ```bash
   rm STM32CubeF7/Drivers/STM32F7xx_HAL_Driver/Inc/stm32f7xx_hal_eth.h
   ```
4. Set PATH to include the Arm GCC toolchain.
5. Change directory to the application repository.
6. Build the application.

   ```bash
   make
   ```
7. Flash the application. Start by connecting the STM32746-Discovery
   board and then invoke the following command.
   
   ```bash
   st-flash --reset write bin/stm32f746-uart.bin 0x8000000
   ```
   


openocd -f board/stm32f7discovery.cfg

monitor reset halt

target remote localhost:3333

