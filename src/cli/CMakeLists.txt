vala_precompile (VALA_C parental-controls-cli
    Application.vala
    FileReader.vala
    PAMWriter.vala
PACKAGES
    posix
    gio-2.0
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi/
    --thread  
)

add_executable (parental-controls-cli ${VALA_C})
target_link_libraries (parental-controls-cli ${DEPS_LIBRARIES}) 

# Installation
install (TARGETS parental-controls-cli RUNTIME DESTINATION bin)