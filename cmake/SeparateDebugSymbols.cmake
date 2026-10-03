if(NOT CONFIG STREQUAL "Debug")
    return()
endif()

set(symbol_file "${EXECUTABLE}.debug")
# Finish the symbol copy before modifying the executable. Each relink refreshes
# both files and their CRC, preventing stale symbols from being silently used.
execute_process(
    COMMAND "${OBJCOPY}" --only-keep-debug --compress-debug-sections=zlib
        "${EXECUTABLE}" "${symbol_file}"
    COMMAND_ERROR_IS_FATAL ANY)
execute_process(
    COMMAND "${OBJCOPY}" --strip-debug "${EXECUTABLE}"
    COMMAND_ERROR_IS_FATAL ANY)
execute_process(
    COMMAND "${OBJCOPY}" "--add-gnu-debuglink=${symbol_file}" "${EXECUTABLE}"
    COMMAND_ERROR_IS_FATAL ANY)
