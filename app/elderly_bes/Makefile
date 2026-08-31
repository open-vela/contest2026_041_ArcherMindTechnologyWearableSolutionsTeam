############################################################################
# apps/examples/elderly_bes/Makefile
############################################################################

include $(APPDIR)/Make.defs

PROGNAME  = elderly
PRIORITY  = $(CONFIG_EXAMPLES_ELDERLY_BES_PRIORITY)
STACKSIZE = $(CONFIG_EXAMPLES_ELDERLY_BES_STACKSIZE)
MODULE    = $(CONFIG_EXAMPLES_ELDERLY_BES)

CSRCS  = elderly_main.c
CSRCS += ui_manager.c
CSRCS += ui_index.c
CSRCS += ui_health_detail.c
CSRCS += ui_settings.c
CSRCS += ui_sos.c
CSRCS += data_collector.c

include $(APPDIR)/Application.mk
