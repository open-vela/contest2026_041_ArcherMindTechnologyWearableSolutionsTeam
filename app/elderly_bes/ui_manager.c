/****************************************************************************
 * apps/examples/elderly/ui_manager.c
 *
 * Page manager: handles page creation, switching, and lifecycle.
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "ui_manager.h"
#include "ui_index.h"
#include "ui_health_detail.h"
#include "ui_settings.h"
#include "ui_wifi.h"
#include "ui_sos.h"

/****************************************************************************
 * Private Data
 ****************************************************************************/

static lv_obj_t *g_pages[PAGE_COUNT];
static lv_obj_t *g_layer;     /* Top-level layer for overlays */
static page_id_t g_current = PAGE_INDEX;

/****************************************************************************
 * Private Functions
 ****************************************************************************/

static void swipe_event_cb(lv_event_t *e)
{
  lv_dir_t dir = lv_indev_get_gesture_dir(lv_indev_active());
  app_context_t *ctx = app_get_context();

  /* Don't allow swipe navigation when SOS is active */

  if (ctx->alarm.active)
    {
      return;
    }

  if (dir == LV_DIR_LEFT)
    {
      if (g_current < PAGE_COUNT - 1)
        {
          ui_manager_switch_page(g_current + 1);
        }
    }
  else if (dir == LV_DIR_RIGHT)
    {
      if (g_current > PAGE_INDEX)
        {
          ui_manager_switch_page(g_current - 1);
        }
    }
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

void ui_manager_init(void)
{
  lv_obj_t *scr = lv_screen_active();

  /* Set black background */

  lv_obj_set_style_bg_color(scr, COLOR_BG, 0);
  lv_obj_set_style_bg_opa(scr, LV_OPA_COVER, 0);
  lv_obj_remove_flag(scr, LV_OBJ_FLAG_SCROLLABLE);

  /* Create the content layer */

  g_layer = lv_obj_create(scr);
  lv_obj_set_size(g_layer, SCREEN_WIDTH, SCREEN_HEIGHT);
  lv_obj_center(g_layer);
  lv_obj_set_style_bg_opa(g_layer, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(g_layer, 0, 0);
  lv_obj_set_style_pad_all(g_layer, 0, 0);
  lv_obj_remove_flag(g_layer, LV_OBJ_FLAG_SCROLLABLE);

  /* Create all pages */

  g_pages[PAGE_INDEX] = ui_index_create(g_layer);
  g_pages[PAGE_HEALTH_DETAIL] = ui_health_detail_create(g_layer);
  g_pages[PAGE_SETTINGS] = ui_settings_create(g_layer);
  g_pages[PAGE_WIFI] = ui_wifi_create(g_layer);
  g_pages[PAGE_SOS] = ui_sos_create(g_layer);

  /* Hide all except the first page */

  for (int i = 0; i < PAGE_COUNT; i++)
    {
      if (i != PAGE_INDEX)
        {
          lv_obj_add_flag(g_pages[i], LV_OBJ_FLAG_HIDDEN);
        }
    }

  g_current = PAGE_INDEX;

  /* Add swipe gesture handler on the active screen */

  lv_obj_add_event_cb(scr, swipe_event_cb, LV_EVENT_GESTURE, NULL);
}

void ui_manager_switch_page(page_id_t page)
{
  if (page >= PAGE_COUNT || page == g_current)
    {
      return;
    }

  /* Hide current page */

  lv_obj_add_flag(g_pages[g_current], LV_OBJ_FLAG_HIDDEN);

  /* Show target page */

  lv_obj_remove_flag(g_pages[page], LV_OBJ_FLAG_HIDDEN);

  g_current = page;

  /* Sync settings page controls when entering settings */

  if (page == PAGE_SETTINGS)
    {
      ui_settings_sync_controls();
    }

  /* Update health detail when entering */

  if (page == PAGE_HEALTH_DETAIL)
    {
      ui_health_detail_update();
    }

  /* Refresh WiFi status when entering WiFi page */

  if (page == PAGE_WIFI)
    {
      ui_wifi_refresh();
    }
}

lv_obj_t *ui_manager_get_page(page_id_t page)
{
  if (page < PAGE_COUNT)
    {
      return g_pages[page];
    }

  return NULL;
}

void ui_manager_refresh(void)
{
  switch (g_current)
    {
      case PAGE_INDEX:
        ui_index_update_vitals();
        ui_index_update_steps();
        ui_index_update_health_status();
        break;

      case PAGE_HEALTH_DETAIL:
        ui_health_detail_update();
        break;

      default:
        break;
    }
}

lv_obj_t *ui_manager_get_layer(void)
{
  return g_layer;
}
