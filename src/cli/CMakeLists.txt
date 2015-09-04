vala_precompile (VALA_C parental-control-cli
    FileReader.vala
    PAMWriter.vala
    main.vala
PACKAGES
    posix
    gio-2.0
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/
    --thread  
)

add_executable (parental-control-cli ${VALA_C})
target_link_libraries (parental-control-cli ${DEPS_LIBRARIES}) 

# Installation
install (TARGETS parental-control-cli RUNTIME DESTINATION bin)