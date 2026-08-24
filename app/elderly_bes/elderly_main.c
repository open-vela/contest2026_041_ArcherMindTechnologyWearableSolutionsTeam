/****************************************************************************
 * apps/examples/elderly_bes/elderly_main.c
 *
 * Main entry point for the Elderly Health Care LVGL application.
 * Minimal version for BES2800 round display - UI only, no background threads.
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include <nuttx/config.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/boardctl.h>

#include <lvgl/lvgl.h>
#include "ui_manager.h"

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

#undef NEED_BOARDINIT

#if defined(CONFIG_BOARDCTL) && !defined(CONFIG_NSH_ARCHINIT)
#  define NEED_BOARDINIT 1
#endif

/****************************************************************************
 * Public Functions
 ****************************************************************************/

int main(int argc, FAR char *argv[])
{
  lv_nuttx_dsc_t info;
  lv_nuttx_result_t result;

  if (lv_is_initialized())
    {
      LV_LOG_ERROR("LVGL already initialized! aborting.");
      return -1;
    }

#ifdef NEED_BOARDINIT
  boardctl(BOARDIOC_INIT, 0);
#endif

  lv_init();
  lv_nuttx_dsc_init(&info);

#ifdef CONFIG_LV_USE_NUTTX_LCD
  info.fb_path = "/dev/lcd0";
#endif

#ifdef CONFIG_INPUT_TOUCHSCREEN
  info.input_path = CONFIG_EXAMPLES_ELDERLY_BES_INPUT_DEVPATH;
#endif

  lv_nuttx_init(&info, &result);

  if (result.disp == NULL)
    {
      LV_LOG_ERROR("Display initialization failure!");
      return 1;
    }

  LV_LOG_USER("Display ready. Creating UI...");

  /* Create UI pages */

  ui_manager_init();

  LV_LOG_USER("UI ready. Entering main loop. Screen: %dx%d",
              CONFIG_EXAMPLES_ELDERLY_BES_SCREEN_WIDTH,
              CONFIG_EXAMPLES_ELDERLY_BES_SCREEN_HEIGHT);

  /* Main event loop */

  while (1)
    {
      uint32_t idle;
      idle = lv_timer_handler();
      idle = idle ? idle : 1;
      usleep(idle * 1000);
    }

  lv_nuttx_deinit(&result);
  lv_deinit();
  return 0;
}
