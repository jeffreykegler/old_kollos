CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(luif_tests C CXX)

set(Scripts "luif_proto.pl")
source_group("scripts" FILES ${Scripts})

set(Outputs "")
foreach(Script_File ${Scripts})
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${Script_File}
    COMMAND ${CMAKE_COMMAND}
    ARGS -E copy_if_different
      ${CMAKE_CURRENT_SOURCE_DIR}/${Script_File}
      ${CMAKE_CURRENT_BINARY_DIR}/${Script_File}
  )
  list(APPEND Outputs ${CMAKE_CURRENT_BINARY_DIR}/${Script_File})
endforeach()

add_custom_target(
  copy_scripts ALL
  DEPENDS ${Outputs}
  COMMENT "Copying files"
  VERBATIM
)

# vim: expandtab shiftwidth=4:
