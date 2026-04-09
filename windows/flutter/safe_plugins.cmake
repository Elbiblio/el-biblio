#
# Safe plugin list for Windows — manually maintained to exclude build-breaking plugins.
# flutter pub get regenerates generated_plugins.cmake; this file is NOT overwritten.
#
# Excluded:
#   firebase_core                        — prebuilt libs require MSVC 14.32+ (VS 2022 17.2+)
#   flutter_local_notifications_windows — requires ATL component from VS Installer
#
# To update when new plugins are added: copy new entries from generated_plugins.cmake
# to this file, omitting the two excluded plugins above.

list(APPEND FLUTTER_PLUGIN_LIST
  audioplayers_windows
  connectivity_plus
  file_selector_windows
  flutter_tts
  permission_handler_windows
  screen_retriever_windows
  share_plus
  speech_to_text_windows
  url_launcher_windows
  window_manager
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
