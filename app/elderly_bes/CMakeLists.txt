# ##############################################################################
# apps/examples/elderly_bes/CMakeLists.txt
# ##############################################################################

if(CONFIG_EXAMPLES_ELDERLY_BES)
  nuttx_add_application(
    NAME
    elderly
    PRIORITY
    ${CONFIG_EXAMPLES_ELDERLY_BES_PRIORITY}
    STACKSIZE
    ${CONFIG_EXAMPLES_ELDERLY_BES_STACKSIZE}
    MODULE
    ${CONFIG_EXAMPLES_ELDERLY_BES}
    DEPENDS
    lvgl
    SRCS
    elderly_main.c
    ui_manager.c
    ui_index.c
    ui_health_detail.c
    ui_settings.c
    ui_sos.c)
endif()
